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

local CITY_COUNT = 32768 -- Scaled up 4x
local VEHICLE_COUNT = 32
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe, line_pipe
local compute_pipe, bindless_set
local graph, g_cityBuffer, g_swImages = {}, {}, {}
local current_time = 0
local temperature = 5.0

local MAX_FRAMES_IN_FLIGHT = 1
local current_frame = 0
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local cbs = {}

function M.init()
    print("Example 33: HEAVY GPU VRP Solver (32k cities, 2.5M trials/frame)")
    math.randomseed(os.time())
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct City { 
            float x, y; 
            uint32_t vehicle_id; 
            uint32_t next_index; 
        } City;
        typedef struct PushConstants { 
            float dt, time; 
            uint32_t city_buf_id; 
            uint32_t seed; 
            uint32_t vehicle_count;
            float temperature;
        } PushConstants;
    ]]
    
    local initial_data = ffi.new("City[?]", CITY_COUNT)
    for i = 0, CITY_COUNT - 1 do 
        if i < VEHICLE_COUNT then
            local ang = (i / VEHICLE_COUNT) * math.pi * 2
            initial_data[i].x = math.cos(ang) * 0.8
            initial_data[i].y = math.sin(ang) * 0.8
            initial_data[i].vehicle_id = i
            initial_data[i].next_index = i
        else
            initial_data[i].x = (math.random()*1.9)-0.95
            initial_data[i].y = (math.random()*1.9)-0.95
            initial_data[i].vehicle_id = math.random(0, VEHICLE_COUNT - 1)
            initial_data[i].next_index = initial_data[i].vehicle_id
        end
    end
    
    local city_buffer = mc.buffer(ffi.sizeof("City") * CITY_COUNT, "storage", initial_data)
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, city_buffer.handle, 0, ffi.sizeof("City") * CITY_COUNT, 0)

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), offset = 0, size = 24 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    compute_pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/33_gpu_vrp/physics.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local vert = shader.create_module(device, shader.compile_glsl(io.open("examples/33_gpu_vrp/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag = shader.create_module(device, shader.compile_glsl(io.open("examples/33_gpu_vrp/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, depth_test = false })
    line_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, depth_test = false, additive = true })

    graph = render_graph.new(device)
    g_cityBuffer = graph:register_resource("CityBuffer", render_graph.TYPE_BUFFER, city_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    local pF = ffi.new("VkFence[1]")
    local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})

    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, fence_info, nil, pF); frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); render_finished_sems[i] = pS[0]
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
end

local last_ticks = 0

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame])
    if not img_idx then return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}))
    
    current_time = current_time + dt
    temperature = math.max(0.0, temperature * 0.995) -- Cooling
    if temperature < 0.05 and math.random() < 0.01 then temperature = 2.0 end -- Re-heat occasionally

    local cb = cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc_compute = ffi.new("PushConstants", { dt = dt, time = current_time, city_buf_id = 0, seed = math.random(1000000), vehicle_count = VEHICLE_COUNT, temperature = temperature })
    local pc_points = ffi.new("PushConstants", { dt = dt, time = current_time, city_buf_id = 0, mode = 0, vehicle_count = VEHICLE_COUNT, temperature = 0 })
    local pc_lines  = ffi.new("PushConstants", { dt = dt, time = current_time, city_buf_id = 0, mode = 1, vehicle_count = VEHICLE_COUNT, temperature = 0 })
    
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()
    graph:add_pass("Optimization", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        for i=1, 10 do
            pc_compute.seed = math.random(1000000)
            vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 24, pc_compute)
            vk.vkCmdDispatch(c, math.ceil(CITY_COUNT / 256), 1, 1)
            local bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, bar, 0, nil, 0, nil)
        end
    end):using(g_cityBuffer, bit.bor(vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32 = { 0.005, 0.005, 0.01, 1.0 }

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, line_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 24, pc_lines)
        vk.vkCmdDraw(c, CITY_COUNT * 2, 1, 0, 0)

        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 24, pc_points)
        vk.vkCmdDraw(c, CITY_COUNT, 1, 0, 0)
        
        vk.vkCmdEndRendering(c)
    end):using(g_cityBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sems[current_frame]}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sems[current_frame]}) 
    }), frame_fences[current_frame])
    
    sw:present(queue, img_idx, render_finished_sems[current_frame])
    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
