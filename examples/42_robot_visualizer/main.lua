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
    typedef struct ParserPC {
        uint32_t in_buf_idx;
        uint32_t in_offset_u32;
        uint32_t out_buf_idx;
        uint32_t count;
    } ParserPC;

    typedef struct RenderPC {
        float view_proj[16];
        uint32_t buf_idx;
        float point_size;
    } RenderPC;

    typedef struct LidarCallbackData {
        float x, y, w, h;
    } LidarCallbackData;

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
    void igCloseCurrentPopup(void);
    bool igIsItemClicked(int mouse_button);
    bool igIsKeyPressed_Bool(int key, bool repeat);
    void igEndPopup(void);
    void igTextColored(const ImVec4_c col, const char* fmt, ...);
]]

local Flags = {
    NoTitleBar = 1, NoResize = 2, NoMove = 4, NoScrollbar = 8, NoCollapse = 32, NoNav = 128, NoDecoration = 43, AlwaysAutoResize = 64,
}

local Keys = {
    CTRL_L = 224, CTRL_R = 228, V = 25, H = 11, X = 27, P = 19, ESC = 41, ENTER = 40, UP = 82, DOWN = 81
}

local state = {
    mcap_path = "test_robot.mcap",
    points_count = 10000, 
    paused = false,
    current_msg = ffi.new("McapMessage"),
    bridge = nil,
    start_time = 0ULL, end_time = 0ULL, current_time_ns = 0ULL,
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = {0, 0, 5} },
    channels = {},
    layout = { type = "view", view_type = "lidar", id = 1 },
    next_id = 2,
    focused_id = 1,
    fuzzy = { open_trigger = false, query = ffi.new("char[128]"), selected_idx = 0, results = {} }
}

local M = state
local device, queue, graphics_family, sw, cb
local pipe_layout, pipe_parse, pipe_render, layout_parse
local bindless_set, image_available_sem, frame_fence
local raw_buffer, point_buffer

-- PERSISTENT FFI OBJECTS (Avoid GC crashes)
local callback_data_pool = {}
for i=1, 10 do table.insert(callback_data_pool, ffi.new("LidarCallbackData")) end
local callback_data_idx = 1

M.panels = {}
function M.register_panel(id, name, render_func)
    M.panels[id] = { id = id, name = name, render = render_func }
end

local function render_lidar_view(gui)
    if gui.ImPlot_BeginPlot("Lidar Cloud", ffi.new("ImVec2_c", {-1, -1}), 8) then
        local p, s = gui.ImPlot_GetPlotPos(), gui.ImPlot_GetPlotSize()
        local data = callback_data_pool[callback_data_idx]
        callback_data_idx = (callback_data_idx % 10) + 1
        data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
        gui.ImDrawList_AddCallback(gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
        gui.ImPlot_EndPlot()
    end
end

local function render_telemetry_view(gui)
    gui.igText("Telemetry Stream")
    gui.igSeparator()
    if not state.paused then gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, 1}), "LIVE")
    else gui.igTextColored(ffi.new("ImVec4_c", {1, 0, 0, 1}), "PAUSED") end
    gui.igText("Time: %llu ns", state.current_time_ns)
    local progress = 0
    if state.end_time > state.start_time then progress = tonumber(state.current_time_ns - state.start_time) / tonumber(state.end_time - state.start_time) end
    local p_ptr = ffi.new("float[1]", progress)
    if gui.igSliderFloat("Seek", p_ptr, 0.0, 1.0, "%.2f", 0) then
        state.paused = true
        local seek_ns = state.start_time + ffi.cast("uint64_t", p_ptr[0] * tonumber(state.end_time - state.start_time))
        robot.lib.mcap_seek(state.bridge, seek_ns)
        if robot.lib.mcap_next(state.bridge, state.current_msg) then 
            state.current_time_ns = state.current_msg.log_time 
            if raw_buffer.allocation.ptr ~= nil and state.current_msg.data ~= nil then
                local copy_size = math.min(tonumber(state.current_msg.data_size), raw_buffer.size)
                ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, copy_size)
            end
        end
    end
    if gui.igButton(state.paused and "Resume" or "Pause", ffi.new("ImVec2_c", {0, 0})) then state.paused = not state.paused end
end

local function render_topic_explorer(gui)
    gui.igText("Topic Explorer")
    gui.igSeparator()
    for _, ch in ipairs(state.channels) do
        local active_ptr = ffi.new("bool[1]", ch.active)
        if gui.igCheckbox(ch.topic, active_ptr) then ch.active = active_ptr[0] end
    end
end

M.register_panel("lidar", "Lidar Cloud", render_lidar_view)
M.register_panel("telemetry", "Telemetry Controls", render_telemetry_view)
M.register_panel("topics", "Topic Explorer", render_topic_explorer)

local pc_p_obj = ffi.new("ParserPC")
local pc_r_obj = ffi.new("RenderPC")
local viewport_obj = ffi.new("VkViewport")
local scissor_obj = ffi.new("VkRect2D")
local attachment_info_obj = ffi.new("VkRenderingAttachmentInfo[1]")
local cb_begin_info = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO })
local wait_stage_mask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})

local function discover_topics()
    local count = robot.lib.mcap_get_channel_count(state.bridge)
    state.channels = {}
    local info = ffi.new("McapChannelInfo")
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(state.bridge, i, info) then
            table.insert(state.channels, { id = info.id, topic = ffi.string(info.topic), encoding = ffi.string(info.message_encoding), schema = ffi.string(info.schema_name), active = true })
        end
    end
end

function M.init()
    print("[42] Initializing Vulkan...")
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    
    print("[42] Initializing Bridge & ImGui...")
    robot.init_bridge()
    imgui.init()
    
    local f = io.open(state.mcap_path, "r")
    if not f then robot.lib.mcap_generate_test_file(state.mcap_path) else f:close() end
    state.bridge = robot.lib.mcap_open(state.mcap_path)
    if state.bridge == nil then error("Failed to open " .. state.mcap_path) end
    state.start_time = robot.lib.mcap_get_start_time(state.bridge)
    state.end_time = robot.lib.mcap_get_end_time(state.bridge)
    state.current_time_ns = state.start_time
    discover_topics()

    print("[42] Allocating Buffers...")
    raw_buffer = mc.buffer(M.points_count * 12, "storage", nil, true)
    point_buffer = mc.buffer(M.points_count * 16, "storage", nil, false)
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffer.handle, 0, raw_buffer.size, 10)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, point_buffer.handle, 0, point_buffer.size, 11)
    
    print("[42] Creating Pipelines...")
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_p_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }})
    layout_parse = pipeline.create_layout(device, {bl_layout}, pc_p_range)
    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local pc_r_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_r_range)
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, alpha_blend = true, color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB }
    })

    print("[42] Finalizing Sync Objects...")
    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sem = pS[0]

    imgui.on_callback = function(cb_handle, callback_ptr, data_ptr)
        local data = ffi.cast("LidarCallbackData*", data_ptr)
        if data == nil then return end
        local proj = mc.mat4_perspective(mc.rad(45), data.w/data.h, 0.1, 1000.0)
        local rx, ry = mc.rad(state.cam.orbit_x), mc.rad(state.cam.orbit_y)
        local cp = { state.cam.target[1] + state.cam.dist * math.cos(ry) * math.cos(rx), state.cam.target[2] + state.cam.dist * math.cos(ry) * math.sin(rx), state.cam.target[3] + state.cam.dist * math.sin(ry) }
        local view = mc.mat4_look_at(cp, state.cam.target, {0,0,1})
        local mvp = mc.mat4_multiply(proj, view)
        for i=0,15 do pc_r_obj.view_proj[i] = mvp.m[i] end
        pc_r_obj.buf_idx, pc_r_obj.point_size = 11, 3.0
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), pc_r_obj)
        local sx, sy = _G._WIN_PW / _G._WIN_LW, _G._WIN_PH / _G._WIN_LH
        viewport_obj.x, viewport_obj.y, viewport_obj.width, viewport_obj.height = data.x*sx, data.y*sy, data.w*sx, data.h*sy
        viewport_obj.minDepth, viewport_obj.maxDepth = 0, 1
        vk.vkCmdSetViewport(cb_handle, 0, 1, viewport_obj)
        scissor_obj.offset.x, scissor_obj.offset.y = data.x*sx, data.y*sy
        scissor_obj.extent.width, scissor_obj.extent.height = data.w*sx, data.h*sy
        vk.vkCmdSetScissor(cb_handle, 0, 1, scissor_obj)
        vk.vkCmdDraw(cb_handle, M.points_count, 1, 0, 0)
    end
    print("[42] Initialization Complete.")
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

local function render_node(node, x, y, w, h, gui)
    if node.type == "split" then
        if node.direction == "v" then
            local w1 = w * node.ratio
            render_node(node.children[1], x, y, w1, h, gui)
            render_node(node.children[2], x+w1, y, w-w1, h, gui)
        else
            local h1 = h * node.ratio
            render_node(node.children[1], x, y, w, h1, gui)
            render_node(node.children[2], x, y+h1, w, h - h1, gui)
        end
    else
        gui.igSetNextWindowPos(ffi.new("ImVec2_c", {x, y}), 0, ffi.new("ImVec2_c", {0, 0}))
        gui.igSetNextWindowSize(ffi.new("ImVec2_c", {w, h}), 0)
        if gui.igBegin(string.format("View %d###%d", node.id, node.id), nil, Flags.NoDecoration) then
            if gui.igIsWindowHovered(0) then state.focused_id = node.id end
            if state.fuzzy.open_trigger and state.focused_id == node.id then
                gui.igOpenPopup_Str("FuzzyFinder", 0)
                state.fuzzy.open_trigger = false
            end
            local p = M.panels[node.view_type]
            if p then p.render(gui)
            else
                gui.igText("Empty View (ID: %d)", node.id)
                gui.igText("CTRL+P: Panel Menu")
            end
        end
        gui.igEnd()
    end
end

local function render_fuzzy_finder(gui)
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {_G._WIN_LW/2, 100}), 0, ffi.new("ImVec2_c", {0.5, 0}))
    if gui.igBeginPopupModal("FuzzyFinder", nil, Flags.AlwaysAutoResize) then
        if gui.igInputText("Search", state.fuzzy.query, 128, 0, nil, nil) then
            state.fuzzy.results = {}
            local q = ffi.string(state.fuzzy.query):lower()
            for _, p in pairs(M.panels) do if p.name:lower():find(q, 1, true) then table.insert(state.fuzzy.results, p) end end
            state.fuzzy.selected_idx = 0
        end
        gui.igSetKeyboardFocusHere(-1)
        for i, p in ipairs(state.fuzzy.results) do
            if gui.igSelectable_Bool(p.name, i-1 == state.fuzzy.selected_idx, 0, ffi.new("ImVec2_c", {300, 0})) then
                replace_focused_view(p.id)
                gui.igCloseCurrentPopup()
            end
        end
        if input.key_pressed(Keys.ESC) then gui.igCloseCurrentPopup() end
        if input.key_pressed(Keys.DOWN) then state.fuzzy.selected_idx = (state.fuzzy.selected_idx + 1) % math.max(1, #state.fuzzy.results) end
        if input.key_pressed(Keys.UP) then state.fuzzy.selected_idx = (state.fuzzy.selected_idx - 1 + #state.fuzzy.results) % math.max(1, #state.fuzzy.results) end
        if input.key_pressed(Keys.ENTER) and state.fuzzy.results[state.fuzzy.selected_idx+1] then
            replace_focused_view(state.fuzzy.results[state.fuzzy.selected_idx+1].id)
            gui.igCloseCurrentPopup()
        end
        gui.igEndPopup()
    end
end

function M.update()
    -- print("[42] Frame Start") -- TRACING
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
            state.fuzzy.open_trigger = true
            ffi.fill(state.fuzzy.query, 128)
            state.fuzzy.results = {}
            for _, p in pairs(M.panels) do table.insert(state.fuzzy.results, p) end
            state.fuzzy.selected_idx = 0
        end
    end

    local gui, io = imgui.gui, imgui.gui.igGetIO_Nil()
    if input.mouse_down(3) and not io.WantCaptureMouse then 
        local rmx, rmy = input.mouse_delta()
        state.cam.orbit_x = state.cam.orbit_x + rmx * 0.2
        state.cam.orbit_y = math.max(-89, math.min(89, state.cam.orbit_y - rmy * 0.2))
    end
    
    if not state.paused then
        -- print("[42] Fetching MCAP data") -- TRACING
        if not robot.lib.mcap_next(state.bridge, state.current_msg) then 
            robot.lib.mcap_rewind(state.bridge) 
            robot.lib.mcap_next(state.bridge, state.current_msg) 
        end
        state.current_time_ns = state.current_msg.log_time
        if raw_buffer.allocation.ptr ~= nil and state.current_msg.data ~= nil then
            local copy_size = math.min(tonumber(state.current_msg.data_size), raw_buffer.size)
            ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, copy_size)
        end
    end
    
    callback_data_idx = 1
    imgui.new_frame()
    render_node(state.layout, 0, 0, _G._WIN_LW, _G._WIN_LH, gui)
    render_fuzzy_finder(gui)

    vk.vkResetCommandBuffer(cb, 0)
    vk.vkBeginCommandBuffer(cb, cb_begin_info)
    
    pc_p_obj.in_buf_idx, pc_p_obj.in_offset_u32, pc_p_obj.out_buf_idx, pc_p_obj.count = 10, 0, 11, M.points_count
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), pc_p_obj)
    vk.vkCmdDispatch(cb, math.ceil(M.points_count / 256), 1, 1)
    
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }}), 0, nil, 0, nil)
    
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ 
        sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, 
        oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, 
        newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 
        image=ffi.cast("VkImage", sw.images[img_idx]), 
        subresourceRange={ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, 
        dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT 
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    
    attachment_info_obj[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    attachment_info_obj[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
    attachment_info_obj[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    attachment_info_obj[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    attachment_info_obj[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    attachment_info_obj[0].clearValue.color.float32[0] = 0.05
    attachment_info_obj[0].clearValue.color.float32[1] = 0.05
    attachment_info_obj[0].clearValue.color.float32[2] = 0.07
    attachment_info_obj[0].clearValue.color.float32[3] = 1.0
    
    local rendering_info = ffi.new("VkRenderingInfo", { 
        sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, 
        renderArea={extent=sw.extent}, 
        layerCount=1, 
        colorAttachmentCount=1, 
        pColorAttachments=attachment_info_obj 
    })
    vk.vkCmdBeginRendering(cb, rendering_info)
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=_G._WIN_PW, height=_G._WIN_PH, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset={x=0, y=0}, extent=sw.extent }))
    imgui.render(cb)
    vk.vkCmdEndRendering(cb)
    
    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)
    
    local submit_info = ffi.new("VkSubmitInfo", { 
        sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount=1, 
        pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), 
        pWaitDstStageMask=wait_stage_mask, 
        commandBufferCount=1, 
        pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount=1, 
        pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) 
    })
    vk.vkQueueSubmit(queue, 1, submit_info, frame_fence)
    sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
