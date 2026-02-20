local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local bit = require("bit")

local M = { angle = 0 }

-- CONFIG: 1 MILLION OBJECTS
local INSTANCE_COUNT = 1024 * 1024
local device, queue, graphics_family, sw, graph
local pipe_cull, pipe_render, layout_graph, bindless_set
local instance_buf, draw_buf, culled_buf
local image_available, cb, frame_fence

function M.init()
    print("Example 20: GPU-DRIVEN CULLING (1 Million Objects)")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct Instance { float x, y, z, scale; float r, g, b, radius; } Instance;
        typedef struct DrawCommand { uint32_t vertexCount, instanceCount, firstVertex, firstInstance; } DrawCommand;
        typedef struct PushConstants {
            float mvp[16];
            uint32_t instanceCount, instanceBuf, drawBuf, culledBuf;
        } PushConstants;
    ]]

    -- 1. Create Instance Data
    local instances = ffi.new("Instance[?]", INSTANCE_COUNT)
    for i = 0, INSTANCE_COUNT - 1 do
        local r, theta = math.sqrt(math.random()) * 100.0, math.random() * 6.28
        instances[i].x, instances[i].y, instances[i].z = r * math.cos(theta), (math.random()-0.5)*5.0, r * math.sin(theta)
        instances[i].scale = 0.1 + math.random() * 0.2
        instances[i].r, instances[i].g, instances[i].b = 0.2 + math.random()*0.8, 0.2 + math.random()*0.8, 0.2 + math.random()*0.8
        instances[i].radius = instances[i].scale * 1.732
    end
    instance_buf = mc.buffer(ffi.sizeof(instances), "storage", instances)

    -- 2. Create Indirect Draw Buffer
    local initial_draw = ffi.new("DrawCommand", { vertexCount = 36, instanceCount = 0, firstVertex = 0, firstInstance = 0 })
    draw_buf = mc.buffer(ffi.sizeof("DrawCommand"), "indirect", initial_draw)

    -- 3. Create Culled ID Buffer
    culled_buf = mc.buffer(ffi.sizeof("uint32_t") * INSTANCE_COUNT, "storage")

    -- 4. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, instance_buf.handle, 0, instance_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, draw_buf.handle, 0, draw_buf.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, culled_buf.handle, 0, culled_buf.size, 2)

    -- 5. Pipelines
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), offset = 0, size = ffi.sizeof("PushConstants") }}))
    pipe_cull = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/20_gpu_culling/cull.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/20_gpu_culling/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/20_gpu_culling/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { depth_test = true, depth_write = true, depth_format = vk.VK_FORMAT_D32_SFLOAT })

    -- 6. Sync
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    
    M.angle = M.angle + 0.005
    local view = mc.mat4_look_at({ math.cos(M.angle)*50, 20, math.sin(M.angle)*50 }, {0,0,0}, {0,1,0})
    local proj = mc.mat4_perspective(mc.rad(45), sw.extent.width/sw.extent.height, 0.1, 1000.0)
    local mvp = mc.mat4_multiply(proj, view)
    
    local pc = ffi.new("PushConstants"); for i=1,16 do pc.mvp[i-1] = mvp.m[i-1] end
    pc.instanceCount, pc.instanceBuf, pc.drawBuf, pc.culledBuf = INSTANCE_COUNT, 0, 1, 2

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- PASS 1: Clear Indirect Count
    vk.vkCmdFillBuffer(cb, draw_buf.handle, 4, 4, 0) -- Reset instanceCount to 0
    local b1 = ffi.new("VkBufferMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, buffer=draw_buf.handle, size=draw_buf.size }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, b1, 0, nil)

    -- PASS 2: Cull
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_cull)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("PushConstants"), pc)
    vk.vkCmdDispatch(cb, math.ceil(INSTANCE_COUNT / 256), 1, 1)

    -- Barrier: Compute -> Indirect/Vertex
    local b2 = ffi.new("VkBufferMemoryBarrier[2]", {
        { sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, buffer=draw_buf.handle, size=draw_buf.size },
        { sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_SHADER_READ_BIT, buffer=culled_buf.handle, size=culled_buf.size }
    })
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, bit.bor(vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT), 0, 0, nil, 2, b2, 0, nil)

    -- PASS 3: Render
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.05, 0.05, 0.07, 1.0 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("PushConstants"), pc)
    
    -- MAGIC: Indirect Draw
    mc.gpu.draw_indirect(cb, draw_buf.handle, 0, 1, 16)
    
    vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
