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
local render_graph = require("vulkan.graph")

local M = {}

-- Persistent State
local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local image_available_sem, frame_fence
local bindless_set, cbs, pFenceArr
local graph, g_pBuffer, g_swImages = {}, {}, {}
local depth_img, depth_view, depth_format, g_depthBuffer
local current_time = 0

function M.init()
    print("MoonCrust: 1M Particles - 3D UPGRADE")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Particle { float px, py, pz, p1; float vx, vy, vz, p2; } Particle;
        typedef struct PushConstants { float dt, time; uint32_t buf_id, tex_id; } PushConstants;
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- Depth Buffer
    depth_format = image.find_depth_format(physical_device)
    depth_img = image.create_2d(device, sw.extent.width, sw.extent.height, depth_format, vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT)
    
    -- Heaps
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 128 * 1024 * 1024)
    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 256 * 1024 * 1024)

    local d_alloc = device_heap:malloc(sw.extent.width * sw.extent.height * 4) -- Estimate for depth
    vk.vkBindImageMemory(device, depth_img, d_alloc.memory, d_alloc.offset)
    depth_view = image.create_view(device, depth_img, depth_format, vk.VK_IMAGE_ASPECT_DEPTH_BIT)

    -- Particle Buffer
    local buffer_info = ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = BUFFER_SIZE, usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) })
    local pBuffer = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, buffer_info, nil, pBuffer); local particle_buffer = pBuffer[0]
    local buf_alloc = device_heap:malloc(BUFFER_SIZE); vk.vkBindBufferMemory(device, particle_buffer, buf_alloc.memory, buf_alloc.offset)

    -- Staging
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do 
        initial_data[i].px = (math.random()*2)-1; initial_data[i].py = (math.random()*2)-1; initial_data[i].pz = (math.random()*2)-1 
    end
    staging.new(physical_device, device, host_heap, BUFFER_SIZE + 1024):upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- Texture
    local TW, TH = 16, 16
    local tex_data = ffi.new("uint8_t[?]", TW * TH * 4)
    for y = 0, TH - 1 do for x = 0, TW - 1 do 
        local dist = math.sqrt(((x-8)/8)^2 + ((y-8)/8)^2)
        local idx = (y*TW+x)*4; tex_data[idx]=255; tex_data[idx+1]=255; tex_data[idx+2]=255; tex_data[idx+3]=math.floor(math.max(0,1-dist)^2 * 255)
    end end
    local glow_img = image.create_2d(device, TW, TH, vk.VK_FORMAT_R8G8B8_UNORM, bit.bor(vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT)) -- Reduced format size
    local glow_alloc = device_heap:malloc(TW*TH*4); vk.vkBindImageMemory(device, glow_img, glow_alloc.memory, glow_alloc.offset)
    staging.new(physical_device, device, host_heap, TW*TH*4):upload_image(glow_img, TW, TH, tex_data, queue, graphics_family)
    local glow_view = image.create_view(device, glow_img, vk.VK_FORMAT_R8G8B8_UNORM)
    local glow_samp = image.create_sampler(device, vk.VK_FILTER_LINEAR)

    -- Bindless
    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer, 0, BUFFER_SIZE, 0)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, glow_view, glow_samp, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)

    -- Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 16 }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/06_particles_visual/physics.comp", pipe_layout)
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/06_particles_visual/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/06_particles_visual/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        additive = true,
        depth_test = true,
        depth_write = true,
        depth_format = depth_format
    })

    -- Render Graph
    graph = render_graph.new(device)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer)
    g_depthBuffer = graph:register_resource("DepthBuffer", render_graph.TYPE_IMAGE, depth_img)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SwapchainImage_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    -- Sync
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]; pFenceArr = ffi.new("VkFence[1]", {frame_fence})
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available_sem = pS[0]
    
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), sw.image_count)
    M.cache = cache
end

function M.update()
    vk.vkWaitForFences(device, 1, pFenceArr, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, pFenceArr)
    current_time = current_time + 0.016
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local pc = ffi.new("PushConstants", { dt = 0.016, time = current_time, buf_id = 0, tex_id = 0 })
    local stages = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT)

    graph:reset()
    graph:add_pass("Physics", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.cache.pipelines["physics"])
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, stages, 0, 16, pc)
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32[3] = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0

        local depth_attach = ffi.new("VkRenderingAttachmentInfo", {
            sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
            imageView = depth_view,
            imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
            storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
            clearValue = { depthStencil = { depth = 1.0, stencil = 0 } }
        })

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach, pDepthAttachment = depth_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, stages, 0, 16, pc)
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
       :using(g_depthBuffer, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
