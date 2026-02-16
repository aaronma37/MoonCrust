local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local staging = require("vulkan.staging")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")

local M = {}

-- Module-level state (Persistent)
local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local image_available_sem, frame_fence
local bindless_set, cbs, submit_infos, pFenceArr
local current_time = 0

function M.init()
    print("MoonCrust: Figure-Eight Particle Attractor (1M Particles)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Particle {
            float px, py;
            float vx, vy;
        } Particle;
        typedef struct PushConstants {
            float dt;
            float time;
            uint32_t buf_id;
            uint32_t tex_id;
        } PushConstants;
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- Heaps
    local host_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))
    local host_heap = heap.new(physical_device, device, host_mem_type, 64 * 1024 * 1024)
    local device_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
    local device_heap = heap.new(physical_device, device, device_mem_type, 128 * 1024 * 1024)

    -- Buffer
    local buffer_info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = BUFFER_SIZE,
        usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, buffer_info, nil, pBuffer)
    local particle_buffer = pBuffer[0]
    local buf_alloc = device_heap:malloc(BUFFER_SIZE)
    vk.vkBindBufferMemory(device, particle_buffer, buf_alloc.memory, buf_alloc.offset)

    -- Initial Data
    local staging_engine = staging.new(physical_device, device, host_heap, BUFFER_SIZE + 1024)
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do
        initial_data[i].px = (math.random() * 2.0) - 1.0
        initial_data[i].py = (math.random() * 2.0) - 1.0
        initial_data[i].vx = 0; initial_data[i].vy = 0
    end
    staging_engine:upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- Procedural Glow Texture
    local TW, TH = 16, 16
    local tex_data = ffi.new("uint8_t[?]", TW * TH * 4)
    for y = 0, TH - 1 do
        for x = 0, TW - 1 do
            local dx = (x - (TW/2)) / (TW/2)
            local dy = (y - (TH/2)) / (TH/2)
            local dist = math.sqrt(dx*dx + dy*dy)
            local alpha = math.max(0, 1.0 - dist)
            alpha = alpha * alpha
            local idx = (y * TW + x) * 4
            tex_data[idx] = 255; tex_data[idx+1] = 255; tex_data[idx+2] = 255
            tex_data[idx+3] = math.floor(alpha * 255)
        end
    end
    local glow_image = image.create_2d(device, TW, TH, vk.VK_FORMAT_R8G8B8A8_UNORM, bit.bor(vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
    local glow_alloc = device_heap:malloc(TW * TH * 4)
    vk.vkBindImageMemory(device, glow_image, glow_alloc.memory, glow_alloc.offset)
    staging_engine:upload_image(glow_image, TW, TH, tex_data, queue, graphics_family)
    local glow_view = image.create_view(device, glow_image, vk.VK_FORMAT_R8G8B8A8_UNORM)
    local glow_sampler = image.create_sampler(device, vk.VK_FILTER_LINEAR)

    -- Bindless Setup
    local bindless_layout = descriptors.create_bindless_layout(device)
    local bindless_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bindless_pool, {bindless_layout})[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer, 0, BUFFER_SIZE, 0)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, glow_view, glow_sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)

    -- Pipeline (Note: We'll re-record per frame to update time via push constants)
    local pc_range = ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT),
        offset = 0, size = 16
    }})
    pipe_layout = pipeline.create_layout(device, {bindless_layout}, pc_range)
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/06_particles_visual/physics.comp", pipe_layout)
    local v_source = io.open("examples/06_particles_visual/render.vert"):read("*all")
    local f_source = io.open("examples/06_particles_visual/render.frag"):read("*all")
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(v_source, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(f_source, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {additive = true})

    -- Command Buffer Setup
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    submit_infos = {}
    
    -- Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pS = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sem = pS[0]
    local fence_info = ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT })
    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, fence_info, nil, pF); frame_fence = pF[0]
    pFenceArr = ffi.new("VkFence[1]", {frame_fence})

    -- We will record command buffers INSIDE the update loop to allow dynamic time
    M.cache = cache
end

function M.update()
    vk.vkWaitForFences(device, 1, pFenceArr, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, pFenceArr)
    
    current_time = current_time + 0.016
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0)
    vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local pc = ffi.new("PushConstants", { dt = 0.016, time = current_time, buf_id = 0, tex_id = 0 })
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})
    local pc_stages = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT)

    -- 1. Physics
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.cache.pipelines["physics"])
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, 16, pc)
    vk.vkCmdDispatch(cb, math.ceil(PARTICLE_COUNT / 256), 1, 1)

    -- 2. Barrier
    local barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, 0, 1, barrier, 0, nil, 0, nil)
    
    -- 3. Transition to Attachment
    local img = ffi.cast("VkImage", sw.images[img_idx])
    local view = ffi.cast("VkImageView", sw.views[img_idx])
    local img_barrier = ffi.new("VkImageMemoryBarrier[1]")
    img_barrier[0].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
    img_barrier[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    img_barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED
    img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    img_barrier[0].image = img
    img_barrier[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, img_barrier)

    -- 4. Render
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    color_attach[0].imageView = view
    color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color.float32[3] = 1.0

    local render_info = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { offset = {0, 0}, extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })
    vk.vkCmdBeginRendering(cb, render_info)
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset={0,0}, extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, 16, pc)
    vk.vkCmdDraw(cb, PARTICLE_COUNT, 1, 0, 0)
    vk.vkCmdEndRendering(cb)

    -- 5. Present Transition
    img_barrier[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, img_barrier)
    vk.vkEndCommandBuffer(cb)

    -- Submit
    local pCBs = ffi.new("VkCommandBuffer[1]", {cb})
    local pWaitSems = ffi.new("VkSemaphore[1]", {image_available_sem})
    local pWaitStages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})
    local render_finished_sem = sw.semaphores[img_idx]
    local pSignalSems = ffi.new("VkSemaphore[1]", {render_finished_sem})
    
    local submit = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = pWaitSems, pWaitDstStageMask = pWaitStages, commandBufferCount = 1, pCommandBuffers = pCBs, signalSemaphoreCount = 1, pSignalSemaphores = pSignalSems })
    vk.vkQueueSubmit(queue, 1, submit, frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
