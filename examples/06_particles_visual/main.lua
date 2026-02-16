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

local M = {}

-- Module-level state (Persistent)
local PARTICLE_COUNT = 1024 * 1024 -- Back to 1M!
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local image_available_sem, frame_fence
local bindless_set, cbs, submit_infos, pFenceArr

function M.init()
    print("Example 06: Visual 1M Particle Simulation - BINDLESS REVOLUTION")
    
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
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- Heaps
    local host_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))
    local host_heap = heap.new(physical_device, device, host_mem_type, 32 * 1024 * 1024)
    local device_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
    local device_heap = heap.new(physical_device, device, device_mem_type, 64 * 1024 * 1024)

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
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do
        initial_data[i].px = 0.0; initial_data[i].py = 0.0
        local angle = math.random() * math.pi * 2
        local speed = math.random() * 0.5
        initial_data[i].vx = math.cos(angle) * speed
        initial_data[i].vy = math.sin(angle) * speed
    end
    local staging_engine = staging.new(physical_device, device, host_heap, BUFFER_SIZE)
    staging_engine:upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- BINDLESS SETUP
    local bindless_layout = descriptors.create_bindless_layout(device)
    local bindless_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bindless_pool, {bindless_layout})[1]
    
    -- Register buffer at index 0
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer, 0, BUFFER_SIZE, 0)

    -- Pipeline with Push Constants for indexing
    local pc_range = ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT),
        offset = 0, size = 8 -- float dt + uint index
    }})
    pipe_layout = pipeline.create_layout(device, {bindless_layout}, pc_range)
    
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/06_particles_visual/physics.comp", pipe_layout)
    
    local v_source = io.open("examples/06_particles_visual/render.vert"):read("*all")
    local f_source = io.open("examples/06_particles_visual/render.frag"):read("*all")
    local v_spirv = shader.compile_glsl(v_source, vk.VK_SHADER_STAGE_VERTEX_BIT)
    local f_spirv = shader.compile_glsl(f_source, vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    local v_mod = shader.create_module(device, v_spirv)
    local f_mod = shader.create_module(device, f_spirv)
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod)

    -- Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local fence_info = ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT })
    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, fence_info, nil, pF); frame_fence = pF[0]
    pFenceArr = ffi.new("VkFence[1]", {frame_fence})

    -- Pre-record Command Buffers
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    submit_infos = {}
    local pWaitSems = ffi.new("VkSemaphore[1]", {image_available_sem})
    local pWaitStages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})

    for i=0, sw.image_count-1 do
        local cb = cbs[i+1]
        local img = ffi.cast("VkImage", sw.images[i])
        local view = ffi.cast("VkImageView", sw.views[i])
        
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = 0 }))

        -- 1. Physics (Bindless)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, cache.pipelines["physics"])
        local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        
        local pc_data = ffi.new("struct { float dt; uint32_t id; }", { 0.016, 0 })
        vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), 0, 8, pc_data)
        vk.vkCmdDispatch(cb, math.ceil(PARTICLE_COUNT / 256), 1, 1)

        -- 2. Barrier
        local barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, 0, 1, barrier, 0, nil, 0, nil)

        -- 3. Transition Image
        local img_barrier = ffi.new("VkImageMemoryBarrier[1]")
        img_barrier[0].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
        img_barrier[0].srcAccessMask = 0
        img_barrier[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        img_barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED
        img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        img_barrier[0].image = img
        img_barrier[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, img_barrier)

        -- 4. Render (Bindless)
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
        
        -- Same push constants for vertex shader buffer index
        vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), 0, 8, pc_data)
        
        vk.vkCmdDraw(cb, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(cb)

        -- 5. Transition to Present
        img_barrier[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        img_barrier[0].dstAccessMask = 0
        img_barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, img_barrier)

        vk.vkEndCommandBuffer(cb)

        -- Anchored SubmitInfo
        local pCBs_anchored = ffi.new("VkCommandBuffer[1]", {cb})
        local pSignalSems_anchored = ffi.new("VkSemaphore[1]", {sw.semaphores[i]})
        local sub = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = pWaitSems, pWaitDstStageMask = pWaitStages, commandBufferCount = 1, pCommandBuffers = pCBs_anchored, signalSemaphoreCount = 1, pSignalSemaphores = pSignalSems_anchored })
        submit_infos[i+1] = { info = sub, pCBs = pCBs_anchored, pSignalSems = pSignalSems_anchored }
    end

    print("Bindless example initialized.")
end

function M.update()
    vk.vkWaitForFences(device, 1, pFenceArr, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, pFenceArr)
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    local submission = submit_infos[img_idx+1]
    vk.vkQueueSubmit(queue, 1, submission.info, frame_fence)
    sw:present(queue, img_idx, submission.pSignalSems[0])
end

return M
