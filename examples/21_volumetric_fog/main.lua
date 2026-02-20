local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local bit = require("bit")

local M = { current_time = 0, angle = 0 }

local device, queue, graphics_family, sw
local pipe_fog, pipe_render, layout_graph, bindless_set
local fog_3d, image_available, cb, cb_pool, frame_fence

function M.init()
    print("Example 21: VOLUMETRIC FOG (3D Textures - using mc.gpu StdLib)")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct PushConstants {
            float mvp[16];      // 64 bytes
            float camX, camY, camZ, pad0; // 16 bytes
            float l1x, l1y, l1z, l1i;     // 16 bytes
            float l2x, l2y, l2z, l2i;     // 16 bytes
            float time;                   // 4 bytes
            uint32_t grid_id;             // 4 bytes
            float pad1, pad2;             // 8 bytes (Total 128)
        } PushConstants;
    ]]

    -- 1. Create 3D Image (64x64x64)
    fog_3d = mc.gpu.image_3d(64, 64, 64, vk.VK_FORMAT_R8G8B8A8_UNORM, "storage")

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    local sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)
    descriptors.update_storage_image_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, fog_3d.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, fog_3d.view, sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, fog_3d.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    -- 3. Pipelines (Size 128 matches the FFI struct)
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 128 }}))
    pipe_fog = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/21_volumetric_fog/fog.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/21_volumetric_fog/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/21_volumetric_fog/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { cull_mode = vk.VK_CULL_MODE_NONE })

    -- 4. Sync
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    cb_pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, cb_pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]

    -- Transition Image once
    local setup_cb = command.allocate_buffers(device, cb_pool, 1)[1]
    vk.vkBeginCommandBuffer(setup_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    local bar = ffi.new("VkImageMemoryBarrier", { sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_GENERAL, image=fog_3d.handle, subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT })
    vk.vkCmdPipelineBarrier(setup_cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {bar}))
    vk.vkEndCommandBuffer(setup_cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {setup_cb}) }), nil)
    vk.vkQueueWaitIdle(queue)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    
    -- UPDATE TIME AND ANGLE
    M.current_time = M.current_time + 0.016
    M.angle = M.angle + 0.005

    local camPos = { math.cos(M.angle)*15, 5, math.sin(M.angle)*15 }
    local view = mc.mat4_look_at(camPos, {0,2,0}, {0,1,0})
    local proj = mc.mat4_perspective(mc.rad(45), sw.extent.width/sw.extent.height, 0.1, 100.0)
    local invViewProj = mc.mat4_inverse(mc.mat4_multiply(proj, view))
    
    local pc = ffi.new("PushConstants"); for i=1,16 do pc.mvp[i-1] = invViewProj.m[i-1] end
    pc.camX, pc.camY, pc.camZ = camPos[1], camPos[2], camPos[3]
    
    -- Animate flickering lights
    pc.l1x, pc.l1y, pc.l1z = math.sin(M.current_time * 1.2) * 6.0, 3.0 + math.cos(M.current_time * 0.8) * 2.0, math.cos(M.current_time * 1.2) * 6.0
    pc.l1i = 1.5 + math.sin(M.current_time * 15.0) * 0.5 
    
    pc.l2x, pc.l2y, pc.l2z = math.sin(M.current_time * 0.7 + 3.14) * 5.0, 4.0 + math.sin(M.current_time * 1.5) * 1.5, math.cos(M.current_time * 0.7 + 3.14) * 5.0
    pc.l2i = 1.2 + math.cos(M.current_time * 12.0) * 0.4
    
    pc.time, pc.grid_id = M.current_time, 0

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- PASS 1: Generate Fog
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_fog)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 128, pc)
    vk.vkCmdDispatch(cb, 8, 8, 8)

    local bar1 = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_SHADER_READ_BIT, oldLayout=vk.VK_IMAGE_LAYOUT_GENERAL, newLayout=vk.VK_IMAGE_LAYOUT_GENERAL, image=fog_3d.handle, subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1} }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, bar1)

    -- PASS 2: Render
    local bar2 = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar2)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.1, 0.1, 0.15, 1.0 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 128, pc)
    vk.vkCmdDraw(cb, 3, 1, 0, 0); vk.vkCmdEndRendering(cb)
    
    local bar3 = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = 0, srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar3)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
