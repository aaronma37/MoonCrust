_G.IMGUI_LIB_PATH = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local sdl = require("vulkan.sdl")
local input = require("mc.input")
local mc = require("mc")
local bit = require("bit")

local imgui = require("imgui")
_G.imgui = imgui

require("examples.42_robot_visualizer.types")
local playback = require("examples.42_robot_visualizer.playback")
local view_3d = require("examples.42_robot_visualizer.view_3d")
local panels = require("examples.42_robot_visualizer.ui.panels")
local config = require("examples.42_robot_visualizer.config")
local theme = require("examples.42_robot_visualizer.ui.theme")
local ui_consts = require("examples.42_robot_visualizer.ui.consts")
local ui_context = require("examples.42_robot_visualizer.ui.context")
local harvester = require("examples.42_robot_visualizer.ui.harvester")
local decoder = require("examples.42_robot_visualizer.decoder")
require("examples.42_robot_visualizer.ui.telemetry")
require("examples.42_robot_visualizer.ui.inspector")
require("examples.42_robot_visualizer.ui.perf")

local imgui_renderer
_G._OPEN_PICKER = function(title, items, on_select)
    local state = _G._PICKER_STATE
    state.trigger, state.title, state.items, state.results, state.selected_idx, state.on_select = true, title, items, items, 0, on_select
    ffi.fill(state.query, 128)
end

local function get_file_mtime(path)
    local f = io.popen('stat -c %Y "' .. path .. '" 2>/dev/null')
    if not f then return 0 end
    local mtime = f:read("*n"); f:close()
    return mtime or 0
end

local config_path = "examples/42_robot_visualizer/config.lua"
local state = {
    layout = config.layout, next_id = 10, last_perf = 0ULL, perf_freq = tonumber(ffi.C.SDL_GetPerformanceFrequency()), config_mtime = get_file_mtime(config_path), config_timer = 0, real_fps = 0, frame_times = {}, frame_times_idx = 1,
    picker = { trigger = false, title = "", query = ffi.new("char[128]"), selected_idx = 0, items = {}, results = {}, on_select = nil },
    file_dialog = { trigger = false, path = ffi.new("char[256]", "."), files = {}, current_dir = "." }
}
function state.refresh_files()
    local p = io.popen('ls -ap "' .. state.file_dialog.current_dir .. '"')
    state.file_dialog.files = {}
    if p then for line in p:lines() do table.insert(state.file_dialog.files, line) end; p:close() end
end
state.refresh_files()
for i=1, 60 do state.frame_times[i] = 0.0166 end 
_G._PICKER_STATE, _G._PERF_STATS = state.picker, state

local M = {}
local device, queue, graphics_family, sw, surface, pipe_parse, layout_parse, bindless_set, raw_buffers
local ui_buffers, text_buffers
local MAX_UI_ELEMENTS = 10000
local MAX_TEXT_INSTANCES = 20000
local MAX_FRAMES_IN_FLIGHT = 2
local current_frame = 0
local frame_fences = ffi.new("VkFence[2]")
local image_available_sems = ffi.new("VkSemaphore[2]")
local render_finished_sems = ffi.new("VkSemaphore[2]")
local command_buffers = ffi.new("VkCommandBuffer[2]")

local static = {
    pc_p = ffi.new("ParserPC"),
    cb_begin = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }),
    mem_barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }}),
    img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }}),
    render_info = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
    attachments = ffi.new("VkRenderingAttachmentInfo[1]"),
    submit_info = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, commandBufferCount = 1, signalSemaphoreCount = 1 }),
    wait_stages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}),
    sems_wait = ffi.new("VkSemaphore[1]"), sems_sig = ffi.new("VkSemaphore[1]"), cbs = ffi.new("VkCommandBuffer[1]"), sets = ffi.new("VkDescriptorSet[1]"), v2_pos = ffi.new("ImVec2_c"), v2_size = ffi.new("ImVec2_c"), fences = ffi.new("VkFence[1]"),
    viewport = ffi.new("VkViewport", {0, 0, 0, 0, 0, 1}),
    scissor = ffi.new("VkRect2D"),
}

local function split_focused(direction)
    local function find_and_split(node)
        if node.type == "view" then
            if node.id == panels.focused_id then
                local old, old_title = node.view_type, node.title
                node.type, node.direction, node.ratio = "split", direction, 0.5
                node.children = { { type = "view", view_type = old, id = node.id, title = old_title }, { type = "view", view_type = "perf", id = state.next_id, title = string.format("View %d###%d", state.next_id, state.next_id) } }
                state.next_id = state.next_id + 1; return true
            end
        else return find_and_split(node.children[1]) or find_and_split(node.children[2]) end
        return false
    end; find_and_split(state.layout)
end

local function render_fuzzy_picker(gui)
    static.v2_pos.x, static.v2_pos.y = _G._WIN_LW/2, 100; static.v2_size.x, static.v2_size.y = 400, 0
    gui.igSetNextWindowPos(static.v2_pos, 0, ui_consts.V2_PIVOT_TOP); gui.igSetNextWindowSize(static.v2_size, 0)
    if gui.igBeginPopupModal("FuzzyPicker", nil, bit.bor(panels.Flags.AlwaysAutoResize, panels.Flags.AlwaysOnTop)) then
        if gui.igInputText("##Search", state.picker.query, 128, 0, nil, nil) then
            state.picker.results = {}; local q = ffi.string(state.picker.query):lower()
            for _, item in ipairs(state.picker.items) do if item.name:lower():find(q, 1, true) then table.insert(state.picker.results, item) end end
            state.picker.selected_idx = 0
        end
        gui.igSetKeyboardFocusHere(-1)
        for i, item in ipairs(state.picker.results) do
            if gui.igSelectable_Bool(item.name, i-1 == state.picker.selected_idx, 0, ui_consts.V2_ZERO) then 
                pcall(state.picker.on_select, item); gui.igCloseCurrentPopup() 
            end
        end
        gui.igEndPopup()
    end
end

local function render_file_dialog(gui)
    if state.file_dialog.trigger then gui.igOpenPopup_Str("File Operations", 0); state.file_dialog.trigger = false; state.refresh_files() end
    static.v2_pos.x, static.v2_pos.y = _G._WIN_LW/2, 100; static.v2_size.x, static.v2_size.y = 500, 400
    gui.igSetNextWindowPos(static.v2_pos, 0, ui_consts.V2_PIVOT_TOP); gui.igSetNextWindowSize(static.v2_size, 0)
    if gui.igBeginPopupModal("File Operations", nil, 0) then
        gui.igText("Current Dir: " .. state.file_dialog.current_dir); gui.igSeparator()
        if gui.igBeginChild_Str("FileList", ffi.new("ImVec2_c", {0, -40}), true, 0) then
            for _, f in ipairs(state.file_dialog.files) do
                if gui.igSelectable_Bool(f, false, 0, ui_consts.V2_ZERO) then
                    if f == "../" then state.file_dialog.current_dir = state.file_dialog.current_dir:gsub("[^/]+/$", ""); if state.file_dialog.current_dir == "" then state.file_dialog.current_dir = "." end; state.refresh_files()
                    elseif f:sub(-1) == "/" then state.file_dialog.current_dir = state.file_dialog.current_dir .. "/" .. f:sub(1, -2); state.refresh_files()
                    else ffi.copy(state.file_dialog.path, state.file_dialog.current_dir .. "/" .. f) end
                end
            end
            gui.igEndChild()
        end
        gui.igInputText("Selected", state.file_dialog.path, 256, 0, nil, nil)
        if gui.igButton("Load", ui_consts.V2_BTN_SMALL) then local p = ffi.string(state.file_dialog.path); playback.load_mcap(p); _G._ACTIVE_MCAP = p:match("([^/]+)$"); gui.igCloseCurrentPopup() end
        gui.igSameLine(0, 10); if gui.igButton("Cancel", ui_consts.V2_BTN_SMALL) then gui.igCloseCurrentPopup() end
        gui.igEndPopup()
    end
end

local function render_node(node, x, y, w, h, gui, id_path)
    id_path = id_path or "root"
    if node.type == "split" then
        local ratio = node.ratio
        if node.direction == "v" then 
            local w1 = w * ratio
            if node.children[1].max_w and w1 > node.children[1].max_w then w1 = node.children[1].max_w; node.ratio = w1 / w end
            if node.children[2].max_w and (w - w1) > node.children[2].max_w then w1 = w - node.children[2].max_w; node.ratio = w1 / w end
            
            render_node(node.children[1], x, y, w1, h, gui, id_path .. "1")
            render_node(node.children[2], x+w1, y, w-w1, h, gui, id_path .. "2")
            
            local split_x = x + w1
            static.v2_pos.x, static.v2_pos.y, static.v2_size.x, static.v2_size.y = split_x - 4, y, 8, h
        else 
            local h1 = h * ratio
            if node.children[1].max_h and h1 > node.children[1].max_h then h1 = node.children[1].max_h; node.ratio = h1 / h end
            if node.children[2].max_h and (h - h1) > node.children[2].max_h then h1 = h - node.children[2].max_h; node.ratio = h1 / h end
            
            render_node(node.children[1], x, y, w, h1, gui, id_path .. "1")
            render_node(node.children[2], x, y+h1, w, h - h1, gui, id_path .. "2") 
            
            local split_y = y + h1
            static.v2_pos.x, static.v2_pos.y, static.v2_size.x, static.v2_size.y = x, split_y - 4, w, 8
        end
        
        gui.igSetNextWindowPos(static.v2_pos, 0, ui_consts.V2_ZERO); gui.igSetNextWindowSize(static.v2_size, 0)
        if gui.igBegin("split" .. id_path, nil, bit.bor(panels.Flags.NoDecoration, panels.Flags.NoSavedSettings, panels.Flags.NoBackground)) then
            local io = gui.igGetIO_Nil()
            if gui.igIsWindowFocused(0) and io.MouseDown[0] then
                local min_px = 250
                if node.direction == "v" then 
                    local target_ratio = (io.MousePos.x - x) / w
                    node.ratio = math.max(min_px / w, math.min((w - min_px) / w, target_ratio))
                else 
                    local target_ratio = (io.MousePos.y - y) / h
                    node.ratio = math.max(min_px / h, math.min((h - min_px) / h, target_ratio))
                end
            end
        end
        gui.igEnd()
    else
        static.v2_pos.x, static.v2_pos.y, static.v2_size.x, static.v2_size.y = x, y, w, h
        gui.igSetNextWindowPos(static.v2_pos, 0, ui_consts.V2_ZERO); gui.igSetNextWindowSize(static.v2_size, 0)
        local window_flags = bit.bor(1, 2, 32, 65536) -- NoTitleBar | NoResize | NoCollapse | NoSavedSettings
        if gui.igBegin(node.title, nil, window_flags) then
            if gui.igIsWindowHovered(0) then panels.focused_id = node.id end
            if state.picker.trigger and panels.focused_id == node.id then gui.igOpenPopup_Str("FuzzyPicker", 0); state.picker.trigger = false end
            render_fuzzy_picker(gui); render_file_dialog(gui)
            local vt, pms = node.view_type, nil
            if node.facet and config.facets and config.facets[node.facet] then local f = config.facets[node.facet]; vt, pms = f.panel, f.params end
            local p = panels.list[vt]
            if p then 
                local ok, err = pcall(p.render, gui, node.id, pms)
                if not ok then print("ERROR IN PANEL [" .. node.title .. "]: " .. tostring(err)) end
            end
        end
        gui.igEnd()
    end
end

function M.init()
    local instance, phys = vulkan.get_instance(), vulkan.get_physical_device()
    device, queue, graphics_family = vulkan.get_device(), vulkan.get_queue()
    sw = swapchain.new(instance, phys, device, _G._SDL_WINDOW, nil, false); surface = sw.surface
    local robot = require("mc.robot"); robot.init_bridge(); playback.init(); bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, playback.gtb.handle, 0, playback.gtb.size, 50)
    raw_buffers = { mc.buffer(view_3d.points_count * 12, "storage", nil, true), mc.buffer(view_3d.points_count * 12, "storage", nil, true) }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffers[1].handle, 0, raw_buffers[1].size, 10)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffers[2].handle, 0, raw_buffers[2].size, 12)
    
    local results_buffer = mc.buffer(1024 * 1024, "storage", nil, true) -- 1MB for parsed results
    local schema_buffer = mc.buffer(256 * 1024, "storage", nil, true)  -- 256KB for instructions
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, results_buffer.handle, 0, results_buffer.size, 14)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, schema_buffer.handle, 0, schema_buffer.size, 15)
    M.results_buffer, M.schema_buffer = results_buffer, schema_buffer
    
    _G._GPU_INSPECTOR = {
        ch = nil,
        instr_count = 0,
        flattened = nil,
        dirty = false,
        results_ptr = ffi.cast("uint32_t*", results_buffer.allocation.ptr)
    }
    
    function _G._GPU_INSPECTOR.set_channel(ch)
        if not ch or ( _G._GPU_INSPECTOR.ch and _G._GPU_INSPECTOR.ch.id == ch.id) then return end
        local raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id)
        if not raw then return end
        local schema = decoder.parse_schema(ffi.string(raw))
                local instr, count, flattened = decoder.get_gpu_instructions(schema)
        
                -- Upload instructions to GPU
                ffi.copy(M.schema_buffer.allocation.ptr, instr, count * 16)
                _G._GPU_INSPECTOR.ch = ch
                _G._GPU_INSPECTOR.instr_count = count
                _G._GPU_INSPECTOR.flattened = flattened        _G._GPU_INSPECTOR.dirty = true
        print(string.format("GPU Inspector: Monitoring %s (%d fields)", ch.topic, count))
    end
    
    ui_buffers = { mc.buffer(MAX_UI_ELEMENTS * 64, "storage", nil, true), mc.buffer(MAX_UI_ELEMENTS * 64, "storage", nil, true) }
    text_buffers = { mc.buffer(MAX_TEXT_INSTANCES * 64, "storage", nil, true), mc.buffer(MAX_TEXT_INSTANCES * 64, "storage", nil, true) }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, ui_buffers[1].handle, 0, ui_buffers[1].size, 60)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, ui_buffers[2].handle, 0, ui_buffers[2].size, 61)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, text_buffers[1].handle, 0, text_buffers[1].size, 62)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, text_buffers[2].handle, 0, text_buffers[2].size, 63)
    
    ui_context.init(ui_buffers[1].allocation.ptr, MAX_UI_ELEMENTS)
    ui_context.wrap(imgui.gui)

    view_3d.init(device, bindless_set, sw); view_3d.register_panels()
    local bl_layout = mc.gpu.get_bindless_layout()
    layout_parse = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }}))
    
    local ui_pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = 12 }})
    local layout_ui = pipeline.create_layout(device, {bl_layout}, ui_pc_range)
    local pipe_ui = pipeline.create_graphics_pipeline(device, layout_ui, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/ui.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)),
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/ui.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)),
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, alpha_blend = true, color_formats = { sw.format } }
    )
    
    local pipe_text = pipeline.create_graphics_pipeline(device, layout_ui, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/text.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)),
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/text.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)),
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, alpha_blend = true, color_formats = { sw.format } }
    )
    M.pipe_ui, M.pipe_text, M.layout_ui = pipe_ui, pipe_text, layout_ui

    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local pool = command.create_pool(device, graphics_family); local cbs_list = command.allocate_buffers(device, pool, 2)
    for i=0, 1 do
        command_buffers[i] = cbs_list[i+1]; local pF = ffi.new("VkFence[1]")
        vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fences[i] = pF[0]
        local pS = ffi.new("VkSemaphore[1]")
        vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS); image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS); render_finished_sems[i] = pS[0]
    end
    imgui.init(); imgui_renderer = require("imgui.renderer"); imgui_renderer.blur_tex_idx = 104
    imgui.add_font("examples/41_imgui_visualizer/cimgui/imgui/misc/fonts/Roboto-Medium.ttf", 18.0, false, imgui.get_glyph_ranges_default())
    local icons = require("examples.42_robot_visualizer.ui.icons")
    local icon_ranges = ffi.new("ImWchar[3]", {icons.GLYPH_MIN, icons.GLYPH_MAX, 0})
    imgui.add_font("examples/42_robot_visualizer/fa-solid-900.otf", 16.0, true, icon_ranges)
    
    imgui.add_font("examples/41_imgui_visualizer/cimgui/imgui/misc/fonts/Roboto-Medium.ttf", 14.0, false, imgui.get_glyph_ranges_default())
    imgui.add_font("examples/42_robot_visualizer/fa-solid-900.otf", 14.0, true, icon_ranges)
    imgui.build_and_upload_fonts(); theme.apply(imgui.gui); state.last_perf = ffi.C.SDL_GetPerformanceCounter(); M.header = require("examples.42_robot_visualizer.ui.header")
    
    -- GC TUNING: Low-latency incremental mode
    collectgarbage("setpause", 110)
    collectgarbage("setstepmul", 400)
    
    local ir = require("imgui.renderer")
    harvester.white_uv = ir.white_uv
    
    ui_context.init(ui_buffers[1].allocation.ptr, MAX_UI_ELEMENTS)
    ui_context.wrap(imgui.gui)

    if _ARGS then for _, arg in pairs(_ARGS) do if type(arg) == "string" then
        if arg == "--maximized" then sdl.SDL_MaximizeWindow(_G._SDL_WINDOW)
        elseif arg:find("%.mcap$") then local p = arg:gsub("^@", ""); if playback.load_mcap(p) then playback.paused = false; playback.seek_to = playback.start_time; _G._ACTIVE_MCAP = p:match("([^/]+)$") end end
    end end end
end

local function find_pms(n, config)
    if n.type == "view" then if n.facet and config.facets and config.facets[n.facet] and config.facets[n.facet].panel == "view3d" then return config.facets[n.facet].params elseif n.view_type == "view3d" then return true end
    else if n.children then return find_pms(n.children[1], config) or find_pms(n.children[2], config) end end
end

function M.update()
    local f_idx = current_frame
    static.fences[0] = frame_fences[f_idx]; vk.vkWaitForFences(device, 1, static.fences, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx, res = sw:acquire_next_image(image_available_sems[f_idx])
    if res == vk.VK_ERROR_OUT_OF_DATE_KHR or res == vk.VK_SUBOPTIMAL_KHR then
        local lw, lh = _G._WIN_LW or 0, _G._WIN_LH or 0
        if lw > 0 and lh > 0 then vk.vkDeviceWaitIdle(device); sw:cleanup(); sw = swapchain.new(vulkan.get_instance(), vulkan.get_physical_device(), device, _G._SDL_WINDOW, surface, false) end
        return
    end
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, static.fences)
    local now = ffi.C.SDL_GetPerformanceCounter(); local dt = tonumber(now - state.last_perf) / state.perf_freq; state.last_perf = now
    state.frame_times[state.frame_times_idx] = dt; state.frame_times_idx = (state.frame_times_idx % 60) + 1
    local avg_dt = 0; for i=1, 60 do avg_dt = avg_dt + (state.frame_times[i] or 0) end; if avg_dt > 0 then state.real_fps = 60.0 / avg_dt end
    
    -- INPUT & HOTKEYS
    local ctrl = input.key_down(224) or input.key_down(228)
    local shift = input.key_down(225) or input.key_down(229)
    local alt = input.key_down(226) or input.key_down(230)
    if input.key_pressed(30) then state.layout = config.layout end
    
    -- Global Data Tweaking (No click required)
    if not ctrl then
        -- POSE (No Modifiers)
        if not shift and not alt then
            if input.key_pressed(79) then playback.pose_offset = math.min(512, playback.pose_offset + 1) end -- Right
            if input.key_pressed(80) then playback.pose_offset = math.max(0, playback.pose_offset - 1) end   -- Left
            if input.key_pressed(82) then playback.pose_offset = math.min(512, playback.pose_offset + 8) end -- Up
            if input.key_pressed(81) then playback.pose_offset = math.max(0, playback.pose_offset - 8) end   -- Down
        end
        -- LIDAR OFFSET (Shift + Right/Left)
        if shift and not alt then
            if input.key_pressed(79) then playback.lidar_offset = (playback.lidar_offset or 0) + 1 end
            if input.key_pressed(80) then playback.lidar_offset = math.max(0, (playback.lidar_offset or 0) - 1) end
        end
        -- LIDAR STRIDE (Alt + Right/Left)
        if alt and not shift then
            if input.key_pressed(79) then playback.lidar_stride = (playback.lidar_stride or 12) + 1 end
            if input.key_pressed(80) then playback.lidar_stride = math.max(1, (playback.lidar_stride or 12) - 1) end
        end
    end
    
    if ctrl then
        if input.key_pressed(18) then state.file_dialog.trigger = true end -- O
        if input.key_pressed(25) then split_focused("v") end -- V
        if input.key_pressed(11) then split_focused("h") end -- H
        if input.key_pressed(19) then -- P
            local items = {}; for id, p in pairs(panels.list) do table.insert(items, { name = p.name, id = id }) end
            _G._OPEN_PICKER("Select Panel", items, function(item) 
                local function find_and_replace(node)
                    if node.type == "view" and node.id == panels.focused_id then node.view_type = item.id; return true
                    elseif node.children then return find_and_replace(node.children[1]) or find_and_replace(node.children[2]) end
                end; find_and_replace(state.layout)
            end)
        end
    end

    -- Camera Navigation
    if view_3d.is_hovered and (input.mouse_down(2) or input.mouse_down(3)) then view_3d.is_dragging = true
    elseif not (input.mouse_down(2) or input.mouse_down(3)) then view_3d.is_dragging = false end
    local can_move = view_3d.is_hovered or view_3d.is_dragging
    if input.mouse_down(3) and can_move then 
        local rmx, rmy = input.mouse_delta()
        view_3d.cam.orbit_x = view_3d.cam.orbit_x + rmx * 0.2
        view_3d.cam.orbit_y = math.max(-89, math.min(89, view_3d.cam.orbit_y - rmy * 0.2))
    end
    if input.mouse_down(2) and can_move then
        local rmx, rmy = input.mouse_delta(); local rx = mc.rad(view_3d.cam.orbit_x)
        local dx, dy, scale = -math.sin(rx), math.cos(rx), view_3d.cam.dist * 0.001
        view_3d.cam.target[0] = view_3d.cam.target[0] - dx * rmx * scale
        view_3d.cam.target[1] = view_3d.cam.target[1] - dy * rmx * scale
        view_3d.cam.target[2] = view_3d.cam.target[2] + rmy * scale
    end
    if view_3d.is_hovered then
        local wheel = _G._MOUSE_WHEEL or 0
        if wheel ~= 0 then view_3d.cam.dist = math.max(1, view_3d.cam.dist - wheel * view_3d.cam.dist * 0.1); _G._MOUSE_WHEEL = 0 end
    end

    view_3d.reset_frame()
    local win_w, win_h = _G._WIN_LW or 1280, _G._WIN_LH or 720
    
    ui_context.init(ui_buffers[f_idx + 1].allocation.ptr, MAX_UI_ELEMENTS)
    ui_context.reset()
    
    imgui.new_frame(); theme.apply(imgui.gui); M.header.draw(imgui.gui); render_node(state.layout, 0, 40, win_w, win_h - 40, imgui.gui)
    local cb = command_buffers[f_idx]; vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, static.cb_begin)
    local out_idx, pt_cnt = (f_idx == 0) and 11 or 13, playback.last_lidar_points
    local in_off, str_u, pos_off = 0, 3, 0
    
    -- Find LiDAR GTB Offset
    local lidar_gtb_off = 0
    if playback.channels_by_id and playback.lidar_ch_id then
        local ch = playback.channels_by_id[playback.lidar_ch_id]
        if ch and ch.gtb_offset then 
            local slot_idx = playback.get_gtb_slot_index(playback.lidar_ch_id)
            lidar_gtb_off = ch.gtb_offset + (slot_idx * ch.msg_size)
        end
    end

    local v3d_pms = find_pms(state.layout, config)
    if type(v3d_pms) == "boolean" then v3d_pms = nil end 
    
        if v3d_pms and v3d_pms.objects then 
        for _, o in ipairs(v3d_pms.objects) do 
            if o.type == "lidar" and o.topic == playback.lidar_topic then 
                if playback.channels then
                    for _, ch in ipairs(playback.channels) do
                        if ch.topic == o.topic then playback.lidar_ch_id = ch.id end
                    end
                end
            end 
            if o.type == "robot" and o.pose_topic then
                if playback.channels then
                    for _, ch in ipairs(playback.channels) do
                        if ch.topic == o.pose_topic then playback.pose_ch_id = ch.id end
                    end
                end
            end
        end 
    end
    
    playback.update(dt, nil); view_3d.update_robot_buffer(f_idx, v3d_pms)
    
    -- Initialize Lidar tweaking state from config if not yet set
    if not playback._lidar_configured and v3d_pms and v3d_pms.objects then
        for _, o in ipairs(v3d_pms.objects) do
            if o.type == "lidar" and o.topic == playback.lidar_topic then
                playback.lidar_stride = o.stride or 12
                playback.lidar_offset = o.header_skip or 0
                playback._lidar_configured = true
                break
            end
        end
    end

    local final_in_off = playback.lidar_offset or 0
    local final_stride = playback.lidar_stride or 12
    local final_pos_off = 0

    static.pc_p.in_buf_idx, static.pc_p.in_offset_bytes, static.pc_p.out_buf_idx, static.pc_p.count = 50, lidar_gtb_off + final_in_off, out_idx, pt_cnt
    static.pc_p.mode = 0
    static.pc_p.instr_buf_idx = 0
    static.pc_p.in_stride_bytes = final_stride
    static.pc_p.in_pos_offset_bytes = final_pos_off
    
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse); static.sets[0] = bindless_set
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_parse, 0, 1, static.sets, 0, nil) 
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, static.sets, 0, nil)
    vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, static.pc_p)
    if pt_cnt > 0 then vk.vkCmdDispatch(cb, math.ceil(pt_cnt / 256), 1, 1) end

    -- UNIVERSAL TELEMETRY PARSING (GPU-Native)
    if _G._GPU_INSPECTOR.ch then
        local ch = _G._GPU_INSPECTOR.ch
        local gtb_off = 0
        if playback.channels_by_id[ch.id] then
            local p_ch = playback.channels_by_id[ch.id]
            if p_ch.gtb_offset then
                local slot_idx = playback.get_gtb_slot_index(ch.id)
                gtb_off = p_ch.gtb_offset + (slot_idx * playback.MSG_SIZE_MAX)
            end
        end
        
        static.pc_p.in_buf_idx = 50
        static.pc_p.in_offset_bytes = gtb_off
        static.pc_p.out_buf_idx = 14 -- results_buffer
        static.pc_p.count = _G._GPU_INSPECTOR.instr_count
        static.pc_p.mode = 1 -- Universal Telemetry Mode
        static.pc_p.instr_buf_idx = 15 -- schema_buffer
        
        vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), static.pc_p)
        if _G._GPU_INSPECTOR.instr_count > 0 then
            vk.vkCmdDispatch(cb, 1, 1, 1)
        end
    end

    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, static.mem_barrier, 0, nil, 0, nil)
    view_3d.render_deferred(cb, out_idx, f_idx, pt_cnt)
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout, static.img_barrier[0].image, static.img_barrier[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, ffi.cast("VkImage", sw.images[img_idx]), vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier[0].srcAccessMask = 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier)
    static.attachments[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
    static.attachments[0].clearValue.color.float32[0], static.attachments[0].clearValue.color.float32[1], static.attachments[0].clearValue.color.float32[2] = 0.02, 0.02, 0.03
    static.render_info.renderArea.extent = sw.extent; static.render_info.pColorAttachments = static.attachments
    vk.vkCmdBeginRendering(cb, static.render_info)
    
    imgui.gui.igRender()
    local draw_data = imgui.gui.igGetDrawData()
    local text_count = 0
    if draw_data ~= nil then
        text_count = harvester.harvest_text(draw_data, text_buffers[f_idx + 1])
    end
    state.last_text_count = text_count
    
    local ui_pc = ffi.new("struct { uint32_t idx; uint32_t pad; float screen[2]; }", { 60 + f_idx, 0, {tonumber(win_w), tonumber(win_h)} })
    
    static.viewport.width, static.viewport.height = win_w, win_h
    vk.vkCmdSetViewport(cb, 0, 1, static.viewport)
    static.scissor.extent.width, static.scissor.extent.height = win_w, win_h
    static.scissor.offset.x, static.scissor.offset.y = 0, 0
    vk.vkCmdSetScissor(cb, 0, 1, static.scissor)

    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_ui)
    static.sets[0] = bindless_set; vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.layout_ui, 0, 1, static.sets, 0, nil)
    vk.vkCmdPushConstants(cb, M.layout_ui, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 16, ui_pc)
    if ui_context.count > 0 then vk.vkCmdDraw(cb, 4, ui_context.count, 0, 0) end
    
    local text_pc = ffi.new("struct { uint32_t idx; uint32_t pad; float screen[2]; }", { 62 + f_idx, 0, {tonumber(win_w), tonumber(win_h)} })
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_text)
    vk.vkCmdPushConstants(cb, M.layout_ui, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 16, text_pc)
    if text_count > 0 then vk.vkCmdDraw(cb, 4, text_count, 0, 0) end
    
    vk.vkCmdEndRendering(cb)
    
    -- HEARTBEAT MONITOR: Track health after frame completion
    state.heartbeat_timer = (state.heartbeat_timer or 0) + dt
    if state.heartbeat_timer > 5.0 then
        print(string.format("[HEARTBEAT] Mem: %.2f MB | UI: %d | Text: %d | FPS: %.1f", 
            collectgarbage("count") / 1024, ui_context.count, state.last_text_count or 0, state.real_fps or 0))
        state.heartbeat_timer = 0
    end

    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    static.img_barrier[0].srcAccessMask, static.img_barrier[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier); vk.vkEndCommandBuffer(cb)
    local sem_finished = render_finished_sems[f_idx]
    static.sems_wait[0], static.sems_sig[0], static.cbs[0] = image_available_sems[f_idx], sem_finished, cb
    static.submit_info.pWaitSemaphores, static.submit_info.pWaitDstStageMask, static.submit_info.pCommandBuffers, static.submit_info.pSignalSemaphores = static.sems_wait, static.wait_stages, static.cbs, static.sems_sig
    vk.vkQueueSubmit(queue, 1, static.submit_info, frame_fences[f_idx])
    sw:present(queue, img_idx, sem_finished); current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

if jit then
    jit.off(M.update)
end

return M
