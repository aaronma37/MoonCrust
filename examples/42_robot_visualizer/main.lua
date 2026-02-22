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

    bool igSliderFloat(const char* label, float* v, float v_min, float v_max, const char* format, int flags);
    bool igCheckbox(const char* label, bool* v);
]]

local state = {
    mcap_path = "test_robot.mcap",
    points_count = 10000, 
    paused = false,
    plot_pos = { x = 0, y = 0 },
    plot_size = { x = 1, y = 1 },
    current_msg = ffi.new("McapMessage"),
    bridge = nil,
    
    -- Timeline state
    start_time = 0ULL,
    end_time = 0ULL,
    current_time_ns = 0ULL,
    
    -- Camera state
    cam = {
        orbit_x = 45,
        orbit_y = 45,
        dist = 50,
        target = {0, 0, 5}
    },

    -- Topic state
    channels = {},
}

local M = state

local device, queue, graphics_family, sw
local pipe_layout, pipe_parse, pipe_render
local bindless_set, image_available_sem, frame_fence, cb
local raw_buffer, point_buffer

-- PRE-ALLOCATED FFI OBJECTS
local pc_p_obj = ffi.new("ParserPC")
local pc_r_obj = ffi.new("RenderPC")
local progress_ptr = ffi.new("float[1]")
local p_open_dummy = ffi.new("bool[1]", true)
local p_fence_wait = ffi.new("VkFence[1]")
local viewport_obj = ffi.new("VkViewport")
local scissor_obj = ffi.new("VkRect2D")
local rendering_info_obj = ffi.new("VkRenderingInfo")
local attachment_info_obj = ffi.new("VkRenderingAttachmentInfo[1]")
local submit_info_obj = ffi.new("VkSubmitInfo")
local cb_begin_info = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO })
local wait_stage_mask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})

local function discover_topics()
    local count = robot.lib.mcap_get_channel_count(state.bridge)
    state.channels = {}
    local info = ffi.new("McapChannelInfo")
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(state.bridge, i, info) then
            table.insert(state.channels, {
                id = info.id,
                topic = ffi.string(info.topic),
                encoding = ffi.string(info.message_encoding),
                schema = ffi.string(info.schema_name),
                active = true
            })
        end
    end
end

function M.init()
    print("Example 42: THE ROBOT PILOT (MCAP + Compute-Driven Rendering)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    
    robot.init_bridge()
    imgui.init()

    local f = io.open(state.mcap_path, "r")
    if not f then
        robot.lib.mcap_generate_test_file(state.mcap_path)
    else
        f:close()
    end

    state.bridge = robot.lib.mcap_open(state.mcap_path)
    if state.bridge == nil then error("Failed to open " .. state.mcap_path) end
    
    state.start_time = robot.lib.mcap_get_start_time(state.bridge)
    state.end_time = robot.lib.mcap_get_end_time(state.bridge)
    state.current_time_ns = state.start_time

    discover_topics()

    -- 1. Buffers
    raw_buffer = mc.buffer(M.points_count * 12, "storage", nil, true)
    point_buffer = mc.buffer(M.points_count * 16, "storage", nil, false)
    
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, raw_buffer.handle, 0, raw_buffer.size, 10)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, point_buffer.handle, 0, point_buffer.size, 11)
    
    -- 2. Pipelines
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_parse_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("ParserPC") }})
    local layout_parse = pipeline.create_layout(device, {bl_layout}, pc_parse_range)
    pipe_parse = pipeline.create_compute_pipeline(device, layout_parse, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/parser.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local pc_render_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_render_range)
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST,
        alpha_blend = true,
        color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB }
    })

    -- 3. Sync
    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sem = pS[0]

    -- 4. Setup Callback Hijack
    imgui.on_callback = function(cb_handle, callback_ptr, data_ptr)
        local pos = state.plot_pos
        local size = state.plot_size
        local aspect = size.x / size.y
        local proj = mc.mat4_perspective(mc.rad(45), aspect, 0.1, 1000.0)
        local rx = mc.rad(state.cam.orbit_x)
        local ry = mc.rad(state.cam.orbit_y)
        local cp = {
            state.cam.target[1] + state.cam.dist * math.cos(ry) * math.cos(rx),
            state.cam.target[2] + state.cam.dist * math.cos(ry) * math.sin(rx),
            state.cam.target[3] + state.cam.dist * math.sin(ry)
        }
        local view = mc.mat4_look_at(cp, state.cam.target, {0,0,1})
        local mvp = mc.mat4_multiply(proj, view)
        
        for i=0,15 do pc_r_obj.view_proj[i] = mvp.m[i] end
        pc_r_obj.buf_idx = 11
        pc_r_obj.point_size = 3.0
        
        vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdPushConstants(cb_handle, pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), pc_r_obj)
        
        local scale_x = _G._WIN_PW / _G._WIN_LW
        local scale_y = _G._WIN_PH / _G._WIN_LH
        
        viewport_obj.x, viewport_obj.y, viewport_obj.width, viewport_obj.height = pos.x * scale_x, pos.y * scale_y, size.x * scale_x, size.y * scale_y
        viewport_obj.minDepth, viewport_obj.maxDepth = 0, 1
        vk.vkCmdSetViewport(cb_handle, 0, 1, viewport_obj)
        
        scissor_obj.offset.x, scissor_obj.offset.y = pos.x * scale_x, pos.y * scale_y
        scissor_obj.extent.width, scissor_obj.extent.height = size.x * scale_x, size.y * scale_y
        vk.vkCmdSetScissor(cb_handle, 0, 1, scissor_obj)
        
        vk.vkCmdDraw(cb_handle, M.points_count, 1, 0, 0)
    end
end

function M.update()
    p_fence_wait[0] = frame_fence
    vk.vkWaitForFences(device, 1, p_fence_wait, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, p_fence_wait)
    
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    local gui = imgui.gui
    local io = gui.igGetIO_Nil()

    local mx, my = input.mouse_pos()
    local rmx, rmy = input.mouse_delta()
    if input.mouse_down(3) and not io.WantCaptureMouse then 
        state.cam.orbit_x = state.cam.orbit_x + rmx * 0.2
        state.cam.orbit_y = math.max(-89, math.min(89, state.cam.orbit_y - rmy * 0.2))
    end

    if not state.paused then
        if not robot.lib.mcap_next(state.bridge, state.current_msg) then
            robot.lib.mcap_rewind(state.bridge)
            robot.lib.mcap_next(state.bridge, state.current_msg)
        end
        state.current_time_ns = state.current_msg.log_time
        ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, state.current_msg.data_size)
    end

    local lw, lh = _G._WIN_LW, _G._WIN_LH
    local pw, ph = _G._WIN_PW, _G._WIN_PH

    imgui.new_frame()
    
    if gui.igBegin("Robot Telemetry", nil, 0) then
        gui.igText("Points: %d", M.points_count)
        
        if gui.igButton(M.paused and "Resume" or "Pause", ffi.new("ImVec2_c", {0, 0})) then
            M.paused = not M.paused
        end
        
        local progress = 0
        if state.end_time > state.start_time then
            progress = tonumber(state.current_time_ns - state.start_time) / tonumber(state.end_time - state.start_time)
        end
        
        progress_ptr[0] = progress
        if gui.igSliderFloat("Timeline", progress_ptr, 0.0, 1.0, "%.2f", 0) then
            state.paused = true
            local seek_ns = state.start_time + ffi.cast("uint64_t", progress_ptr[0] * tonumber(state.end_time - state.start_time))
            robot.lib.mcap_seek(state.bridge, seek_ns)
            if robot.lib.mcap_next(state.bridge, state.current_msg) then
                state.current_time_ns = state.current_msg.log_time
                ffi.copy(raw_buffer.allocation.ptr, state.current_msg.data, state.current_msg.data_size)
            end
        end

        gui.igSeparator()
        gui.igText("Topic Explorer")
        for _, ch in ipairs(state.channels) do
            local active_ptr = ffi.new("bool[1]", ch.active)
            if gui.igCheckbox(ch.topic, active_ptr) then
                ch.active = active_ptr[0]
            end
            if gui.igIsItemHovered(0) then
                gui.igBeginTooltip()
                gui.igText("Encoding: %s", ch.encoding)
                gui.igText("Schema: %s", ch.schema)
                gui.igEndTooltip()
            end
        end

        if gui.ImPlot_BeginPlot("Lidar Cloud", ffi.new("ImVec2_c", {-1, -1}), 8) then
            local p = gui.ImPlot_GetPlotPos()
            local s = gui.ImPlot_GetPlotSize()
            state.plot_pos.x, state.plot_pos.y = p.x, p.y
            state.plot_size.x, state.plot_size.y = s.x, s.y
            gui.ImDrawList_AddCallback(gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), nil, 0) 
            gui.ImPlot_EndPlot()
        end
        gui.igEnd()
    end

    vk.vkResetCommandBuffer(cb, 0)
    vk.vkBeginCommandBuffer(cb, cb_begin_info)
    
    pc_p_obj.in_buf_idx, pc_p_obj.in_offset_u32, pc_p_obj.out_buf_idx, pc_p_obj.count = 10, 0, 11, M.points_count
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_parse)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_parse, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, layout_parse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ParserPC"), pc_p_obj)
    vk.vkCmdDispatch(cb, math.ceil(M.points_count / 256), 1, 1)
    
    local mem_bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, mem_bar, 0, nil, 0, nil)

    local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange=range, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
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
    
    rendering_info_obj.sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO
    rendering_info_obj.renderArea = {extent = sw.extent}
    rendering_info_obj.layerCount = 1
    rendering_info_obj.colorAttachmentCount = 1
    rendering_info_obj.pColorAttachments = attachment_info_obj
    
    vk.vkCmdBeginRendering(cb, rendering_info_obj)
    
    viewport_obj.x, viewport_obj.y, viewport_obj.width, viewport_obj.height = 0, 0, pw, ph
    vk.vkCmdSetViewport(cb, 0, 1, viewport_obj)
    scissor_obj.offset.x, scissor_obj.offset.y = 0, 0
    scissor_obj.extent.width, scissor_obj.extent.height = pw, ph
    vk.vkCmdSetScissor(cb, 0, 1, scissor_obj)
    
    imgui.render(cb)
    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    local render_finished_sem = sw.semaphores[img_idx]
    local render_finished_sem_arr = ffi.new("VkSemaphore[1]", {render_finished_sem})
    local cb_arr = ffi.new("VkCommandBuffer[1]", {cb})
    local image_available_sem_arr = ffi.new("VkSemaphore[1]", {image_available_sem})

    submit_info_obj.sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO
    submit_info_obj.pNext = nil
    submit_info_obj.waitSemaphoreCount = 1
    submit_info_obj.pWaitSemaphores = image_available_sem_arr
    submit_info_obj.pWaitDstStageMask = wait_stage_mask
    submit_info_obj.commandBufferCount = 1
    submit_info_obj.pCommandBuffers = cb_arr
    submit_info_obj.signalSemaphoreCount = 1
    submit_info_obj.pSignalSemaphores = render_finished_sem_arr
    
    vk.vkQueueSubmit(queue, 1, submit_info_obj, frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
