local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local command = require("vulkan.command")
local input = require("mc.input")
local sdl = require("vulkan.sdl")
local bit = require("bit")

local M = { 
    cam_pos = {64, 35, 64}, -- Start in the center of the terrain
    cam_yaw = 0,
    current_time = 0
}

local device, queue, sw, pipe_layout, pipe_render, pipe_gen, pipe_blit
local bindless_set, cb, frame_fence, image_available
local world_buf, accum_img

function M.init()
    print("Example 28: ROBUST GPU VOXEL WORLD")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); local q, family = vulkan.get_queue(); queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    -- 1. Create Voxel Buffer (128x64x128 floats)
    local world_size = 128 * 64 * 128 * 4
    world_buf = mc.buffer(world_size, "storage", nil, false)
    accum_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")

    -- 2. Bindless
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    local sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, world_buf.handle, 0, world_size, 0)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, accum_img.view, sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, accum_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    -- 3. Pipelines
    ffi.cdef[[
        typedef struct VoxelPC {
            uint32_t out_img, world_buf;
            float time;
            uint32_t grid_res;
            float cam_x, cam_y, cam_z, cam_yaw;
        } VoxelPC;
    ]]

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = 0x7FFFFFFF, offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)

    pipe_gen = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/28_voxel_world/world.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/28_voxel_world/render.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local v_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/25_voxel_atrium/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/25_voxel_atrium/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_blit = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST })

    -- 4. Sync
    local pool = command.create_pool(device, family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); image_available = image_available[0]

    -- 5. INITIAL GEN
    local gcb = command.allocate_buffers(device, pool, 1)[1]
    vk.vkBeginCommandBuffer(gcb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(gcb, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, ffi.new("VoxelPC", { 0, 0, 0, 128, 0, 0, 0, 0 }))
    vk.vkCmdDispatch(gcb, 16, 8, 16)
    vk.vkEndCommandBuffer(gcb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {gcb}) }), nil)
    vk.vkQueueWaitIdle(queue)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available)
    if idx == nil then return end
    
    input.tick(); M.current_time = M.current_time + 0.016
    if input.key_down(input.SCANCODE_W) then 
        M.cam_pos[1] = M.cam_pos[1] + math.sin(M.cam_yaw) * 0.5
        M.cam_pos[3] = M.cam_pos[3] + math.cos(M.cam_yaw) * 0.5
    end
    if input.key_down(input.SCANCODE_S) then 
        M.cam_pos[1] = M.cam_pos[1] - math.sin(M.cam_yaw) * 0.5
        M.cam_pos[3] = M.cam_pos[3] - math.cos(M.cam_yaw) * 0.5
    end
    if input.key_down(input.SCANCODE_A) then M.cam_yaw = M.cam_yaw + 0.03 end
    if input.key_down(input.SCANCODE_D) then M.cam_yaw = M.cam_yaw - 0.03 end

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- Voxel Render (Compute)
    local pc = ffi.new("VoxelPC", { 0, 0, M.current_time, 128, M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], M.cam_yaw })
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, 32, pc)
    vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)

    -- Transition and Blit
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_blit)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, 4, ffi.new("uint32_t[1]", {0}))
    vk.vkCmdDraw(cb, 3, 1, 0, 0); vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
