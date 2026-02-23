local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local input = require("mc.input")
local mc = require("mc")
local robot = require("mc.robot")
local bit = require("bit")

_G.IMGUI_LIB_PATH = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local imgui = require("imgui")
local imgui_renderer

-- 1. FFI DEFINITIONS
ffi.cdef[[
    typedef struct LineVertex { float x, y, z; float r, g, b, a; } LineVertex;
    typedef struct Pose { float x, y, z, yaw; } Pose;
    typedef struct ParserPC { uint32_t in_buf_idx; uint32_t in_offset_u32; uint32_t out_buf_idx; uint32_t count; } ParserPC;
    typedef struct RenderPC { float view_proj[16]; uint32_t buf_idx; float point_size; } RenderPC;
    typedef struct LidarCallbackData { float x, y, w, h; } LidarCallbackData;
    typedef int ImGuiAxis;

    bool igSliderFloat(const char* label, float* v, float v_min, float v_max, const char* format, int flags);
    bool igCheckbox(const char* label, bool* v);
    void igSetNextWindowPos(const ImVec2_c pos, int cond, const ImVec2_c pivot);
    void igSetNextWindowSize(const ImVec2_c size, int cond);
    bool igIsWindowHovered(int flags);
    bool igIsWindowFocused(int flags);
    void igSameLine(float offset_from_start_x, float spacing);
    bool igInputText(const char* label, char* buf, size_t buf_size, int flags, void* callback, void* user_data);
    void igSetKeyboardFocusHere(int offset);
    bool igSelectable_Bool(const char* label, bool selected, int flags, const ImVec2_c size);
    void igOpenPopup_Str(const char* str_id, int popup_flags);
    bool igBeginPopupModal(const char* name, bool* p_open, int flags);
    void igEndPopup(void);
    void igCloseCurrentPopup(void);
    bool igIsItemClicked(int mouse_button);
    bool igIsKeyPressed_Bool(int key, bool repeat);
    void igEnd(void);
    void igTextColored(const ImVec4_c col, const char* fmt, ...);
    void igSetNextWindowFocus(void);
    void igSeparatorText(const char* label);
    bool igBeginChild_Str(const char* str_id, const ImVec2_c size, bool border, ImGuiChildFlags flags);
    void igEndChild(void);
    void igTextWrapped(const char* fmt, ...);
    void igTextDisabled(const char* fmt, ...);
    void igText(const char* fmt, ...);
    bool igTreeNode_Str(const char* label);
    void igTreePop(void);
    bool igBeginTable(const char* str_id, int column, int flags, const ImVec2_c outer_size, float inner_width);
    void igEndTable(void);
    void igTableNextRow(int row_flags, float min_row_height);
    bool igTableNextColumn(void);
    void igTableSetupColumn(const char* label, int flags, float init_width_or_weight, ImGuiID user_id);
    void igTableHeadersRow(void);
    void igSetNextItemWidth(float item_width);
    ImVec2_c igGetWindowPos(void);
    ImVec2_c igGetWindowSize(void);
    uint64_t SDL_GetTicks(void);
    void ImPlot_SetupAxes(const char* x_label, const char* y_label, ImPlotFlags x_flags, ImPlotFlags y_flags);
    void ImPlot_PlotLine_FloatPtrInt(const char* label_id, const float* values, int count, double xscale, double x0, const ImPlotSpec_c spec);
]]

local Flags = { NoDecoration = 43, AlwaysAutoResize = 64, AlwaysOnTop = 262144, TableBorders = 3, TableResizable = 16 }
local Keys = { CTRL_L = 224, CTRL_R = 228, V = 25, H = 11, X = 27, P = 19, O = 18, ESC = 41, ENTER = 40, UP = 82, DOWN = 81 }

local state = {
    mcap_path = "test_robot.mcap", points_count = 10000, paused = false, seek_to = nil, speed = 1.0,
    current_msg = ffi.new("McapMessage"), bridge = nil,
    start_time = 0ULL, end_time = 0ULL, current_time_ns = 0ULL, playback_time_ns = 0ULL,
    last_ticks = 0ULL, dt = 0,
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = {0, 0, 5}, ortho = false },
    robot_pose = { x = 0, y = 0, z = 0, yaw = 0 },
    channels = {}, lidar_ch_id = 0, pose_ch_id = 0, message_buffers = {}, plot_history = {}, 
    layout = { 
        type = "split", direction = "h", ratio = 0.8,
        children = {
            {
                type = "split", direction = "v", ratio = 0.7,
                children = {
                    { type = "view", view_type = "view3d", id = 1, title = "3D Lidar###1" },
                    {
                        type = "split", direction = "h", ratio = 0.6,
                        children = {
                            { type = "view", view_type = "pretty_viewer", id = 2, title = "Message Inspector###2" },
                            { type = "view", view_type = "perf", id = 3, title = "Performance###3" }
                        }
                    }
                }
            },
            { type = "view", view_type = "telemetry", id = 4, title = "Playback Controls###4" }
        }
    }, next_id = 5, focused_id = 1, panel_states = {},
    picker = { trigger = false, title = "", query = ffi.new("char[128]"), selected_idx = 0, items = {}, results = {}, on_select = nil }
}

local M = state
local device, queue, graphics_family, sw, cb
local pipe_layout, pipe_parse, pipe_render, pipe_line, layout_parse
local bindless_set, image_available_sem, frame_fence
local raw_buffer, point_buffer, line_buffer, line_count, robot_buffer, robot_line_count

-- 2. STATIC ARENA
local static = {
    v2_zero = ffi.new("ImVec2_c", {0, 0}),
    v2_full = ffi.new("ImVec2_c", {-1, -1}),
    v2_table = ffi.new("ImVec2_c", {0, 250}),
    v2_picker = ffi.new("ImVec2_c", {0.5, 0}),
    v4_live = ffi.new("ImVec4_c", {0, 1, 0, 1}),
    v4_paused = ffi.new("ImVec4_c", {1, 0, 0, 1}),
    v4_val = ffi.new("ImVec4_c", {0.2, 0.8, 1, 1}),
    plot_spec = ffi.new("ImPlotSpec_c", { Stride = 4 }),
    scratch_chars = ffi.new("char[1024]"),
    pc_p = ffi.new("ParserPC"), pc_r = ffi.new("RenderPC"),
    viewport = ffi.new("VkViewport"), scissor = ffi.new("VkRect2D"),
    attachments = ffi.new("VkRenderingAttachmentInfo[1]"),
    cb_begin = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }),
    wait_stages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}),
    mem_barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }}),
    img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }}),
    render_info = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
    submit_info = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, commandBufferCount = 1, signalSemaphoreCount = 1 }),
    fences = ffi.new("VkFence[1]"), sems_wait = ffi.new("VkSemaphore[1]"), sems_sig = ffi.new("VkSemaphore[1]"), cbs = ffi.new("VkCommandBuffer[1]"),
    sets = ffi.new("VkDescriptorSet[1]"), v_buffs = ffi.new("VkBuffer[1]"), v_offs = ffi.new("VkDeviceSize[1]", {0}),
    cam_pos = ffi.new("mc_vec3"), cam_target = ffi.new("mc_vec3"), cam_up = ffi.new("mc_vec3", {0, 0, 1}),
    mat_proj = ffi.new("mc_mat4"), mat_view = ffi.new("mc_mat4"), mat_mvp = ffi.new("mc_mat4")
}

local callback_data_pool = {}
for i=1, 10 do table.insert(callback_data_pool, ffi.new("LidarCallbackData")) end
local callback_data_idx = 1

-- TILING FUNCTIONS
local function split_focused(direction)
    local function find_and_split(node)
        if node.type == "view" then
            if node.id == state.focused_id then
                local old, old_title = node.view_type, node.title
                node.type, node.direction, node.ratio = "split", direction, 0.5
                node.children = { { type = "view", view_type = old, id = node.id, title = old_title }, { type = "view", view_type = "empty", id = state.next_id, title = string.format("View %d###%d", state.next_id, state.next_id) } }
                state.next_id = state.next_id + 1; return true
            end
        else return find_and_split(node.children[1]) or find_and_split(node.children[2]) end
        return false
    end; find_and_split(state.layout)
end

local function close_focused()
    local function find_and_close(node, parent)
        if node.type == "view" then
            if node.id == state.focused_id and parent then
                local other = (parent.children[1] == node) and parent.children[2] or parent.children[1]
                for k,v in pairs(other) do parent[k] = v end; return true
            end
        else return find_and_close(node.children[1], node) or find_and_close(node.children[2], node) end
        return false
    end; find_and_close(state.layout, nil)
end

local function replace_focused_view(new_type)
    local function find_and_replace(node)
        if node.type == "view" then
            if node.id == state.focused_id then node.view_type = new_type; return true end
        else return find_and_replace(node.children[1]) or find_and_replace(node.children[2]) end
        return false
    end; find_and_replace(state.layout)
end

local function open_picker(title, items, on_select)
    state.picker.trigger, state.picker.title, state.picker.items, state.picker.results, state.picker.selected_idx, state.picker.on_select = true, title, items, items, 0, on_select
    ffi.fill(state.picker.query, 128)
end

local function discover_topics()
    local count = robot.lib.mcap_get_channel_count(state.bridge)
    state.channels = {}
    local info = ffi.new("McapChannelInfo")
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(state.bridge, i, info) then
            if info.topic == nil then break end
            local t = ffi.string(info.topic)
            if t == "lidar" then state.lidar_ch_id = info.id end
            if t == "pose" then state.pose_ch_id = info.id end
            table.insert(state.channels, { id = info.id, topic = t, encoding = ffi.string(info.message_encoding), schema = ffi.string(info.schema_name), active = true })
        end
    end
end

-- PANEL RENDERERS
M.panels = {}
function M.register_panel(id, name, render_func) M.panels[id] = { id = id, name = name, render = render_func } end

M.register_panel("view3d", "3D Scene", function(gui, node_id)
    if gui.igBeginChild_Str("SceneChild", static.v2_full, false, 0) then
        local p, s = gui.igGetWindowPos(), gui.igGetWindowSize()
        local data = callback_data_pool[callback_data_idx]; callback_data_idx = (callback_data_idx % 10) + 1
        data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
        gui.ImDrawList_AddCallback(gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
    end
    gui.igEndChild()
end)

M.register_panel("lidar", "Lidar Cloud", function(gui, node_id)
    if gui.ImPlot_BeginPlot("Lidar Cloud", static.v2_full, 8) then
        local p, s = gui.ImPlot_GetPlotPos(), gui.ImPlot_GetPlotSize()
        local data = callback_data_pool[callback_data_idx]; callback_data_idx = (callback_data_idx % 10) + 1
        data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
        gui.ImDrawList_AddCallback(gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
        gui.ImPlot_EndPlot()
    end
end)

local function format_ts(ns, start_ns)
    local d = tonumber(ns - (start_ns or 0)) / 1e9
    local m = math.floor(d / 60)
    local s = d % 60
    return string.format("%02d:%05.2f", m, s)
end

M.register_panel("telemetry", "Playback Controls", function(gui, node_id)
    local total_ns = state.end_time - state.start_time
    gui.igTextColored(state.paused and static.v4_paused or static.v4_live, state.paused and "PAUSED" or "LIVE")
    gui.igSameLine(0, -1)
    gui.igText(" | %s / %s", format_ts(state.current_time_ns, state.start_time), format_ts(state.end_time, state.start_time))
    
    local progress = (total_ns > 0) and tonumber(state.current_time_ns - state.start_time) / tonumber(total_ns) or 0
    local p_ptr = ffi.new("float[1]", progress)
    gui.igSetNextItemWidth(-1)
    if gui.igSliderFloat("##Timeline", p_ptr, 0.0, 1.0, "", 0) then
        state.seek_to = state.start_time + ffi.cast("uint64_t", p_ptr[0] * tonumber(total_ns))
    end
    
    if gui.igButton(state.paused and "Resume" or "Pause", ffi.new("ImVec2_c", {100, 0})) then state.paused = not state.paused end
    gui.igSameLine(0, -1)
    if gui.igButton("Rewind", ffi.new("ImVec2_c", {100, 0})) then state.seek_to = state.start_time end
    gui.igSameLine(0, 10)
    gui.igText("Speed: %.1fx", state.speed)
    gui.igSameLine(0, -1)
    for _, s in ipairs({0.5, 1, 2, 5, 10}) do
        if gui.igButton(tostring(s).."x", ffi.new("ImVec2_c", {40, 0})) then state.speed = s end
        gui.igSameLine(0, -1)
    end
end)

M.register_panel("msg_viewer", "Raw Stream Viewer", function(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }; state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Stream...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}; for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Stream", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local buf = state.message_buffers[p_state.selected_ch.id]
        if buf and buf.size > 0 then
            gui.igBeginChild_Str("MsgScroll", static.v2_zero, true, 0)
            local sz = math.min(buf.size, 1023)
            for i=0, sz-1 do local b = buf.data[i]; static.scratch_chars[i] = (b >= 32 and b <= 126) and b or 46 end
            static.scratch_chars[sz] = 0; gui.igTextWrapped(static.scratch_chars); gui.igEndChild()
        else gui.igTextDisabled("(No data)") end
    end
end)

M.register_panel("hex_viewer", "Hex Dump Viewer", function(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }; state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Hex...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}; for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Hex", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local buf = state.message_buffers[p_state.selected_ch.id]
        if buf and buf.size > 0 then
            gui.igBeginChild_Str("HexScroll", static.v2_zero, true, 0)
            for i=0, math.min(buf.size-1, 511), 16 do
                local r = buf.data + i; local sz = math.min(16, buf.size - i)
                if sz == 16 then gui.igText("%04X: %02X %02X %02X %02X %02X %02X %02X %02X  %02X %02X %02X %02X %02X %02X %02X %02X", i, r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10],r[11],r[12],r[13],r[14],r[15]) end
            end
            gui.igEndChild()
        end
    end
end)

M.register_panel("plotter", "2D Data Plotter", function(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }; state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Plot...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}; for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Plot", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local hist = state.plot_history[p_state.selected_ch.id]
        if hist and gui.ImPlot_BeginPlot("Data", static.v2_full, 0) then
            gui.ImPlot_SetupAxes("T", "V", 0, 0); gui.ImPlot_PlotLine_FloatPtrInt("V", hist, 1000, 1.0, 0, static.plot_spec); gui.ImPlot_EndPlot()
        end
    end
end)

M.register_panel("pretty_viewer", "Pretty Message Viewer", function(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }; state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Pretty View...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}; for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Pretty View", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local ch = p_state.selected_ch; local buf = state.message_buffers[ch.id]
        if buf and buf.size > 0 then
            if gui.igTreeNode_Str("Metadata") then gui.igText("Topic: %s", ch.topic); gui.igText("Type: %s", ch.schema); gui.igText("Size: %d bytes", buf.size); gui.igTreePop() end
            if ch.topic == "lidar" then
                if gui.igTreeNode_Str("PointCloud2 Table") then
                    if gui.igBeginTable("PtsTable", 4, bit.bor(Flags.TableBorders, Flags.TableResizable), static.v2_table, 0) then
                        gui.igTableSetupColumn("Idx", 0, 0, 0); gui.igTableSetupColumn("X", 0, 0, 0); gui.igTableSetupColumn("Y", 0, 0, 0); gui.igTableSetupColumn("Z", 0, 0, 0); gui.igTableHeadersRow()
                        local f = ffi.cast("float*", buf.data)
                        for i=0, 49 do gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%d", i); gui.igTableNextColumn(); gui.igText("%.3f", f[i*3]); gui.igTableNextColumn(); gui.igText("%.3f", f[i*3+1]); gui.igTableNextColumn(); gui.igText("%.3f", f[i*3+2]) end
                        gui.igEndTable()
                    end; gui.igTreePop()
                end
            elseif ch.topic == "pose" then
                local p = ffi.cast("Pose*", buf.data)
                gui.igTextColored(static.v4_val, "Position: (%.3f, %.3f, %.3f)", p.x, p.y, p.z)
                gui.igTextColored(static.v4_val, "Orientation (Yaw): %.3f rad", p.yaw)
            elseif buf.size >= 4 then gui.igTextColored(static.v4_val, "Numeric Value: %.4f", ffi.cast("float*", buf.data)[0]) end
        else gui.igTextDisabled("(No data received yet)") end
    end
end)

M.register_panel("perf", "Performance Stats", function(gui, node_id)
    gui.igText("System Status")
    gui.igSeparator()
    gui.igText("FPS: %.1f", gui.igGetIO_Nil().Framerate)
    gui.igText("Frame Time: %.3f ms", 1000.0 / gui.igGetIO_Nil().Framerate)
    gui.igSeparator()
    gui.igText("Lua Heap: %.2f MB", collectgarbage("count") / 1024)
    gui.igText("Active Streams: %d", #state.channels)
end)

M.register_panel("topics", "Topic List", function(gui, node_id)
    gui.igText("Discovered Topics")
    gui.igSeparator()
    if gui.igBeginTable("TopicTable", 3, bit.bor(Flags.TableBorders, Flags.TableResizable), static.v2_zero, 0) then
        gui.igTableSetupColumn("Topic", 0, 0, 0); gui.igTableSetupColumn("Type", 0, 0, 0); gui.igTableSetupColumn("ID", 0, 0, 0); gui.igTableHeadersRow()
        for _, ch in ipairs(state.channels) do
            gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%s", ch.topic); gui.igTableNextColumn(); gui.igText("%s", ch.schema); gui.igTableNextColumn(); gui.igText("%d", ch.id)
        end
        gui.igEndTable()
    end
end)

function M.init()
    local instance, phys = vulkan.get_instance(), vulkan.get_physical_device()
    device, queue, graphics_family = vulkan.get_device(), vulkan.get_queue()
    sw = swapchain.new(instance, phys, device, _G._SDL_WINDOW)
    robot.init_bridge(); imgui.init(); imgui_renderer = require("imgui.renderer")
    os.execute("rm -f test_robot.mcap"); robot.lib.mcap_generate_test_file(state.mcap_path)
    state.bridge = robot.lib.mcap_open(state.mcap_path); if state.bridge == nil then error("Bridge fail") end
    state.start_time, state.end_time = robot.lib.mcap_get_start_time(state.bridge), robot.lib.mcap_get_end_time(state.bridge)
    state.current_time_ns = state.start_time; state.playback_time_ns = state.start_time; discover_topics()
    state.last_ticks = ffi.C.SDL_GetTicks()
    robot.lib.mcap_next(state.bridge, state.current_msg) -- Get first baseline message
    raw_buffer = mc.buffer(M.points_count * 12, "storage", nil, true)
    point_buffer = mc.buffer(M.points_count * 16, "storage", nil, false)
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffer.handle, 0, raw_buffer.size, 10)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, point_buffer.handle, 0, point_buffer.size, 11)
    local bl_layout = mc.gpu.get_bindless_layout()
    layout_parse = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }}))
    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }}))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, alpha_blend = true, color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB } })
    
    pipe_line = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/line.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/line.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, 
        alpha_blend = true, 
        color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB },
        vertex_binding_descriptions = { { binding = 0, stride = ffi.sizeof("LineVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX } },
        vertex_attribute_descriptions = { 
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 12 }
        }
    })

    -- Generate Grid (20x20, 1m)
    local verts = {}
    local function add_line(x1,y1,z1, x2,y2,z2, r,g,b,a)
        table.insert(verts, {x=x1,y=y1,z=z1, r=r,g=g,b=b,a=a})
        table.insert(verts, {x=x2,y=y2,z=z2, r=r,g=g,b=b,a=a})
    end
    for i = -10, 10 do
        local alpha = (i == 0) and 0.5 or 0.2
        add_line(i, -10, 0, i, 10, 0, 1, 1, 1, alpha)
        add_line(-10, i, 0, 10, i, 0, 1, 1, 1, alpha)
    end
    -- Axis Triad
    add_line(0,0,0, 2,0,0, 1,0,0,1) -- X=Red
    add_line(0,0,0, 0,2,0, 0,1,0,1) -- Y=Green
    add_line(0,0,0, 0,0,2, 0,0,1,1) -- Z=Blue
    line_count = #verts
    line_buffer = mc.buffer(line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)
    local p_verts = ffi.cast("LineVertex*", line_buffer.allocation.ptr)
    for i, v in ipairs(verts) do p_verts[i-1] = v end

    robot_line_count = 24 -- 12 lines for a box
    robot_buffer = mc.buffer(robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)

    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS); image_available_sem = pS[0]

    imgui.on_callback = function(cb_handle, callback_ptr, data_ptr)
        local data = ffi.cast("LidarCallbackData*", data_ptr); if data == nil then return end
        local rx, ry = mc.rad(state.cam.orbit_x), mc.rad(state.cam.orbit_y)
        static.cam_target.x, static.cam_target.y, static.cam_target.z = state.cam.target[1], state.cam.target[2], state.cam.target[3]
        static.cam_pos.x = static.cam_target.x + state.cam.dist * math.cos(ry) * math.cos(rx)
        static.cam_pos.y = static.cam_target.y + state.cam.dist * math.cos(ry) * math.sin(rx)
        static.cam_pos.z = static.cam_target.z + state.cam.dist * math.sin(ry)
        local p
        if state.cam.ortho then
            local h = state.cam.dist * 0.5
            local w = h * (data.w / data.h)
            p = mc.mat4_ortho(-w, w, -h, h, -1000.0, 1000.0)
        else
            p = mc.mat4_perspective(mc.rad(45), data.w/data.h, 0.1, 1000.0)
        end
        local v = mc.mat4_look_at({static.cam_pos.x, static.cam_pos.y, static.cam_pos.z}, {static.cam_target.x, static.cam_target.y, static.cam_target.z}, {0,0,1})
        local mvp = mc.mat4_multiply(p, v)
        for i=0,15 do static.pc_r.view_proj[i] = mvp.m[i] end
        static.pc_r.buf_idx, static.pc_r.point_size = 11, 3.0
        
        local sx, sy = _G._WIN_PW / _G._WIN_LW, _G._WIN_PH / _G._WIN_LH
        static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height, static.viewport.minDepth, static.viewport.maxDepth = data.x*sx, data.y*sy, data.w*sx, data.h*sy, 0, 1
        vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport); static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = data.x*sx, data.y*sy, data.w*sx, data.h*sy
        vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)

        -- 1. Draw Grid and Axes
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_line)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
        static.v_buffs[0] = line_buffer.handle
        vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
        vk.vkCmdDraw(cb_handle, line_count, 1, 0, 0)

        -- 1b. Draw Robot
        static.v_buffs[0] = robot_buffer.handle
        vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
        vk.vkCmdDraw(cb_handle, robot_line_count, 1, 0, 0)

        -- 2. Draw Lidar
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
        vk.vkCmdDraw(cb_handle, M.points_count, 1, 0, 0)

        -- 3. Draw Orientation Gizmo (Bottom Right)
        local gz_size = 80 * sx
        static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height = (data.x + data.w)*sx - gz_size - 10*sx, (data.y + data.h)*sy - gz_size - 10*sy, gz_size, gz_size
        vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
        static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height
        vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)

        local gp = mc.mat4_ortho(-2, 2, -2, 2, -10, 10)
        local gv = mc.mat4_look_at({static.cam_pos.x - static.cam_target.x, static.cam_pos.y - static.cam_target.y, static.cam_pos.z - static.cam_target.z}, {0,0,0}, {0,0,1})
        local gmvp = mc.mat4_multiply(gp, gv)
        for i=0,15 do static.pc_r.view_proj[i] = gmvp.m[i] end
        
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_line)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
        static.v_buffs[0] = line_buffer.handle
        vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
        vk.vkCmdDraw(cb_handle, 6, 1, 84, 0) -- Draw only the 3 axis lines (last 6 verts)

        -- 4. Restore ImGui State
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.pipeline)
        static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height = 0, 0, _G._WIN_PW, _G._WIN_PH
        vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
        static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = 0, 0, _G._WIN_PW, _G._WIN_PH
        vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)
        static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height = 0, 0, _G._WIN_PW, _G._WIN_PH
        vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport); static.sets[0] = mc.gpu.get_bindless_set()
        vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.layout, 0, 1, static.sets, 0, nil)
        static.v_buffs[0] = imgui_renderer.v_buffer.handle
        vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
        vk.vkCmdBindIndexBuffer(cb_handle, imgui_renderer.i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT16)
    end
end

local function render_fuzzy_picker(gui)
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {_G._WIN_LW/2, 100}), 0, static.v2_picker)
    gui.igSetNextWindowSize(ffi.new("ImVec2_c", {400, 0}), 0)
    if gui.igBeginPopupModal("FuzzyPicker", nil, bit.bor(Flags.AlwaysAutoResize, Flags.AlwaysOnTop)) then
        if gui.igInputText("##Search", state.picker.query, 128, 0, nil, nil) then
            state.picker.results = {}; local q = ffi.string(state.picker.query):lower()
            for _, item in ipairs(state.picker.items) do if item.name:lower():find(q, 1, true) then table.insert(state.picker.results, item) end end
            state.picker.selected_idx = 0
        end
        gui.igSetKeyboardFocusHere(-1)
        for i, item in ipairs(state.picker.results) do
            if gui.igSelectable_Bool(item.name, i-1 == state.picker.selected_idx, 0, static.v2_zero) then state.picker.on_select(item); gui.igCloseCurrentPopup() end
        end
        if input.key_pressed(Keys.ESC) then gui.igCloseCurrentPopup() end
        if input.key_pressed(Keys.DOWN) then state.picker.selected_idx = (state.picker.selected_idx + 1) % #state.picker.results end
        if input.key_pressed(Keys.UP) then state.picker.selected_idx = (state.picker.selected_idx - 1 + #state.picker.results) % #state.picker.results end
        if input.key_pressed(Keys.ENTER) and state.picker.results[state.picker.selected_idx+1] then state.picker.on_select(state.picker.results[state.picker.selected_idx+1]); gui.igCloseCurrentPopup() end
        gui.igEndPopup()
    end
end

local function render_node(node, x, y, w, h, gui)
    if node.type == "split" then
        if node.direction == "v" then local w1 = w * node.ratio; render_node(node.children[1], x, y, w1, h, gui); render_node(node.children[2], x+w1, y, w-w1, h, gui)
        else local h1 = h * node.ratio; render_node(node.children[1], x, y, w, h1, gui); render_node(node.children[2], x, y+h1, w, h - h1, gui) end
    else
        gui.igSetNextWindowPos(ffi.new("ImVec2_c", {x, y}), 0, static.v2_zero)
        gui.igSetNextWindowSize(ffi.new("ImVec2_c", {w, h}), 0)
        if gui.igBegin(node.title, nil, Flags.NoDecoration) then
            if gui.igIsWindowHovered(0) then state.focused_id = node.id end
            if state.picker.trigger and state.focused_id == node.id then gui.igOpenPopup_Str("FuzzyPicker", 0); state.picker.trigger = false end
            render_fuzzy_picker(gui)
            local p = M.panels[node.view_type]; if p then p.render(gui, node.id) end
        end; gui.igEnd()
    end
end

function M.update()
    static.fences[0] = frame_fence; vk.vkWaitForFences(device, 1, static.fences, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, static.fences)
    local img_idx = sw:acquire_next_image(image_available_sem); if img_idx == nil then return end
    collectgarbage("step", 100); local ctrl = input.key_down(Keys.CTRL_L) or input.key_down(Keys.CTRL_R)

    local ticks = ffi.C.SDL_GetTicks()
    state.dt = tonumber(ticks - state.last_ticks) / 1000.0
    state.last_ticks = ticks

    if ctrl then
        if input.key_pressed(Keys.V) then split_focused("v") end
        if input.key_pressed(Keys.H) then split_focused("h") end
        if input.key_pressed(Keys.X) then close_focused() end
        if input.key_pressed(Keys.P) then
            local items = {}; for id, p in pairs(M.panels) do table.insert(items, { name = p.name, id = id }) end
            open_picker("Select Panel", items, function(item) replace_focused_view(item.id) end)
        end
    end
    local gui, io = imgui.gui, imgui.gui.igGetIO_Nil()
    if input.mouse_down(3) and not io.WantCaptureMouse then 
        local rmx, rmy = input.mouse_delta(); state.cam.orbit_x, state.cam.orbit_y = state.cam.orbit_x + rmx * 0.2, math.max(-89, math.min(89, state.cam.orbit_y - rmy * 0.2))
    end
    -- Middle-click Pan
    if input.mouse_down(2) and not io.WantCaptureMouse then
        local rmx, rmy = input.mouse_delta()
        local rx = mc.rad(state.cam.orbit_x)
        local right_x, right_y = -math.sin(rx), math.cos(rx)
        local scale = state.cam.dist * 0.001
        state.cam.target[1] = state.cam.target[1] - right_x * rmx * scale
        state.cam.target[2] = state.cam.target[2] - right_y * rmx * scale
        state.cam.target[3] = state.cam.target[3] + rmy * scale
    end
    -- Scroll Zoom
    if not io.WantCaptureMouse then
        local wheel = _G._MOUSE_WHEEL or 0
        if wheel ~= 0 then
            state.cam.dist = math.max(1, state.cam.dist - wheel * state.cam.dist * 0.1)
            _G._MOUSE_WHEEL = 0 -- Consume wheel
        end
    end
    -- Toggle Ortho
    if input.key_pressed(Keys.O) and ctrl then state.cam.ortho = not state.cam.ortho end

    if state.seek_to then
        robot.lib.mcap_seek(state.bridge, state.seek_to)
        state.playback_time_ns = state.seek_to
        state.seek_to = nil
        robot.lib.mcap_next(state.bridge, state.current_msg)
    elseif not state.paused then
        state.playback_time_ns = state.playback_time_ns + ffi.cast("uint64_t", state.dt * 1e9 * state.speed)
    end

    -- Loop through messages until the bag time catches up to our playback clock
    while (not state.paused or state.seek_to) and state.current_msg.log_time < state.playback_time_ns do
        local ch_id = state.current_msg.channel_id
        if state.current_msg.data ~= nil then 
            local buf = state.message_buffers[ch_id]; if not buf then buf = { data = ffi.new("uint8_t[4096]"), size = 0 }; state.message_buffers[ch_id] = buf end
            local sz = math.min(tonumber(state.current_msg.data_size), 4096); ffi.copy(buf.data, state.current_msg.data, sz); buf.size = sz
            if sz >= 4 then local h = state.plot_history[ch_id]; if not h then h = ffi.new("float[1000]"); state.plot_history[ch_id] = h end; for i=0, 998 do h[i] = h[i+1] end; h[999] = ffi.cast("float*", state.current_msg.data)[0] end
            if ch_id == state.pose_ch_id then
                local p = ffi.cast("Pose*", state.current_msg.data)
                state.robot_pose.x, state.robot_pose.y, state.robot_pose.z, state.robot_pose.yaw = p.x, p.y, p.z, p.yaw
            end
        end
        if ch_id == state.lidar_ch_id and raw_buffer.allocation.ptr ~= nil then ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, math.min(tonumber(state.current_msg.data_size), raw_buffer.size)) end
        
        if not robot.lib.mcap_next(state.bridge, state.current_msg) then
            robot.lib.mcap_rewind(state.bridge)
            state.playback_time_ns = state.start_time
            robot.lib.mcap_next(state.bridge, state.current_msg)
            break
        end
    end
    
    state.current_time_ns = state.playback_time_ns

    -- Update Robot Buffer (always do this based on latest state.robot_pose)
    local rv = ffi.cast("LineVertex*", robot_buffer.allocation.ptr)
    local px, py, pz, yaw = state.robot_pose.x, state.robot_pose.y, state.robot_pose.z, state.robot_pose.yaw
    local s, c = math.sin(yaw), math.cos(yaw)
    local function add_robot_line(idx, x1,y1,z1, x2,y2,z2, r,g,b,a)
        local rx1, ry1 = x1*c - y1*s, x1*s + y1*c
        local rx2, ry2 = x2*c - y2*s, x2*s + y2*c
        rv[idx].x, rv[idx].y, rv[idx].z = px+rx1, py+ry1, pz+z1
        rv[idx].r, rv[idx].g, rv[idx].b, rv[idx].a = r, g, b, a
        rv[idx+1].x, rv[idx+1].y, rv[idx+1].z = px+rx2, py+ry2, pz+z2
        rv[idx+1].r, rv[idx+1].g, rv[idx+1].b, rv[idx+1].a = r, g, b, a
        return idx + 2
    end
    local cur_i = 0
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0,  0.5,-0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0,  0.5, 0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0, -0.5, 0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0, -0.5,-0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0.5,  0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0.5,  0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0.5, -0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0.5, -0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0, -0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0,  0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0,  0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0, -0.5, 0.5,0.5, 1,1,0,1)
    callback_data_idx = 1; imgui.new_frame(); render_node(state.layout, 0, 0, _G._WIN_LW, _G._WIN_LH, gui)
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, static.cb_begin)
    static.pc_p.in_buf_idx, static.pc_p.in_offset_u32, static.pc_p.out_buf_idx, static.pc_p.count = 10, 0, 11, M.points_count
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse); static.sets[0] = bindless_set; vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, static.sets, 0, nil); vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), static.pc_p); vk.vkCmdDispatch(cb, math.ceil(M.points_count / 256), 1, 1)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, static.mem_barrier, 0, nil, 0, nil)
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout, static.img_barrier[0].image, static.img_barrier[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, ffi.cast("VkImage", sw.images[img_idx]), vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier)
    static.attachments[0].sType, static.attachments[0].imageView, static.attachments[0].imageLayout, static.attachments[0].loadOp, static.attachments[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    static.attachments[0].clearValue.color.float32[0], static.attachments[0].clearValue.color.float32[1], static.attachments[0].clearValue.color.float32[2], static.attachments[0].clearValue.color.float32[3] = 0.05, 0.05, 0.07, 1.0
    static.render_info.renderArea.extent = sw.extent; static.render_info.pColorAttachments = static.attachments; vk.vkCmdBeginRendering(cb, static.render_info)
    static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height, static.viewport.minDepth, static.viewport.maxDepth = 0, 0, _G._WIN_PW, _G._WIN_PH, 0, 1; vk.vkCmdSetViewport(cb, 0, 1, static.viewport)
    static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = 0, 0, sw.extent.width, sw.extent.height; vk.vkCmdSetScissor(cb, 0, 1, static.scissor); imgui.render(cb); vk.vkCmdEndRendering(cb)
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier); vk.vkEndCommandBuffer(cb)
    static.sems_wait[0], static.sems_sig[0], static.cbs[0] = image_available_sem, sw.semaphores[img_idx], cb; static.submit_info.pWaitSemaphores, static.submit_info.pWaitDstStageMask, static.submit_info.pCommandBuffers, static.submit_info.pSignalSemaphores = static.sems_wait, static.wait_stages, static.cbs, static.sems_sig
    vk.vkQueueSubmit(queue, 1, static.submit_info, frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
