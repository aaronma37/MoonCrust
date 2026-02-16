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
local resource = require("vulkan.resource")

local M = {}

-- STABLE INTERACTIVE MODE (Static Commands)
local PARTICLE_COUNT = 1024 * 1024 -- 1M back on!
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local image_available_sem, frame_fence
local bindless_set, cbs, pFenceArr
local graph, g_pBuffer, g_swImages = {}, {}, {}
local current_time = 0

function M.init()
    print("Example 07: STABLE INTERACTIVE 1M Particles")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    
    -- Initialize Death Row
    resource.init(device)

    ffi.cdef[[
        typedef struct Particle { float px, py, pz, p1; float vx, vy, vz, p2; } Particle;
        typedef struct AttractorData {
            float time;
            float mouse_x;
            float mouse_y;
            uint32_t mouse_down;
        } AttractorData;
        typedef struct PushConstants { 
            float dt;
            uint32_t buf_id;
            uint32_t attr_id;
            uint32_t tex_id; 
        } PushConstants;
    ]]
    
    -- Heaps
    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 256 * 1024 * 1024)
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 128 * 1024 * 1024)

    -- 1. Particle Buffer (1M)
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = BUFFER_SIZE, usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) }), nil, pBuffer)
    local particle_buffer = pBuffer[0]
    local buf_alloc = device_heap:malloc(BUFFER_SIZE); vk.vkBindBufferMemory(device, particle_buffer, buf_alloc.memory, buf_alloc.offset)

    -- 2. Attractor Buffer (Host Visible for instant updates!)
    local attr_info = ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = ffi.sizeof("AttractorData"), usage = vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT })
    local pAttr = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, attr_info, nil, pAttr); local attractor_buffer = pAttr[0]
    local attr_alloc = host_heap:malloc(ffi.sizeof("AttractorData")) -- Map to CPU memory
    vk.vkBindBufferMemory(device, attractor_buffer, attr_alloc.memory, attr_alloc.offset)
    M.attr_ptr = ffi.cast("AttractorData*", attr_alloc.ptr)

    -- Staging Initial
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do initial_data[i].px = (math.random()*2)-1; initial_data[i].py = (math.random()*2)-1; initial_data[i].pz = (math.random()*2)-1 end
    staging.new(physical_device, device, host_heap, BUFFER_SIZE + 1024):upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- Texture
    local TW, TH = 16, 16
    local tex_data = ffi.new("uint8_t[?]", TW * TH * 4)
    for y = 0, TH - 1 do for x = 0, TW - 1 do 
        local dist = math.sqrt(((x-8)/8)^2 + ((y-8)/8)^2)
        local idx = (y*TW+x)*4; tex_data[idx]=255; tex_data[idx+1]=255; tex_data[idx+2]=255; tex_data[idx+3]=math.floor(math.max(0,1-dist)^2 * 255)
    end end
    local glow_img = image.create_2d(device, TW, TH, vk.VK_FORMAT_R8G8B8_UNORM, bit.bor(vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
    local glow_alloc = device_heap:malloc(TW*TH*4); vk.vkBindImageMemory(device, glow_img, glow_alloc.memory, glow_alloc.offset)
    staging.new(physical_device, device, host_heap, TW*TH*4):upload_image(glow_img, TW, TH, tex_data, queue, graphics_family)
    local glow_view = image.create_view(device, glow_img, vk.VK_FORMAT_R8G8B8_UNORM)
    local glow_samp = image.create_sampler(device, vk.VK_FILTER_LINEAR)

    -- Bindless Setup
    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer, 0, BUFFER_SIZE, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, attractor_buffer, 0, ffi.sizeof("AttractorData"), 1) -- Index 1
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, glow_view, glow_samp, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)

    -- Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), offset = 0, size = 16 }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/07_interactive_particles/physics.comp", pipe_layout)
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/07_interactive_particles/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/07_interactive_particles/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { additive = true })

    -- Render Graph (STATIC PRE-RECORD)
    graph = render_graph.new(device)
    local res_pBuf = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer)
    local res_attr = graph:register_resource("AttrBuffer", render_graph.TYPE_BUFFER, attractor_buffer)
    
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    
    local pc = ffi.new("PushConstants", { dt = 0.016, buf_id = 0, attr_id = 1, tex_id = 0 })
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})

    for i=0, sw.image_count-1 do
        local cb = cbs[i+1]
        local sw_res = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i])
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        
        graph:reset()
        graph:add_pass("Physics", function(c)
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, cache.pipelines["physics"])
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
            vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), 0, 16, pc)
            vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
        end):using(res_pBuf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(res_attr, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

        graph:add_pass("Render", function(c)
            local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
            color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[i]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
            color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32[3] = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
            vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
            vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
            vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
            vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), 0, 16, pc)
            vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
            vk.vkCmdEndRendering(c)
        end):using(res_pBuf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT)
           :using(sw_res, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

        graph:add_pass("Present", function(c) end):using(sw_res, 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
        graph:execute(cb)
        vk.vkEndCommandBuffer(cb)
    end

    -- Sync
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]; pFenceArr = ffi.new("VkFence[1]", {frame_fence})
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available_sem = pS[0]
end

function M.update()
    -- Process Death Row
    resource.tick()

    vk.vkWaitForFences(device, 1, pFenceArr, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, pFenceArr)
    
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    current_time = current_time + 0.016
    -- UPDATE ATTRACTOR BUFFER (CPU to GPU instantly)
    M.attr_ptr.time = current_time
    M.attr_ptr.mouse_x = ((_MOUSE_X or 0) / (sw.extent.width or 1280)) * 2 - 1
    M.attr_ptr.mouse_y = ((_MOUSE_Y or 0) / (sw.extent.height or 720)) * 2 - 1
    M.attr_ptr.mouse_down = _MOUSE_DOWN and 1 or 0

    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cbs[img_idx+1]}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
