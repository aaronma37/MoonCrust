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

local NUM_JOBS = 32
local NUM_MACHINES = 16
local NUM_OPS = NUM_JOBS * NUM_MACHINES
local POP_SIZE = 4096

local device, queue, graphics_family, sw, pipe_layout
local pipe_evaluate, pipe_breed, pipe_render
local bindless_set
local graph, g_jobData, g_pop, g_scores, g_renderData, g_swImages = {}, {}, {}, {}, {}, {}
local current_time = 0

local scores_ptr -- Pointer to mapped score buffer
local best_idx = 0
local best_span = 0.0

local MAX_FRAMES_IN_FLIGHT = 1
local current_frame = 0
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local cbs = {}

function M.init()
    print("Example 38: GPU Job Shop Scheduling (Genetic Algorithm)")
    math.randomseed(os.time())
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Operation {
            uint32_t machine;
            float duration;
        } Operation;
        typedef struct RenderOp {
            float start, machine, duration, job;
        } RenderOp;
        typedef struct PushConstants {
            float dt, time;
            uint32_t pop_size;
            uint32_t best_idx;
            uint32_t mode;
        } PushConstants;
        typedef struct RenderPC {
            float dt, time;
            uint32_t pop_size;
            uint32_t best_idx;
            float max_span;
        } RenderPC;
    ]]
    
    -- 1. Initialize Problem Data
    local job_data_size = ffi.sizeof("Operation") * NUM_OPS
    local job_data = ffi.new("Operation[?]", NUM_OPS)
    
    for j = 0, NUM_JOBS-1 do
        -- Each job visits every machine exactly once in random order
        local machines = {}
        for m = 0, NUM_MACHINES-1 do table.insert(machines, m) end
        
        for m = 0, NUM_MACHINES-1 do
            -- Shuffle machine order
            local swap_idx = math.random(m + 1, NUM_MACHINES)
            machines[m + 1], machines[swap_idx] = machines[swap_idx], machines[m + 1]
            
            -- Setup op
            local op_idx = j * NUM_MACHINES + m
            job_data[op_idx].machine = machines[m + 1]
            job_data[op_idx].duration = math.random(10, 100) -- Duration
        end
    end
    local buf_job_data = mc.buffer(job_data_size, "storage", job_data)

    -- 2. Initialize Population (Random Permutations of Job IDs)
    local pop_size_bytes = ffi.sizeof("uint32_t") * POP_SIZE * NUM_OPS
    local pop_data = ffi.new("uint32_t[?]", POP_SIZE * NUM_OPS)
    
    for p = 0, POP_SIZE - 1 do
        local base = p * NUM_OPS
        -- Create a valid chromosome: each job ID appears exactly NUM_MACHINES times
        local list = {}
        for j = 0, NUM_JOBS-1 do
            for m = 0, NUM_MACHINES-1 do table.insert(list, j) end
        end
        -- Shuffle list
        for i = 1, NUM_OPS do
            local j = math.random(i, NUM_OPS)
            list[i], list[j] = list[j], list[i]
            pop_data[base + i - 1] = list[i]
        end
    end
    local buf_pop = mc.buffer(pop_size_bytes, "storage", pop_data)

    -- 3. Results Buffers
    local buf_scores = mc.buffer(ffi.sizeof("float") * POP_SIZE, "storage", nil, true) -- Host visible
    scores_ptr = ffi.cast("float*", buf_scores.allocation.ptr)
    
    local buf_render = mc.buffer(ffi.sizeof("RenderOp") * NUM_OPS, "storage")

    -- 4. Bindless
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_job_data.handle, 0, job_data_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_pop.handle, 0, pop_size_bytes, 0)
    descriptors.update_buffer_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_scores.handle, 0, ffi.sizeof("float") * POP_SIZE, 0)
    descriptors.update_buffer_set(device, bindless_set, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_render.handle, 0, ffi.sizeof("RenderOp") * NUM_OPS, 0)

    -- 5. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    
    pipe_evaluate = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/38_job_shop_scheduling/evaluate.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_breed = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/38_job_shop_scheduling/breed.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local vert = shader.create_module(device, shader.compile_glsl(io.open("examples/38_job_shop_scheduling/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag = shader.create_module(device, shader.compile_glsl(io.open("examples/38_job_shop_scheduling/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, vert, frag, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, 
        depth_test = false 
    })

    -- 6. Graph
    graph = render_graph.new(device)
    g_jobData = graph:register_resource("JobData", render_graph.TYPE_BUFFER, buf_job_data.handle)
    g_pop = graph:register_resource("Population", render_graph.TYPE_BUFFER, buf_pop.handle)
    g_scores = graph:register_resource("Scores", render_graph.TYPE_BUFFER, buf_scores.handle)
    g_renderData = graph:register_resource("RenderData", render_graph.TYPE_BUFFER, buf_render.handle)
    
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        frame_fences[i] = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fences[i])
        image_available_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sems[i])
        render_finished_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, render_finished_sems[i])
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
end

local last_ticks = 0

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, frame_fences[current_frame], vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    
    -- Read back best score from PREVIOUS frame (to avoid pipeline stall)
    -- Simply linear scan the mapped buffer (small enough for CPU)
    local min_span = 1e9
    local new_best_idx = 0
    for i=0, POP_SIZE-1 do
        if scores_ptr[i] > 0 and scores_ptr[i] < min_span then
            min_span = scores_ptr[i]
            new_best_idx = i
        end
    end
    best_idx = new_best_idx
    best_span = min_span
    
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame][0])
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, frame_fences[current_frame])
    
    current_time = current_time + dt
    local cb = cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { dt = dt, time = current_time, pop_size = POP_SIZE, best_idx = best_idx, mode = 0 })
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()

    -- 1. Breeding (Crossover + Mutation)
    graph:add_pass("Breed", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_breed)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        -- We seed the shader with random + best_idx
        pc.mode = math.random(1000000) -- Use 'mode' slot for seed in breed shader
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
        vk.vkCmdDispatch(c, math.ceil(POP_SIZE / 64), 1, 1)
    end):using(g_pop, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_scores, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- 2. Evaluation
    graph:add_pass("Evaluate", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_evaluate)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        pc.mode = 0 -- Evaluate Mode
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
        vk.vkCmdDispatch(c, math.ceil(POP_SIZE / 64), 1, 1)
    end):using(g_pop, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_jobData, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_scores, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- 3. WriteBack Best (Prepare Render Buffer)
    graph:add_pass("WriteBack", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_evaluate)
        pc.mode = 1 -- WriteBack Mode
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
        vk.vkCmdDispatch(c, 1, 1, 1) -- Only 1 thread needed to write the best entry
    end):using(g_pop, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_jobData, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_renderData, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- 4. Render
    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[0] = 0.05; color_attach[0].clearValue.color.float32[1] = 0.05; color_attach[0].clearValue.color.float32[2] = 0.05; color_attach[0].clearValue.color.float32[3] = 1

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        
        local rpc = ffi.new("RenderPC", { dt = dt, time = current_time, pop_size = POP_SIZE, best_idx = best_idx, max_span = best_span })
        
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 32, rpc)
        -- Draw 512 instances (operations)
        vk.vkCmdDraw(c, 4, NUM_OPS, 0, 0)
        
        vk.vkCmdEndRendering(c)
    end):using(g_renderData, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    
    -- Ensure scores are ready for CPU next frame
    local bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, 0, 1, bar, 0, nil, 0, nil)

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
