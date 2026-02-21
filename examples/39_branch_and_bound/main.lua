local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local staging = require("vulkan.staging")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local M = {
    current_time = 0,
    nodes_done = 0,
    reset_timer = 0,
    last_ticks = 0,
    current_frame = 0,
    MAX_FRAMES_IN_FLIGHT = 2
}

local NUM_ITEMS = 40
local MAX_NODES = 262144 
local CAPACITY = 150.0

local device, queue, graphics_family, sw, pipe_layout, compute_pipe, graphics_pipe, line_pipe, bindless_set
local graph, g_items, g_nodes, g_stats, g_swImages = {}, {}, {}, {}, {}
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local cbs = {}
local stats_ptr 

function M.generate_problem()
    local items = ffi.new("Item[?]", NUM_ITEMS)
    for i = 0, NUM_ITEMS - 1 do
        items[i].val = math.random(10, 100); items[i].weight = math.random(5, 50)
    end
    local item_list = {}
    for i=0, NUM_ITEMS-1 do table.insert(item_list, {v=items[i].val, w=items[i].weight}) end
    table.sort(item_list, function(a,b) return (a.v/a.w) > (b.v/b.w) end)
    for i=0, NUM_ITEMS-1 do items[i].val = item_list[i+1].v; items[i].weight = item_list[i+1].w end

    local greedy_val = 0
    local curr_w = 0
    for i=0, NUM_ITEMS-1 do
        if curr_w + items[i].weight <= CAPACITY then
            curr_w = curr_w + items[i].weight
            greedy_val = greedy_val + items[i].val
        end
    end

    local pd, d, q, family = vulkan.get_physical_device(), vulkan.get_device(), vulkan.get_queue()
    staging.new(pd, d, mc.gpu.heaps.host, ffi.sizeof("Item") * NUM_ITEMS + 1024):upload_buffer(g_items.handle, items, 0, q, family, ffi.sizeof("Item") * NUM_ITEMS)

    local initial_nodes = ffi.new("Node[?]", MAX_NODES)
    for i=0, MAX_NODES-1 do initial_nodes[i].depth = 0; initial_nodes[i].status = 0 end
    initial_nodes[0].val = 0; initial_nodes[0].weight = 0; initial_nodes[0].depth = 0; initial_nodes[0].status = 0; initial_nodes[0].x_pos = 0
    staging.new(pd, d, mc.gpu.heaps.host, ffi.sizeof("Node") * MAX_NODES + 1024):upload_buffer(g_nodes.handle, initial_nodes, 0, q, family, ffi.sizeof("Node") * MAX_NODES)

    local stats = ffi.new("Stats[1]")
    stats[0].count = 1; stats[0].best_uint = ffi.cast("uint32_t*", ffi.new("float[1]", greedy_val))[0]
    staging.new(pd, d, mc.gpu.heaps.host, ffi.sizeof("Stats") + 1024):upload_buffer(g_stats.handle, stats, 0, q, family, ffi.sizeof("Stats"))
    
    M.nodes_done = 0; M.reset_timer = 0
    print("New Problem: Items=40. Branching beginning...")
end

function M.init()
    print("Example 39: Mixed-Integer Branch-and-Bound (Decision Tree)")
    math.randomseed(os.time())
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(vulkan.get_instance(), vulkan.get_physical_device(), device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Item { float val, weight; } Item;
        typedef struct Node { float val, weight; uint32_t depth, parent, status; float x_pos; uint32_t p1, p2; } Node;
        typedef struct Stats { uint32_t count; uint32_t best_uint; } Stats;
        typedef struct PushConstants { float dt, time; uint32_t max_nodes, num_items; float capacity; uint32_t start_idx, num_to_process, mode; } PushConstants;
    ]]
    
    local buf_items = mc.buffer(ffi.sizeof("Item") * NUM_ITEMS, "storage")
    local buf_nodes = mc.buffer(ffi.sizeof("Node") * MAX_NODES, "storage")
    local buf_stats = mc.buffer(ffi.sizeof("Stats"), "storage", nil, true)
    stats_ptr = ffi.cast("Stats*", buf_stats.allocation.ptr)

    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_items.handle, 0, ffi.sizeof("Item") * NUM_ITEMS, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_nodes.handle, 0, ffi.sizeof("Node") * MAX_NODES, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf_stats.handle, 0, ffi.sizeof("Stats"), 2)

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL, offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    compute_pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/39_branch_and_bound/evaluate.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local vmod = shader.create_module(device, shader.compile_glsl(io.open("examples/39_branch_and_bound/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local fmod = shader.create_module(device, shader.compile_glsl(io.open("examples/39_branch_and_bound/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vmod, fmod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, depth_test = false, additive = true })
    line_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, vmod, fmod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, depth_test = false, additive = true })

    graph = render_graph.new(device)
    g_items, g_nodes, g_stats = graph:register_resource("Items", 1, buf_items.handle), graph:register_resource("Nodes", 1, buf_nodes.handle), graph:register_resource("Stats", 1, buf_stats.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, 2, sw.images[i]) end
    M.g_items, M.g_nodes, M.g_stats = g_items, g_nodes, g_stats
    M.generate_problem()

    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})
    for i=0, M.MAX_FRAMES_IN_FLIGHT-1 do
        local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, fence_info, nil, pF); frame_fences[i] = pF[0]
        local pS1 = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pS1); image_available_sems[i] = pS1[0]
        local pS2 = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pS2); render_finished_sems[i] = pS2[0]
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), M.MAX_FRAMES_IN_FLIGHT)
end

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if M.last_ticks == 0 then M.last_ticks = ticks end
    local dt = (ticks - M.last_ticks) / 1000.0; M.last_ticks = ticks
    M.reset_timer = M.reset_timer + dt
    if M.reset_timer > 30.0 then M.generate_problem() end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fences[M.current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local current_total_nodes = stats_ptr.count
    local img_idx = sw:acquire_next_image(image_available_sems[M.current_frame])
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fences[M.current_frame]}))
    M.current_time = M.current_time + dt
    local cb = cbs[M.current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local pc = ffi.new("PushConstants", { dt = dt, time = M.current_time, max_nodes = MAX_NODES, num_items = NUM_ITEMS, capacity = CAPACITY, start_idx = M.nodes_done, num_to_process = 0, mode = 0 })
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})
    graph:reset()
    local nodes_to_eval = math.min(500, math.max(1, current_total_nodes - M.nodes_done))
    if M.nodes_done < MAX_NODES and nodes_to_eval > 0 then
        graph:add_pass("Branch", function(c)
            vk.vkCmdBindPipeline(c, 1, compute_pipe); vk.vkCmdBindDescriptorSets(c, 1, pipe_layout, 0, 1, pSets, 0, nil)
            pc.num_to_process, pc.mode = nodes_to_eval, 0
            vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc)
            vk.vkCmdDispatch(c, math.ceil(nodes_to_eval / 64), 1, 1); M.nodes_done = M.nodes_done + nodes_to_eval
        end):using(M.g_items, 1, 32):using(M.g_nodes, 3, 32):using(M.g_stats, 3, 32)
    end
    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO; color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[3]=1.0
        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent })); vk.vkCmdBindDescriptorSets(c, 0, pipe_layout, 0, 1, pSets, 0, nil)
        local draw_count = math.min(current_total_nodes, MAX_NODES)
        pc.mode = 1; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc); vk.vkCmdBindPipeline(c, 0, line_pipe); vk.vkCmdDraw(c, draw_count * 2, 1, 0, 0)
        pc.mode = 2; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 32, pc); vk.vkCmdBindPipeline(c, 0, graphics_pipe); vk.vkCmdDraw(c, draw_count, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(M.g_nodes, 1, 128):using(g_swImages[img_idx], 128, 1024, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    local bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, 0, 1, bar, 0, nil, 0, nil)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sems[M.current_frame]}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sems[M.current_frame]}) }), frame_fences[M.current_frame])
    sw:present(queue, img_idx, render_finished_sems[M.current_frame]); M.current_frame = (M.current_frame + 1) % M.MAX_FRAMES_IN_FLIGHT
end
return M
