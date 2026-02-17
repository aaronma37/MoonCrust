local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local render_graph = require("vulkan.graph")
local resource = require("vulkan.resource")
local sdl = require("vulkan.sdl")

local M = { frame_count = 0, current_time = 0 }

local device, queue, graphics_family, sw, pipe_layout, pipe_trace, pipe_render
local bindless_set, cbs, image_available_sem, frame_fence
local accum_img, accum_view, accum_sampler

function M.init()
    print("Example 12: CINEMATIC PATH TRACER")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    resource.init(device)

    ffi.cdef[[
        typedef struct TracePC { uint32_t out_img, frame_count; float time; uint32_t moving; } TracePC;
        typedef struct RenderPC { uint32_t img_idx, p1, p2, p3; } RenderPC;
    ]]

    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 256 * 1024 * 1024)

    accum_img = image.create_2d(device, sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, bit.bor(vk.VK_IMAGE_USAGE_STORAGE_BIT, vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
    local ialloc = device_heap:malloc(sw.extent.width * sw.extent.height * 16)
    vk.vkBindImageMemory(device, accum_img, ialloc.memory, ialloc.offset)
    accum_view = image.create_view(device, accum_img, vk.VK_FORMAT_R32G32B32A32_SFLOAT)
    accum_sampler = image.create_sampler(device, vk.VK_FILTER_LINEAR)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, accum_view, accum_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, accum_view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 16 }}))
    pipe_trace = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/12_path_tracer/path_trace.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/12_path_tracer/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/12_path_tracer/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]

    local setup_cb = command.allocate_buffers(device, pool, 1)[1]
    command.begin_one_time(setup_cb)
    local bar = ffi.new("VkImageMemoryBarrier", { sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_GENERAL, image=accum_img, subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_TRANSFER_WRITE_BIT })
    vk.vkCmdPipelineBarrier(setup_cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {bar}))
    vk.vkCmdClearColorImage(setup_cb, accum_img, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, ffi.new("VkClearColorValue"), 1, ffi.new("VkImageSubresourceRange[1]", {{aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}}))
    bar.oldLayout, bar.newLayout, bar.srcAccessMask, bar.dstAccessMask = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.VK_IMAGE_LAYOUT_GENERAL, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT
    vk.vkCmdPipelineBarrier(setup_cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {bar}))
    command.end_and_submit(setup_cb, queue, device)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    M.current_time = M.current_time + 0.016
    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- Cinematic Pass: Always treat as moving for now to keep it clean
    -- Or we can just use a high frame count only when static.
    local is_moving = 0 -- STOP MOVEMENT FOR CLARITY
    if is_moving == 1 then M.frame_count = 0 end

    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_trace)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 16, ffi.new("TracePC", { 0, M.frame_count, M.current_time, is_moving }))
    vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)

    local mem_bar = ffi.new("VkMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=vk.VK_ACCESS_SHADER_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 1, mem_bar, 0, nil, 0, nil)

    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 4, ffi.new("uint32_t[1]", {0}))
    vk.vkCmdDraw(cb, 3, 1, 0, 0)
    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence)
    sw:present(queue, img_idx, sw.semaphores[img_idx])
    M.frame_count = M.frame_count + 1
end

return M
