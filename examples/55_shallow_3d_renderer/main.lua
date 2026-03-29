local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")
local graph = require("vulkan.graph")
local input = require("mc.input")

local M = { 
    current_time = 0,
    cam_pos = {32, 0, 32},
    cam_yaw = 0,
    grid_res = 128,
    move_mode = 1 -- 1: World, 2: Screen-Relative, 3: Inverted, 4: Swapped
}

local device, queue, graphics_family, sw, rg
local vol_a, vol_b, dirty_buf, v_buf, indirect_buf, index_buf, depth_img
local pipe_sim, pipe_mesh, pipe_render, pipe_gen, render_layout
local bindless_set, image_available_sem, frame_fence, cbs
local res_vol_a, res_vol_b, res_dirty, res_v_buf, res_indirect, res_depth

function M.init()
    print("Example 54: 3D GPU CA MESHER")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    rg = graph.new(device)

    -- 1. Resources
    vol_a = mc.gpu.image_3d(M.grid_res, M.grid_res, M.grid_res, vk.VK_FORMAT_R32_UINT, "storage sampled")
    vol_b = mc.gpu.image_3d(M.grid_res, M.grid_res, M.grid_res, vk.VK_FORMAT_R32_UINT, "storage sampled")
    
    local num_chunks = (M.grid_res/16)^3
    dirty_buf = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    v_buf = mc.gpu.buffer(num_chunks * 98304 * 4, "storage", nil, false)
    indirect_buf = mc.gpu.buffer(num_chunks * 20, "indirect", nil, true)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    
    local indices_per_chunk = 24576 * 6
    local index_data = ffi.new("uint16_t[?]", indices_per_chunk)
    for i=0, 24576-1 do
        local b = i * 4
        local o = i * 6
        index_data[o+0], index_data[o+1], index_data[o+2] = b+0, b+1, b+2
        index_data[o+3], index_data[o+4], index_data[o+5] = b+0, b+2, b+3
    end
    index_buf = mc.gpu.buffer(indices_per_chunk * 2, "index", index_data, false)

    -- Register with Graph
    res_vol_a = rg:register_resource("vol_a", graph.TYPE_IMAGE, vol_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_vol_b = rg:register_resource("vol_b", graph.TYPE_IMAGE, vol_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_dirty = rg:register_resource("dirty", graph.TYPE_BUFFER, dirty_buf.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    res_v_buf = rg:register_resource("v_buf", graph.TYPE_BUFFER, v_buf.handle)
    res_indirect = rg:register_resource("indirect", graph.TYPE_BUFFER, indirect_buf.handle)
    res_depth = rg:register_resource("depth", graph.TYPE_IMAGE, depth_img.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED, access = 0, stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT })

    -- 2. Bindless Updates
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, vol_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, vol_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 1)
    
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, dirty_buf.handle, 0, dirty_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, v_buf.handle, 0, v_buf.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, indirect_buf.handle, 0, indirect_buf.size, 2)

    ffi.cdef[[ typedef struct RenderPC { float mvp[16]; uint32_t v_buf_off; } RenderPC; ]]

    -- 3. Pipelines
    pipe_sim = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/sim.comp", 16)
    pipe_mesh = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/mesh.comp", 20)
    pipe_gen = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gen.comp", 12)
    
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = 68 }})
    render_layout = pipeline.create_layout(device, {bl_layout}, pc_ranges)
    local v_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_render = pipeline.create_graphics_pipeline(device, render_layout, v_mod, f_mod, { depth_test = true, cull_mode = vk.VK_CULL_MODE_BACK_BIT })

    -- 4. Initialization
    local pool = command.create_pool(device, graphics_family)
    local gcb = command.allocate_buffers(device, pool, 1)[1]
    command.begin_one_time(gcb)
    local vol_bar = ffi.new("VkImageMemoryBarrier[2]")
    for i=0,1 do
        vol_bar[i].sType, vol_bar[i].oldLayout, vol_bar[i].newLayout, vol_bar[i].image = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL, (i == 0) and vol_a.handle or vol_b.handle
        vol_bar[i].srcAccessMask, vol_bar[i].dstAccessMask = 0, vk.VK_ACCESS_SHADER_WRITE_BIT
        vol_bar[i].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    end
    vk.vkCmdPipelineBarrier(gcb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 2, vol_bar)
    vk.vkCmdFillBuffer(gcb, dirty_buf.handle, 0, dirty_buf.size, 1)
    vk.vkCmdFillBuffer(gcb, v_buf.handle, 0, v_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, indirect_buf.handle, 0, indirect_buf.size, 0)
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen.handle)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(gcb, pipe_gen.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 12, ffi.new("uint32_t[3]", {0, M.grid_res, 123}))
    vk.vkCmdDispatch(gcb, M.grid_res/16, M.grid_res/16, M.grid_res)
    vk.vkEndCommandBuffer(gcb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {gcb}) }), nil)
    vk.vkQueueWaitIdle(queue)
    vk.vkDestroyCommandPool(device, pool, nil)

    -- 5. Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool2 = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool2, sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
end

local frame_count = 0
function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    frame_count = frame_count + 1
    M.current_time = M.current_time + 0.016
    
    if frame_count % 60 == 0 then
        local ptr = ffi.cast("uint32_t*", indirect_buf.allocation.ptr)
        local total_indices = 0
        local num_chunks = (M.grid_res/16)^3
        for i=0, num_chunks-1 do total_indices = total_indices + ptr[i*5] end
        print(string.format("FPS: 60 | Mode: %d | Cam: %.1f, %.1f, %.1f | Total Indices: %d", M.move_mode, M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], total_indices))
    end
    
    if input.key_down(input.SCANCODE_1) then M.move_mode = 1 end
    if input.key_down(input.SCANCODE_2) then M.move_mode = 2 end
    if input.key_down(input.SCANCODE_3) then M.move_mode = 3 end
    if input.key_down(input.SCANCODE_4) then M.move_mode = 4 end

    local cam_speed = 0.5
    local dx, dz = 0, 0
    if input.key_down(input.SCANCODE_W) then dz = dz - 1 end
    if input.key_down(input.SCANCODE_S) then dz = dz + 1 end
    if input.key_down(input.SCANCODE_A) then dx = dx - 1 end
    if input.key_down(input.SCANCODE_D) then dx = dx + 1 end

    if M.move_mode == 1 then
        M.cam_pos[1] = M.cam_pos[1] + dx * cam_speed
        M.cam_pos[3] = M.cam_pos[3] + dz * cam_speed
    elseif M.move_mode == 2 then
        M.cam_pos[1] = M.cam_pos[1] + (dx - dz) * cam_speed * 0.707
        M.cam_pos[3] = M.cam_pos[3] + (-dx - dz) * cam_speed * 0.707
    elseif M.move_mode == 3 then
        M.cam_pos[1] = M.cam_pos[1] + (-dx + dz) * cam_speed * 0.707
        M.cam_pos[3] = M.cam_pos[3] + (dx + dz) * cam_speed * 0.707
    elseif M.move_mode == 4 then
        M.cam_pos[1] = M.cam_pos[1] + dz * cam_speed
        M.cam_pos[3] = M.cam_pos[3] + dx * cam_speed
    end

    local aspect = sw.extent.width / sw.extent.height
    local proj = mc.mat4_perspective(mc.rad(60), aspect, 0.1, 1000.0)
    -- Camera at (x+100, 100, z+100) looking at (x, 0, z)
    local eye = {M.cam_pos[1] + 100, 100, M.cam_pos[3] + 100}
    local target = {M.cam_pos[1], 0, M.cam_pos[3]}
    local view = mc.mat4_look_at(eye, target, {0,1,0})
    local mvp = mc.mat4_multiply(proj, view)

    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    rg:reset()
    
    local vol_in_res = (frame_count % 2 == 1) and res_vol_a or res_vol_b
    local vol_out_res = (frame_count % 2 == 1) and res_vol_b or res_vol_a
    local vol_in_idx = (frame_count % 2 == 1) and 0 or 1
    local vol_out_idx = (frame_count % 2 == 1) and 1 or 0

    rg:add_pass("Mesher", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mesh.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mesh.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(cb, pipe_mesh.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 20, ffi.new("uint32_t[5]", {vol_in_idx, 0, 1, 2, M.grid_res}))
        vk.vkCmdDispatch(cb, M.grid_res/16, M.grid_res/16, M.grid_res/16)
    end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(res_dirty, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_v_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_indirect, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    local chunks = (M.grid_res/16)^3
    rg:add_pass("Render", function(cb)
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
        local color_attach, depth_attach = ffi.new("VkRenderingAttachmentInfo[1]"), ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05, 0.05, 0.1, 1.0}
        depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout, depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", depth_img.view), vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {depth=1, stencil=0}
        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, render_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local pc = ffi.new("RenderPC"); for i=1,16 do pc.mvp[i-1] = mvp.m[i-1] end; pc.v_buf_off = 1
        vk.vkCmdPushConstants(cb, render_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 68, pc)
        vk.vkCmdBindIndexBuffer(cb, index_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexedIndirect(cb, indirect_buf.handle, 0, chunks, 20)
        vk.vkCmdEndRendering(cb)
        bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    end):using(res_v_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(res_indirect, vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT)
       :using(res_depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    rg:execute(cb)
    vk.vkEndCommandBuffer(cb)
    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
