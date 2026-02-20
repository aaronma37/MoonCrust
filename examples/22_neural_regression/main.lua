local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local bit = require("bit")

local M = { current_time = 0 }

-- MLP CONFIG: 2 -> 32 -> 3
local HIDDEN_SIZE = 32
-- W1: 2x32 (64), B1: 32, W2: 32x3 (96), B2: 3. Total: 195
local WEIGHT_COUNT = 64 + 32 + 96 + 3
local device, queue, graphics_family, sw
local pipe_train, pipe_render, layout_graph, bindless_set
local weight_buf, image_available, cb, cb_pool, frame_fence

function M.init()
    print("Example 22: NEURAL REGRESSION (Nuclear Option: Tanh + Clipping)")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct PushConstants {
            uint32_t weightBuf, targetImg;
            float lr, time;
            float resX, resY;
            float pad1, pad2;
        } PushConstants;
    ]]

    -- Xavier Initialization
    local weights = ffi.new("float[?]", WEIGHT_COUNT)
    for i = 0, WEIGHT_COUNT - 1 do
        local scale = (i < 96) and math.sqrt(1.0/2.0) or math.sqrt(1.0/HIDDEN_SIZE)
        weights[i] = (math.random() - 0.5) * 2.0 * scale
    end
    weight_buf = mc.buffer(ffi.sizeof(weights), "storage", weights)

    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, weight_buf.handle, 0, weight_buf.size, 0)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 32 }}))
    pipe_train = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/22_neural_regression/mlp.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/22_neural_regression/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/22_neural_regression/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { cull_mode = vk.VK_CULL_MODE_NONE })

    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    cb_pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, cb_pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    
    M.current_time = M.current_time + 0.016
    -- Very low learning rate due to massive batch size (65k threads)
    local pc = ffi.new("PushConstants", { weightBuf = 0, targetImg = 0, lr = 0.000005, time = M.current_time, resX = sw.extent.width, resY = sw.extent.height })

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_train)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    for i=1, 8 do
        pc.time = M.current_time + (i * 0.007)
        vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 32, pc)
        vk.vkCmdDispatch(cb, 256, 1, 1) 
        local b = ffi.new("VkBufferMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer=weight_buf.handle, size=weight_buf.size }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, b, 0, nil)
    end

    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0, 0, 0, 1 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 32, pc)
    vk.vkCmdDraw(cb, 3, 1, 0, 0); vk.vkCmdEndRendering(cb)
    
    local bar_pres = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = 0, srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar_pres)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
