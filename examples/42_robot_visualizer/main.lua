local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local input = require("mc.input")
local mc = require("mc")
local bit = require("bit")

_G.IMGUI_LIB_PATH = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local imgui = require("imgui")

-- Load FFI types (now that imgui has defined core types)
require("examples.42_robot_visualizer.types")

-- Load modular components
local playback = require("examples.42_robot_visualizer.playback")
local view_3d = require("examples.42_robot_visualizer.view_3d")
local panels = require("examples.42_robot_visualizer.ui.panels")
require("examples.42_robot_visualizer.ui.telemetry")
require("examples.42_robot_visualizer.ui.inspector")
require("examples.42_robot_visualizer.ui.perf")

local imgui_renderer

-- Global helper for panels to trigger topic picker
_G._OPEN_PICKER = function(title, items, on_select)
    local state = _G._PICKER_STATE
    state.trigger, state.title, state.items, state.results, state.selected_idx, state.on_select = true, title, items, items, 0, on_select
    ffi.fill(state.query, 128)
end

local function create_default_layout()
    return { 
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
    }
end

local function create_full_3d_layout()
    return { type = "view", view_type = "view3d", id = 1, title = "3D Lidar###1" }
end

local state = {
    layout = create_default_layout(),
    next_id = 5,
    last_ticks = 0ULL,
    picker = { trigger = false, title = "", query = ffi.new("char[128]"), selected_idx = 0, items = {}, results = {}, on_select = nil }
}
_G._PICKER_STATE = state.picker

local M = {}
local device, queue, graphics_family, sw, cb
local pipe_parse, layout_parse, bindless_set, image_available_sem, frame_fence, raw_buffer

local static = {
    pc_p = ffi.new("ParserPC"),
    cb_begin = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }),
    mem_barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }}),
    img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }}),
    render_info = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
    attachments = ffi.new("VkRenderingAttachmentInfo[1]"),
    submit_info = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, commandBufferCount = 1, signalSemaphoreCount = 1 }),
    wait_stages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}),
}

-- Layout split/close logic (unchanged)
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

function M.init()
    local instance, phys = vulkan.get_instance(), vulkan.get_physical_device()
    device, queue, graphics_family = vulkan.get_device(), vulkan.get_queue()
    sw = swapchain.new(instance, phys, device, _G._SDL_WINDOW)
    
    local robot = require("mc.robot")
    robot.init_bridge()
    
    playback.init()
    bindless_set = mc.gpu.get_bindless_set()
    
    raw_buffer = mc.buffer(view_3d.points_count * 12, "storage", nil, true)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffer.handle, 0, raw_buffer.size, 10)
    
    view_3d.init(device, bindless_set, sw)
    view_3d.register_panels()
    
    local bl_layout = mc.gpu.get_bindless_layout()
    layout_parse = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }}))
    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS); image_available_sem = pS[0]

    imgui.init(); imgui_renderer = require("imgui.renderer")
    imgui.on_callback = function(cb_handle, callback_ptr, data_ptr)
        view_3d.on_callback(cb_handle, data_ptr, imgui_renderer)
    end
    
    state.last_ticks = ffi.C.SDL_GetTicks()
end

local function render_fuzzy_picker(gui)
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {_G._WIN_LW/2, 100}), 0, ffi.new("ImVec2_c", {0.5, 0}))
    gui.igSetNextWindowSize(ffi.new("ImVec2_c", {400, 0}), 0)
    if gui.igBeginPopupModal("FuzzyPicker", nil, bit.bor(panels.Flags.AlwaysAutoResize, panels.Flags.AlwaysOnTop)) then
        if gui.igInputText("##Search", state.picker.query, 128, 0, nil, nil) then
            state.picker.results = {}; local q = ffi.string(state.picker.query):lower()
            for _, item in ipairs(state.picker.items) do if item.name:lower():find(q, 1, true) then table.insert(state.picker.results, item) end end
            state.picker.selected_idx = 0
        end
        gui.igSetKeyboardFocusHere(-1)
        for i, item in ipairs(state.picker.results) do
            if gui.igSelectable_Bool(item.name, i-1 == state.picker.selected_idx, 0, ffi.new("ImVec2_c", {0,0})) then 
                local ok, err = pcall(state.picker.on_select, item)
                if not ok then print("Picker Error:", err) end
                gui.igCloseCurrentPopup() 
            end
        end
        if input.key_pressed(41) then gui.igCloseCurrentPopup() end -- ESC
        if input.key_pressed(81) then state.picker.selected_idx = (state.picker.selected_idx + 1) % #state.picker.results end -- DOWN
        if input.key_pressed(82) then state.picker.selected_idx = (state.picker.selected_idx - 1 + #state.picker.results) % #state.picker.results end -- UP
        if input.key_pressed(40) and state.picker.results[state.picker.selected_idx+1] then state.picker.on_select(state.picker.results[state.picker.selected_idx+1]); gui.igCloseCurrentPopup() end
        gui.igEndPopup()
    end
end

local function render_node(node, x, y, w, h, gui)
    -- print(string.format("Node: %s, x=%.1f, y=%.1f, w=%.1f, h=%.1f", node.type, x, y, w, h))
    if node.type == "split" then
        if node.direction == "v" then local w1 = w * node.ratio; render_node(node.children[1], x, y, w1, h, gui); render_node(node.children[2], x+w1, y, w-w1, h, gui)
        else local h1 = h * node.ratio; render_node(node.children[1], x, y, w, h1, gui); render_node(node.children[2], x, y+h1, w, h - h1, gui) end
    else
        gui.igSetNextWindowPos(ffi.new("ImVec2_c", {x, y}), 0, ffi.new("ImVec2_c", {0,0}))
        gui.igSetNextWindowSize(ffi.new("ImVec2_c", {w, h}), 0)
        local visible = gui.igBegin(node.title, nil, bit.bor(panels.Flags.NoDecoration, panels.Flags.NoSavedSettings))
        -- print(string.format("View '%s' (ID %d) Visible: %s", node.title, node.id, tostring(visible)))
        if visible then
            if gui.igIsWindowHovered(0) then panels.focused_id = node.id end
            if state.picker.trigger and panels.focused_id == node.id then gui.igOpenPopup_Str("FuzzyPicker", 0); state.picker.trigger = false end
            render_fuzzy_picker(gui)
            local p = panels.list[node.view_type]
            if p then 
                local ok, err = pcall(p.render, gui, node.id) 
                if not ok then gui.igTextColored(ffi.new("ImVec4_c", {1,0,0,1}), "Render Error: %s", tostring(err)) end
            end
        end; gui.igEnd()
    end
end

function M.update()
    static.fences = ffi.new("VkFence[1]", {frame_fence})
    vk.vkWaitForFences(device, 1, static.fences, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, static.fences)
    local img_idx = sw:acquire_next_image(image_available_sem); if img_idx == nil then return end
    
    local ticks = ffi.C.SDL_GetTicks()
    local dt = tonumber(ticks - state.last_ticks) / 1000.0
    state.last_ticks = ticks

    view_3d.reset_frame()
    collectgarbage("step", 100)
    
    -- Input Debug
    local ctrl = input.key_down(224) or input.key_down(228)
    if input.key_pressed(30) then -- 1
        -- print("Key 1 Pressed! Ctrl:", ctrl)
        state.layout = create_default_layout()
    end
    if input.key_pressed(31) then -- 2
        -- print("Key 2 Pressed! Ctrl:", ctrl)
        state.layout = create_full_3d_layout() 
    end
    if input.key_pressed(32) then -- 3
        -- print("Key 3 Pressed! Ctrl:", ctrl)
        state.layout = { 
            type = "split", direction = "h", ratio = 0.5,
            children = {
                { type = "view", view_type = "pretty_viewer", id = 2, title = "Message Inspector###2" },
                { type = "view", view_type = "telemetry", id = 4, title = "Playback Controls###4" }
            }
        }
    end

    if ctrl then
        if input.key_pressed(25) then split_focused("v") end -- V
        if input.key_pressed(11) then split_focused("h") end -- H
        if input.key_pressed(27) then -- X
            local function find_and_close(node, parent)
                if node.type == "view" then
                    if node.id == panels.focused_id and parent then
                        local other = (parent.children[1] == node) and parent.children[2] or parent.children[1]
                        for k,v in pairs(other) do parent[k] = v end; return true
                    end
                else return find_and_close(node.children[1], node) or find_and_close(node.children[2], node) end
                return false
            end; find_and_close(state.layout, nil)
        end
        if input.key_pressed(19) then -- P
            local items = {}; for id, p in pairs(panels.list) do table.insert(items, { name = p.name, id = id }) end
            _G._OPEN_PICKER("Select Panel", items, function(item) 
                local function find_and_replace(node)
                    if node.type == "view" then
                        if node.id == panels.focused_id then node.view_type = item.id; return true end
                    else return find_and_replace(node.children[1]) or find_and_replace(node.children[2]) end
                    return false
                end; find_and_replace(state.layout)
            end)
        end
    end

    playback.update(dt, raw_buffer)
    view_3d.update_robot_buffer()

    -- Camera navigation
    local gui, io = imgui.gui, imgui.gui.igGetIO_Nil()
    if input.mouse_down(3) and not io.WantCaptureMouse then 
        local rmx, rmy = input.mouse_delta()
        view_3d.cam.orbit_x = view_3d.cam.orbit_x + rmx * 0.2
        view_3d.cam.orbit_y = math.max(-89, math.min(89, view_3d.cam.orbit_y - rmy * 0.2))
    end
    if input.mouse_down(2) and not io.WantCaptureMouse then
        local rmx, rmy = input.mouse_delta()
        local rx = mc.rad(view_3d.cam.orbit_x)
        local right_x, right_y = -math.sin(rx), math.cos(rx)
        local scale = view_3d.cam.dist * 0.001
        view_3d.cam.target[1] = view_3d.cam.target[1] - right_x * rmx * scale
        view_3d.cam.target[2] = view_3d.cam.target[2] - right_y * rmx * scale
        view_3d.cam.target[3] = view_3d.cam.target[3] + rmy * scale
    else
        view_3d.cam.target[1] = playback.robot_pose.x
        view_3d.cam.target[2] = playback.robot_pose.y
        view_3d.cam.target[3] = playback.robot_pose.z + 0.5
    end
    if not io.WantCaptureMouse then
        local wheel = _G._MOUSE_WHEEL or 0
        if wheel ~= 0 then view_3d.cam.dist = math.max(1, view_3d.cam.dist - wheel * view_3d.cam.dist * 0.1); _G._MOUSE_WHEEL = 0 end
    end

    local win_w, win_h = _G._WIN_LW or 1280, _G._WIN_LH or 720
    imgui.new_frame(); render_node(state.layout, 0, 0, win_w, win_h, gui)
    
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, static.cb_begin)
    static.pc_p.in_buf_idx, static.pc_p.in_offset_u32, static.pc_p.out_buf_idx, static.pc_p.count = 10, 0, 11, view_3d.points_count
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse); static.sets = ffi.new("VkDescriptorSet[1]", {bindless_set}); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, static.sets, 0, nil); vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), static.pc_p); vk.vkCmdDispatch(cb, math.ceil(view_3d.points_count / 256), 1, 1)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, static.mem_barrier, 0, nil, 0, nil)
    
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout, static.img_barrier[0].image, static.img_barrier[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, ffi.cast("VkImage", sw.images[img_idx]), vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier[0].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier)
    
    static.img_barrier[0].image = view_3d.depth_image.handle
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL
    static.img_barrier[0].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT
    static.img_barrier[0].dstAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier)

    static.attachments[0].sType, static.attachments[0].imageView, static.attachments[0].imageLayout, static.attachments[0].loadOp, static.attachments[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    static.attachments[0].clearValue.color.float32[0], static.attachments[0].clearValue.color.float32[1], static.attachments[0].clearValue.color.float32[2], static.attachments[0].clearValue.color.float32[3] = 0.05, 0.05, 0.07, 1.0
    static.render_info.renderArea.extent = sw.extent; static.render_info.pColorAttachments = static.attachments; static.render_info.pDepthAttachment = view_3d.depth_attach
    vk.vkCmdBeginRendering(cb, static.render_info)
    imgui.render(cb); vk.vkCmdEndRendering(cb)
    
    static.img_barrier[0].image = ffi.cast("VkImage", sw.images[img_idx])
    static.img_barrier[0].oldLayout, static.img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    static.img_barrier[0].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier); vk.vkEndCommandBuffer(cb)
    
    static.sems_wait = ffi.new("VkSemaphore[1]", {image_available_sem})
    static.sems_sig = ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]})
    static.cbs = ffi.new("VkCommandBuffer[1]", {cb})
    static.submit_info.pWaitSemaphores, static.submit_info.pWaitDstStageMask, static.submit_info.pCommandBuffers, static.submit_info.pSignalSemaphores = static.sems_wait, static.wait_stages, static.cbs, static.sems_sig
    vk.vkQueueSubmit(queue, 1, static.submit_info, frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
