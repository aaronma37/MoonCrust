local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local M = {}

local ANT_COUNT = 131072
local CITY_COUNT = 12
local MAP_SIZE = 1024
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe, ant_pipe
local compute_ant, compute_decay, bindless_set
local graph, g_antBuffer, g_cityBuffer, g_swImages = {}, {}, {}, {}
local current_time = 0

local MAX_FRAMES_IN_FLIGHT = 1
local current_frame = 0
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local cbs = {}

function M.init()
    print("Example 35: Ant Colony Optimization (ACO) Network Solver")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Ant {
            float x, y;
            float angle;
            uint32_t phase;
            uint32_t home_city;
            uint32_t target_city;
            uint32_t p1, p2;
        } Ant;
        typedef struct City {
            float x, y;
            uint32_t id, pad;
        } City;
        typedef struct PushConstants {
            float dt, time;
            uint32_t ant_buf_id;
            uint32_t city_buf_id;
            uint32_t num_ants;
            uint32_t num_cities;
            uint32_t seed;
            uint32_t mode;
        } PushConstants;
    ]]
    
    -- 1. Initialize Ants and Cities
    local ant_data = ffi.new("Ant[?]", ANT_COUNT)
    for i = 0, ANT_COUNT - 1 do 
        ant_data[i].x = (math.random()*1.8)-0.9
        ant_data[i].y = (math.random()*1.8)-0.9
        ant_data[i].angle = math.random() * math.pi * 2
        ant_data[i].home_city = math.random(0, CITY_COUNT-1)
        ant_data[i].target_city = (ant_data[i].home_city + 1) % CITY_COUNT
        ant_data[i].phase = 0
    end
    local ant_buffer = mc.buffer(ffi.sizeof("Ant") * ANT_COUNT, "storage", ant_data)

    local city_data = ffi.new("City[?]", CITY_COUNT)
    for i = 0, CITY_COUNT - 1 do
        local ang = (i / CITY_COUNT) * math.pi * 2
        city_data[i].x = math.cos(ang) * 0.7 + (math.random()-0.5)*0.2
        city_data[i].y = math.sin(ang) * 0.7 + (math.random()-0.5)*0.2
        city_data[i].id = i
    end
    local city_buffer = mc.buffer(ffi.sizeof("City") * CITY_COUNT, "storage", city_data)

    -- 2. Pheromone Map (Storage Image)
    local p_map = mc.gpu.image(MAP_SIZE, MAP_SIZE, vk.VK_FORMAT_R8G8B8A8_UNORM, "storage")
    local p_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)

    -- 3. Bindless
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, ant_buffer.handle, 0, ffi.sizeof("Ant") * ANT_COUNT, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, city_buffer.handle, 0, ffi.sizeof("City") * CITY_COUNT, 1)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, p_map.view, p_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, p_map.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    -- 4. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    
    compute_ant = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/35_ant_colony/ant.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    compute_decay = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/35_ant_colony/decay.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local vert = shader.create_module(device, shader.compile_glsl(io.open("examples/35_ant_colony/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag = shader.create_module(device, shader.compile_glsl(io.open("examples/35_ant_colony/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, depth_test = false })
    ant_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, depth_test = false, additive = true })

    -- 5. Graph
    graph = render_graph.new(device)
    g_antBuffer = graph:register_resource("AntBuffer", render_graph.TYPE_BUFFER, ant_buffer.handle)
    g_cityBuffer = graph:register_resource("CityBuffer", render_graph.TYPE_BUFFER, city_buffer.handle)
    local g_pMap = graph:register_resource("PheromoneMap", render_graph.TYPE_IMAGE, p_map.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED })
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, ffi.new("VkFence[1]")) -- Dummy for table
        frame_fences[i] = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fences[i])
        image_available_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sems[i])
        render_finished_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, render_finished_sems[i])
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
    
    M.g_pMap = g_pMap
end

local last_ticks = 0

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, frame_fences[current_frame], vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame][0])
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, frame_fences[current_frame])
    
    current_time = current_time + dt
    local cb = cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { dt = dt, time = current_time, ant_buf_id = 0, city_buf_id = 1, num_ants = ANT_COUNT, num_cities = CITY_COUNT, seed = math.random(1000000), mode = 0 })
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()
    graph:add_pass("Ant_Logic", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_ant)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc)
        vk.vkCmdDispatch(c, math.ceil(ANT_COUNT / 256), 1, 1)
    end):using(g_antBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_cityBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(M.g_pMap, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    graph:add_pass("Pheromone_Decay", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_decay)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc)
        vk.vkCmdDispatch(c, MAP_SIZE / 16, MAP_SIZE / 16, 1)
    end):using(M.g_pMap, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[3] = 1.0

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        
        -- 1. Background (Pheromones)
        pc.mode = 0
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc)
        vk.vkCmdDraw(c, 3, 1, 0, 0)

        -- 2. Ants
        pc.mode = 1
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, ant_pipe)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc)
        vk.vkCmdDraw(c, ANT_COUNT, 1, 0, 0)
        
        vk.vkCmdEndRendering(c)
    end):using(g_antBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(M.g_pMap, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = image_available_sems[current_frame], 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = render_finished_sems[current_frame] 
    }), frame_fences[current_frame][0])
    
    sw:present(queue, img_idx, render_finished_sems[current_frame][0])
    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
