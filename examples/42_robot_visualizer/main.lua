local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local input = require("mc.input")
local mc = require("mc")
local robot = require("mc.robot")
local bit = require("bit")

_G.IMGUI_LIB_PATH = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local imgui = require("imgui")

-- 1. FFI DEFINITIONS
ffi.cdef[[
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
    bool igTreeNode_Str(const char* label);
    void igTreePop(void);
    bool igBeginTable(const char* str_id, int column, int flags, const ImVec2_c outer_size, float inner_width);
    void igEndTable(void);
    void igTableNextRow(int row_flags, float min_row_height);
    bool igTableNextColumn(void);
    void igTableSetupColumn(const char* label, int flags, float init_width_or_weight, ImGuiID user_id);
    void igTableHeadersRow(void);
    void ImPlot_SetupAxes(const char* x_label, const char* y_label, ImPlotFlags x_flags, ImPlotFlags y_flags);
    void ImPlot_PlotLine_FloatPtrInt(const char* label_id, const float* values, int count, double xscale, double x0, const ImPlotSpec_c spec);
]]

local Flags = { NoDecoration = 43, AlwaysAutoResize = 64, AlwaysOnTop = 262144, TableBorders = 3, TableResizable = 16 }
local Keys = { CTRL_L = 224, CTRL_R = 228, V = 25, H = 11, X = 27, P = 19, ESC = 41, ENTER = 40, UP = 82, DOWN = 81 }

local state = {
    mcap_path = "test_robot.mcap", points_count = 10000, paused = false,
    current_msg = ffi.new("McapMessage"), bridge = nil,
    start_time = 0ULL, end_time = 0ULL, current_time_ns = 0ULL,
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = {0, 0, 5} },
    channels = {}, lidar_ch_id = 0, last_messages = {}, plot_history = {}, 
    layout = { type = "view", view_type = "lidar", id = 1 }, next_id = 2, focused_id = 1, panel_states = {},
    picker = { trigger = false, title = "", query = ffi.new("char[128]"), selected_idx = 0, items = {}, results = {}, on_select = nil }
}

local M = state
local device, queue, graphics_family, sw, cb
local pipe_layout, pipe_parse, pipe_render, layout_parse
local bindless_set, image_available_sem, frame_fence
local raw_buffer, point_buffer

local callback_data_pool = {}
for i=1, 10 do table.insert(callback_data_pool, ffi.new("LidarCallbackData")) end
local callback_data_idx = 1
local default_plot_spec = ffi.new("ImPlotSpec_c", { Stride = 4 })

M.panels = {}
function M.register_panel(id, name, render_func) M.panels[id] = { id = id, name = name, render = render_func } end

local function open_picker(title, items, on_select)
    state.picker.trigger, state.picker.title, state.picker.items, state.picker.results, state.picker.selected_idx, state.picker.on_select = true, title, items, items, 0, on_select
    ffi.fill(state.picker.query, 128)
end

local function split_focused(direction)
    local function find_and_split(node)
        if node.type == "view" then
            if node.id == state.focused_id then
                local old = node.view_type
                node.type, node.direction, node.ratio = "split", direction, 0.5
                node.children = { { type = "view", view_type = old, id = node.id }, { type = "view", view_type = "empty", id = state.next_id } }
                state.next_id = state.next_id + 1
                return true
            end
        else return find_and_split(node.children[1]) or find_and_split(node.children[2]) end
        return false
    end
    find_and_split(state.layout)
end

local function close_focused()
    local function find_and_close(node, parent)
        if node.type == "view" then
            if node.id == state.focused_id and parent then
                local other = (parent.children[1] == node) and parent.children[2] or parent.children[1]
                for k,v in pairs(other) do parent[k] = v end
                return true
            end
        else return find_and_close(node.children[1], node) or find_and_close(node.children[2], node) end
        return false
    end
    find_and_close(state.layout, nil)
end

local function replace_focused_view(new_type)
    local function find_and_replace(node)
        if node.type == "view" then
            if node.id == state.focused_id then node.view_type = new_type; return true end
        else return find_and_replace(node.children[1]) or find_and_replace(node.children[2]) end
        return false
    end
    find_and_replace(state.layout)
end

local function render_lidar_view(gui, node_id)
    if gui.ImPlot_BeginPlot("Lidar Cloud", ffi.new("ImVec2_c", {-1, -1}), 8) then
        local p, s = gui.ImPlot_GetPlotPos(), gui.ImPlot_GetPlotSize()
        local data = callback_data_pool[callback_data_idx]
        callback_data_idx = (callback_data_idx % 10) + 1
        data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
        gui.ImDrawList_AddCallback(gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
        gui.ImPlot_EndPlot()
    end
end

local function render_telemetry_view(gui, node_id)
    gui.igText("Playback Control")
    gui.igSeparator()
    if not state.paused then gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, 1}), "LIVE")
    else gui.igTextColored(ffi.new("ImVec4_c", {1, 0, 0, 1}), "PAUSED") end
    gui.igText("Time: " .. tostring(state.current_time_ns) .. " ns")
    local progress = (state.end_time > state.start_time) and tonumber(state.current_time_ns - state.start_time) / tonumber(state.end_time - state.start_time) or 0
    local p_ptr = ffi.new("float[1]", progress)
    if gui.igSliderFloat("Timeline", p_ptr, 0.0, 1.0, "%.2f", 0) then
        state.paused = true
        robot.lib.mcap_seek(state.bridge, state.start_time + ffi.cast("uint64_t", p_ptr[0] * tonumber(state.end_time - state.start_time)))
    end
    if gui.igButton(state.paused and "Resume" or "Pause", ffi.new("ImVec2_c", {0, 0})) then state.paused = not state.paused end
end

local function render_msg_viewer(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }
    state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Stream...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}
        for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Stream", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local ch = p_state.selected_ch
        local msg = state.last_messages[ch.id]
        if msg then
            gui.igBeginChild_Str("MsgScroll", ffi.new("ImVec2_c", {0, 0}), true, 0)
            local sanitized = ""
            for i=1, math.min(#msg, 512) do
                local b = msg:byte(i)
                sanitized = sanitized .. ((b >= 32 and b <= 126) and string.char(b) or ".")
            end
            gui.igTextWrapped(sanitized)
            gui.igEndChild()
        else gui.igTextDisabled("(No data)") end
    end
end

local function render_hex_viewer(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }
    state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Hex Stream...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}
        for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Hex Stream", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local ch = p_state.selected_ch
        local msg = state.last_messages[ch.id]
        if msg then
            gui.igBeginChild_Str("HexScroll", ffi.new("ImVec2_c", {0, 0}), true, 0)
            for i=0, math.min(#msg-1, 511), 16 do
                local line = string.format("%04X: ", i)
                for j=0, 15 do
                    if i+j < #msg then line = line .. string.format("%02X ", msg:byte(i+j+1))
                    else line = line .. "   " end
                end
                gui.igText(line)
            end
            gui.igEndChild()
        else gui.igTextDisabled("(No data)") end
    end
end

local function render_plotter_view(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }
    state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Plot...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}
        for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Plot", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local hist = state.plot_history[p_state.selected_ch.id]
        if hist then
            if gui.ImPlot_BeginPlot("Data", ffi.new("ImVec2_c", {-1, -1}), 0) then
                gui.ImPlot_SetupAxes("T", "V", 0, 0)
                gui.ImPlot_PlotLine_FloatPtrInt("V", hist, 1000, 1.0, 0, default_plot_spec)
                gui.ImPlot_EndPlot()
            end
        else gui.igTextDisabled("(No numeric data)") end
    end
end

local function render_pretty_viewer(gui, node_id)
    local p_state = state.panel_states[node_id] or { selected_ch = nil }
    state.panel_states[node_id] = p_state
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Pretty View...", ffi.new("ImVec2_c", {-1, 25})) then
        local items = {}
        for _, ch in ipairs(state.channels) do table.insert(items, { name = ch.topic, data = ch }) end
        open_picker("Select Pretty View", items, function(it) p_state.selected_ch = it.data end)
    end
    if p_state.selected_ch then
        local ch = p_state.selected_ch
        local msg = state.last_messages[ch.id]
        if msg then
            if gui.igTreeNode_Str("Metadata") then
                gui.igText("Topic: %s", ch.topic); gui.igText("Encoding: %s", ch.encoding); gui.igText("Schema: %s", ch.schema); gui.igText("Size: %d bytes", #msg)
                gui.igTreePop()
            end
            if ch.topic == "lidar" then
                if gui.igTreeNode_Str("PointCloud2 Data") then
                    local points = #msg / 12
                    if gui.igBeginTable("PointsTable", 4, bit.bor(Flags.TableBorders, Flags.TableResizable), ffi.new("ImVec2_c", {0, 200}), 0) then
                        gui.igTableSetupColumn("Index", 0, 0, 0); gui.igTableSetupColumn("X", 0, 0, 0); gui.igTableSetupColumn("Y", 0, 0, 0); gui.igTableSetupColumn("Z", 0, 0, 0)
                        gui.igTableHeadersRow()
                        local floats = ffi.cast("float*", msg)
                        for i=0, math.min(points-1, 50) do
                            gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%d", i)
                            gui.igTableNextColumn(); gui.igText("%.3f", floats[i*3+0]); gui.igTableNextColumn(); gui.igText("%.3f", floats[i*3+1]); gui.igTableNextColumn(); gui.igText("%.3f", floats[i*3+2])
                        end
                        gui.igEndTable()
                    end
                    gui.igTreePop()
                end
            elseif #msg >= 4 then
                local val = ffi.cast("float*", msg)[0]
                gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, 1}), "Float Value: %.4f", val)
            end
        else gui.igTextDisabled("(No data received yet)") end
    end
end

local function render_perf(gui, node_id)
    gui.igText("System Performance")
    gui.igSeparator()
    gui.igText("FPS: %.1f", gui.igGetIO_Nil().Framerate)
    gui.igText("Frame Time: %.3f ms", 1000.0 / gui.igGetIO_Nil().Framerate)
    gui.igSeparator()
    gui.igText("Memory Usage: %.2f MB", collectgarbage("count") / 1024)
end

local function render_topics(gui, node_id)
    gui.igText("Discovered Topics")
    gui.igSeparator()
    if gui.igBeginTable("TopicTable", 3, bit.bor(Flags.TableBorders, Flags.TableResizable), ffi.new("ImVec2_c", {0, 0}), 0) then
        gui.igTableSetupColumn("Topic", 0, 0, 0); gui.igTableSetupColumn("Type", 0, 0, 0); gui.igTableSetupColumn("ID", 0, 0, 0)
        gui.igTableHeadersRow()
        for _, ch in ipairs(state.channels) do
            gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%s", ch.topic)
            gui.igTableNextColumn(); gui.igText("%s", ch.schema); gui.igTableNextColumn(); gui.igText("%d", ch.id)
        end
        gui.igEndTable()
    end
end

M.register_panel("lidar", "Lidar Cloud", render_lidar_view)
M.register_panel("telemetry", "Playback Controls", render_telemetry_view)
M.register_panel("msg_viewer", "Raw Stream Viewer", render_msg_viewer)
M.register_panel("hex_viewer", "Hex Dump Viewer", render_hex_viewer)
M.register_panel("plotter", "2D Data Plotter", render_plotter_view)
M.register_panel("pretty_viewer", "Pretty Message Viewer", render_pretty_viewer)
M.register_panel("perf", "Performance Stats", render_perf)
M.register_panel("topics", "Topic List", render_topics)

local pc_p_obj, pc_r_obj = ffi.new("ParserPC"), ffi.new("RenderPC")
local viewport_obj, scissor_obj, attachment_info_obj = ffi.new("VkViewport"), ffi.new("VkRect2D"), ffi.new("VkRenderingAttachmentInfo[1]")
local cb_begin_info, wait_stage_mask = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }), ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})

local function discover_topics()
    local count = robot.lib.mcap_get_channel_count(state.bridge)
    print("[42] Bridge reported " .. count .. " channels.")
    state.channels = {}
    local info = ffi.new("McapChannelInfo")
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(state.bridge, i, info) then
            local t = ffi.string(info.topic)
            if t == "lidar" then state.lidar_ch_id = info.id end
            table.insert(state.channels, { id = info.id, topic = t, encoding = ffi.string(info.message_encoding), schema = ffi.string(info.schema_name), active = true })
            print("  - Discovered Stream: " .. t .. " (ID: " .. info.id .. ")")
        end
    end
end

function M.init()
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    robot.init_bridge()
    imgui.init()
    os.execute("rm -f test_robot.mcap")
    robot.lib.mcap_generate_test_file(state.mcap_path)
    state.bridge = robot.lib.mcap_open(state.mcap_path)
    state.start_time, state.end_time = robot.lib.mcap_get_start_time(state.bridge), robot.lib.mcap_get_end_time(state.bridge)
    state.current_time_ns = state.start_time
    discover_topics()

    raw_buffer = mc.buffer(M.points_count * 12, "storage", nil, true)
    point_buffer = mc.buffer(M.points_count * 16, "storage", nil, false)
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffer.handle, 0, raw_buffer.size, 10)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, point_buffer.handle, 0, point_buffer.size, 11)
    
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_p_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }})
    layout_parse = pipeline.create_layout(device, {bl_layout}, pc_p_range)
    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local pc_r_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_r_range)
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, alpha_blend = true, color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB } })

    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS); image_available_sem = pS[0]

    imgui.on_callback = function(cb_handle, callback_ptr, data_ptr)
        local data = ffi.cast("LidarCallbackData*", data_ptr)
        if data == nil then return end
        local rx, ry = mc.rad(state.cam.orbit_x), mc.rad(state.cam.orbit_y)
        local cp = { state.cam.target[1] + state.cam.dist * math.cos(ry) * math.cos(rx), state.cam.target[2] + state.cam.dist * math.cos(ry) * math.sin(rx), state.cam.target[3] + state.cam.dist * math.sin(ry) }
        local mvp = mc.mat4_multiply(mc.mat4_perspective(mc.rad(45), data.w/data.h, 0.1, 1000.0), mc.mat4_look_at(cp, state.cam.target, {0,0,1}))
        for i=0,15 do pc_r_obj.view_proj[i] = mvp.m[i] end
        pc_r_obj.buf_idx, pc_r_obj.point_size = 11, 3.0
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), pc_r_obj)
        local sx, sy = _G._WIN_PW / _G._WIN_LW, _G._WIN_PH / _G._WIN_LH
        viewport_obj.x, viewport_obj.y, viewport_obj.width, viewport_obj.height = data.x*sx, data.y*sy, data.w*sx, data.h*sy
        viewport_obj.minDepth, viewport_obj.maxDepth = 0, 1
        vk.vkCmdSetViewport(cb_handle, 0, 1, viewport_obj)
        scissor_obj.offset.x, scissor_obj.offset.y, scissor_obj.extent.width, scissor_obj.extent.height = data.x*sx, data.y*sy, data.w*sx, data.h*sy
        vk.vkCmdSetScissor(cb_handle, 0, 1, scissor_obj)
        vk.vkCmdDraw(cb_handle, M.points_count, 1, 0, 0)
        
        local imgui_renderer = require("imgui.renderer")
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.pipeline)
        viewport_obj.x, viewport_obj.y, viewport_obj.width, viewport_obj.height = 0, 0, _G._WIN_PW, _G._WIN_PH
        vk.vkCmdSetViewport(cb_handle, 0, 1, viewport_obj)
        local sets = ffi.new("VkDescriptorSet[1]", {mc.gpu.get_bindless_set()})
        vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.layout, 0, 1, sets, 0, nil)
        vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, ffi.new("VkBuffer[1]", {imgui_renderer.v_buffer.handle}), ffi.new("VkDeviceSize[1]", {0}))
        vk.vkCmdBindIndexBuffer(cb_handle, imgui_renderer.i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT16)
    end
end

local function render_fuzzy_picker(gui)
    local lw, lh = _G._WIN_LW or 1280, _G._WIN_LH or 720
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {lw/2, 100}), 0, ffi.new("ImVec2_c", {0.5, 0}))
    gui.igSetNextWindowSize(ffi.new("ImVec2_c", {400, 0}), 0)
    if gui.igBeginPopupModal("FuzzyPicker", nil, bit.bor(Flags.AlwaysAutoResize, Flags.AlwaysOnTop)) then
        gui.igText(state.picker.title)
        if gui.igInputText("##Search", state.picker.query, 128, 0, nil, nil) then
            state.picker.results = {}
            local q = ffi.string(state.picker.query):lower()
            for _, item in ipairs(state.picker.items) do if item.name:lower():find(q, 1, true) then table.insert(state.picker.results, item) end end
            state.picker.selected_idx = 0
        end
        gui.igSetKeyboardFocusHere(-1)
        for i, item in ipairs(state.picker.results) do
            local is_sel = (i-1 == state.picker.selected_idx)
            if gui.igSelectable_Bool(item.name, is_sel, 0, ffi.new("ImVec2_c", {0, 0})) then state.picker.on_select(item) gui.igCloseCurrentPopup() end
        end
        if input.key_pressed(Keys.ESC) then gui.igCloseCurrentPopup() end
        if input.key_pressed(Keys.DOWN) then state.picker.selected_idx = (state.picker.selected_idx + 1) % #state.picker.results end
        if input.key_pressed(Keys.UP) then state.picker.selected_idx = (state.picker.selected_idx - 1 + #state.picker.results) % #state.picker.results end
        if input.key_pressed(Keys.ENTER) and state.picker.results[state.picker.selected_idx+1] then state.picker.on_select(state.picker.results[state.picker.selected_idx+1]) gui.igCloseCurrentPopup() end
        gui.igEndPopup()
    end
end

local function render_node(node, x, y, w, h, gui)
    if node.type == "split" then
        if node.direction == "v" then local w1 = w * node.ratio render_node(node.children[1], x, y, w1, h, gui) render_node(node.children[2], x+w1, y, w-w1, h, gui)
        else local h1 = h * node.ratio render_node(node.children[1], x, y, w, h1, gui) render_node(node.children[2], x, y+h1, w, h - h1, gui) end
    else
        gui.igSetNextWindowPos(ffi.new("ImVec2_c", {x, y}), 0, ffi.new("ImVec2_c", {0, 0}))
        gui.igSetNextWindowSize(ffi.new("ImVec2_c", {w, h}), 0)
        if gui.igBegin(string.format("View %d###%d", node.id, node.id), nil, Flags.NoDecoration) then
            if gui.igIsWindowHovered(0) then state.focused_id = node.id end
            if state.picker.trigger and state.focused_id == node.id then gui.igOpenPopup_Str("FuzzyPicker", 0) state.picker.trigger = false end
            render_fuzzy_picker(gui)
            local p = M.panels[node.view_type]
            if p then p.render(gui, node.id)
            else gui.igText("Empty View (ID: %d)", node.id) gui.igText("CTRL+P: Panel Menu") end
        end
        gui.igEnd()
    end
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end
    local ctrl = input.key_down(Keys.CTRL_L) or input.key_down(Keys.CTRL_R)
    if ctrl then
        if input.key_pressed(Keys.V) then split_focused("v") end
        if input.key_pressed(Keys.H) then split_focused("h") end
        if input.key_pressed(Keys.X) then close_focused() end
        if input.key_pressed(Keys.P) then
            local items = {}
            for id, p in pairs(M.panels) do table.insert(items, { name = p.name, id = id }) end
            open_picker("Select Panel", items, function(item) replace_focused_view(item.id) end)
        end
    end
    local gui, io = imgui.gui, imgui.gui.igGetIO_Nil()
    if input.mouse_down(3) and not io.WantCaptureMouse then 
        local rmx, rmy = input.mouse_delta()
        state.cam.orbit_x, state.cam.orbit_y = state.cam.orbit_x + rmx * 0.2, math.max(-89, math.min(89, state.cam.orbit_y - rmy * 0.2))
    end
    if not state.paused then
        if not robot.lib.mcap_next(state.bridge, state.current_msg) then robot.lib.mcap_rewind(state.bridge) robot.lib.mcap_next(state.bridge, state.current_msg) end
        state.current_time_ns = state.current_msg.log_time
        local ch_id = state.current_msg.channel_id
        if state.current_msg.data ~= nil then 
            local msg_len = math.min(tonumber(state.current_msg.data_size), 4096)
            state.last_messages[ch_id] = ffi.string(state.current_msg.data, msg_len)
            if tonumber(state.current_msg.data_size) >= 4 then
                local hist = state.plot_history[ch_id]
                if not hist then hist = ffi.new("float[1000]") state.plot_history[ch_id] = hist end
                for i=0, 998 do hist[i] = hist[i+1] end
                hist[999] = ffi.cast("float*", state.current_msg.data)[0]
            end
        end
        if ch_id == state.lidar_ch_id and raw_buffer.allocation.ptr ~= nil then
            local copy_size = math.min(tonumber(state.current_msg.data_size), raw_buffer.size)
            ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, copy_size)
        end
    end
    callback_data_idx = 1
    imgui.new_frame()
    render_node(state.layout, 0, 0, _G._WIN_LW, _G._WIN_LH, gui)
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, cb_begin_info)
    pc_p_obj.in_buf_idx, pc_p_obj.in_offset_u32, pc_p_obj.out_buf_idx, pc_p_obj.count = 10, 0, 11, M.points_count
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil); vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), pc_p_obj); vk.vkCmdDispatch(cb, math.ceil(M.points_count / 256), 1, 1)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }}), 0, nil, 0, nil)
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    attachment_info_obj[0].sType, attachment_info_obj[0].imageView, attachment_info_obj[0].imageLayout, attachment_info_obj[0].loadOp, attachment_info_obj[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    attachment_info_obj[0].clearValue.color.float32[0], attachment_info_obj[0].clearValue.color.float32[1], attachment_info_obj[0].clearValue.color.float32[2], attachment_info_obj[0].clearValue.color.float32[3] = 0.05, 0.05, 0.07, 1.0
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=attachment_info_obj }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=_G._WIN_PW, height=_G._WIN_PH, minDepth=0, maxDepth=1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset={x=0, y=0}, extent=sw.extent })); imgui.render(cb); vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=wait_stage_mask, commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
