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

-- CONFIG
local AGENT_COUNT = 1024 * 1024
-- MAP SIZE is now dynamic

-- State
local device, queue, graphics_family, sw
local pipe_agent, pipe_diffuse, pipe_render
local layout_agent, layout_diffuse, layout_render
local bindless_set, cbs, pFenceArr, image_available_sem, frame_fence
local graph, g_swImages = {}, {}
local current_time = 0

-- Resources
local agent_buf
local map_imgs, map_views, map_samplers = {}, {}, {} -- [1], [2] for ping-pong
local g_maps, g_agents = {}, nil
local MAP_WIDTH, MAP_HEIGHT

function M.init()
    print("Example 08: SLIME MOLD (Physarum) - Visual ML")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    resource.init(device)

    -- Dynamic Map Size (Aligned to 16)
    MAP_WIDTH = sw.extent.width
    MAP_HEIGHT = math.ceil(sw.extent.height / 16) * 16
    print("Map Size: " .. MAP_WIDTH .. "x" .. MAP_HEIGHT)

    ffi.cdef[[
        typedef struct Agent { float x, y, angle, pad; } Agent;
        typedef struct AgentPC { float dt, time; uint32_t buf, tex, img, w, h; } AgentPC;
        typedef struct DiffusePC { float dt; uint32_t tex, img; } DiffusePC;
        typedef struct RenderPC { uint32_t tex; } RenderPC;
    ]]

    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 512 * 1024 * 1024)
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 128 * 1024 * 1024)

    -- 1. Agents Buffer
    local buf_size = ffi.sizeof("Agent") * AGENT_COUNT
    local pBuf = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = buf_size, usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT) }), nil, pBuf)
    agent_buf = pBuf[0]
    local alloc = device_heap:malloc(buf_size)
    vk.vkBindBufferMemory(device, agent_buf, alloc.memory, alloc.offset)

    local agents_ptr = ffi.new("Agent[?]", AGENT_COUNT)
    for i = 0, AGENT_COUNT - 1 do
        local r = math.sqrt(math.random()) * (MAP_HEIGHT * 0.4)
        local theta = math.random() * 6.28318
        agents_ptr[i].x = (MAP_WIDTH / 2) + r * math.cos(theta)
        agents_ptr[i].y = (MAP_HEIGHT / 2) + r * math.sin(theta)
        agents_ptr[i].angle = theta + 3.14159
    end
    staging.new(physical_device, device, host_heap, buf_size + 1024):upload_buffer(agent_buf, agents_ptr, 0, queue, graphics_family)

    -- 2. Trail Maps (Ping-Pong)
    for i = 1, 2 do
        map_imgs[i] = image.create_2d(device, MAP_WIDTH, MAP_HEIGHT, vk.VK_FORMAT_R8G8B8A8_UNORM, bit.bor(vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_STORAGE_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
        local ialloc = device_heap:malloc(MAP_WIDTH * MAP_HEIGHT * 4)
        vk.vkBindImageMemory(device, map_imgs[i], ialloc.memory, ialloc.offset)
        map_views[i] = image.create_view(device, map_imgs[i], vk.VK_FORMAT_R8G8B8A8_UNORM)
        map_samplers[i] = image.create_sampler(device, vk.VK_FILTER_LINEAR)
    end

    -- GPU Clear (More reliable than Staging upload)
    local pool = command.create_pool(device, graphics_family)
    local setup_cb = command.allocate_buffers(device, pool, 1)[1]
    vk.vkBeginCommandBuffer(setup_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    
    local clear_color = ffi.new("VkClearColorValue") -- Default is 0.0
    local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
    
    for i = 1, 2 do
        -- Transition to Transfer DST
        local bar = ffi.new("VkImageMemoryBarrier", {
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT,
            image = map_imgs[i],
            subresourceRange = range
        })
        vk.vkCmdPipelineBarrier(setup_cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {bar}))
        
        -- Clear
        vk.vkCmdClearColorImage(setup_cb, map_imgs[i], vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, clear_color, 1, range)
        
        -- Transition to General (Ready for Compute)
        bar.oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
        bar.newLayout = vk.VK_IMAGE_LAYOUT_GENERAL
        bar.srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
        bar.dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT
        vk.vkCmdPipelineBarrier(setup_cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {bar}))
    end
    
    vk.vkEndCommandBuffer(setup_cb)
    local fence_setup = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO }), nil, fence_setup)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {setup_cb}) }), fence_setup[0])
    vk.vkWaitForFences(device, 1, fence_setup, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkDestroyFence(device, fence_setup[0], nil)
    vk.vkDestroyCommandPool(device, pool, nil)

    -- 3. Bindless
    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, agent_buf, 0, buf_size, 0)
    for i = 1, 2 do
        descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, map_views[i], map_samplers[i], vk.VK_IMAGE_LAYOUT_GENERAL, i-1)
        descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, map_views[i], vk.VK_IMAGE_LAYOUT_GENERAL, i-1)
    end

    -- 4. Pipelines
    layout_agent = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 32 }}))
    pipe_agent = pipeline.create_compute_pipeline(device, layout_agent, shader.create_module(device, shader.compile_glsl(io.open("examples/08_slime_mold/agent.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    layout_diffuse = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 16 }}))
    pipe_diffuse = pipeline.create_compute_pipeline(device, layout_diffuse, shader.create_module(device, shader.compile_glsl(io.open("examples/08_slime_mold/diffuse.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    layout_render = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT, offset = 0, size = 4 }}))
    pipe_render = pipeline.create_graphics_pipeline(device, layout_render, shader.create_module(device, shader.compile_glsl(io.open("examples/08_slime_mold/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/08_slime_mold/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        cull_mode = vk.VK_CULL_MODE_NONE,
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    })

    -- 5. Render Graph
    graph = render_graph.new(device)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end
    for i=1, 2 do g_maps[i] = graph:register_resource("Map_"..i, render_graph.TYPE_IMAGE, map_imgs[i]) end
    g_agents = graph:register_resource("Agents", render_graph.TYPE_BUFFER, agent_buf)

    -- 6. Sync
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]; pFenceArr = ffi.new("VkFence[1]", {frame_fence})
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available_sem = pS[0]
end

local frame_idx = 0

function M.update()
    vk.vkDeviceWaitIdle(device)
    resource.tick()
    
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    current_time = current_time + 0.016
    frame_idx = frame_idx + 1
    
    local r_idx = (frame_idx % 2) -- 0 or 1
    local w_idx = 1 - r_idx
    local r_lua, w_lua = r_idx + 1, w_idx + 1

    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    graph:reset()
    
    -- PASS 1: Diffuse (Read R -> Write W)
    graph:add_pass("Diffuse", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_diffuse)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_diffuse, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, layout_diffuse, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, ffi.new("DiffusePC", {0.016, r_idx, w_idx}))
        vk.vkCmdDispatch(c, math.ceil(MAP_WIDTH / 16), math.ceil(MAP_HEIGHT / 16), 1)
    end):using(g_maps[r_lua], vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_maps[w_lua], vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    -- PASS 2: Agents (Read W -> Write W)
    graph:add_pass("Agents", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_agent)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_agent, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, layout_agent, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, ffi.new("AgentPC", {0.016, current_time, 0, w_idx, w_idx, MAP_WIDTH, MAP_HEIGHT}))
        vk.vkCmdDispatch(c, math.ceil(AGENT_COUNT / 256), 1, 1)
    end):using(g_agents, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_maps[w_lua], vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    -- PASS 3: Render (Draw W)
    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
        
        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_render, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, layout_render, vk.VK_SHADER_STAGE_FRAGMENT_BIT, 0, 4, ffi.new("RenderPC", {w_idx}))
        vk.vkCmdDraw(c, 3, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_maps[w_lua], vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
