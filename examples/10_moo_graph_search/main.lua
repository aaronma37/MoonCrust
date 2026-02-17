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
local sdl = require("vulkan.sdl")
local math_utils = require("examples.10_moo_graph_search.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    angle = 0,
    current_time = 0,
    last_reset = 0
}

-- CONFIG: SCALED UP
local FPS_LIMIT = 60
local FRAME_TIME = 1000 / FPS_LIMIT
local NODE_COUNT = 5000
local EDGE_COUNT = 15000
local RESET_INTERVAL = 8 

-- State
local win_graph, win_pareto, win_pareto_id
local sw_graph, sw_pareto
local device, queue, graphics_family
local pipe_nodes, pipe_edges, pipe_pareto, pipe_search
local layout_graph
local node_buf, edge_buf, pareto_buf, interactive_buf
local bindless_set
local image_available_graph, image_available_pareto
local cbs_graph, cbs_pareto
local frame_fence
local initial_solutions = nil

function M.init()
    print("Example 10: MOO GRAPH SEARCH (Clean Interactive)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct Node { float x, y, z, p1; float r, g, b, p2; } Node;
        typedef struct Edge { uint32_t a, b; float dist, cost; } Edge;
        typedef struct Solution { float dist, cost; uint32_t parent_node, parent_sol_idx; } Solution;
        typedef struct InteractiveData { float mouse_x, mouse_y; uint32_t active_node, active_sol_idx; } InteractiveData;
        typedef struct GraphPC { float mvp[16]; float obs_x, obs_y, obs_z, obs_r; uint32_t mode; } GraphPC;
        typedef struct SearchPC { uint32_t node_count, edge_count, iter, pad; float obs_x, obs_y, obs_z, obs_r; } SearchPC;
    ]]

    win_graph = _SDL_WINDOW
    sw_graph = swapchain.new(instance, physical_device, device, win_graph)
    win_pareto = sdl.SDL_CreateWindow("Pareto Front", 640, 640, bit.bor(sdl.SDL_WINDOW_VULKAN, sdl.SDL_WINDOW_RESIZABLE))
    win_pareto_id = sdl.SDL_GetWindowID(win_pareto)
    sw_pareto = swapchain.new(instance, physical_device, device, win_pareto)

    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 256 * 1024 * 1024)
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 128 * 1024 * 1024)

    local nodes = ffi.new("Node[?]", NODE_COUNT)
    for i = 0, NODE_COUNT - 1 do
        nodes[i].x, nodes[i].y, nodes[i].z = (math.random()-0.5)*12, (math.random()-0.5)*12, (math.random()-0.5)*12
        nodes[i].r, nodes[i].g, nodes[i].b = 0.1, 0.15, 0.2
    end
    nodes[0].r, nodes[0].g, nodes[0].b = 1.0, 1.0, 0.0
    
    local node_size = ffi.sizeof("Node") * NODE_COUNT
    local pNB = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = node_size, usage = bit.bor(vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT) }), nil, pNB)
    node_buf = pNB[0]; local n_alloc = device_heap:malloc(node_size); vk.vkBindBufferMemory(device, node_buf, n_alloc.memory, n_alloc.offset)
    staging.new(physical_device, device, host_heap, node_size + 1024):upload_buffer(node_buf, nodes, 0, queue, graphics_family)

    local edges = ffi.new("Edge[?]", EDGE_COUNT)
    for i = 0, EDGE_COUNT - 1 do
        local a, b = math.random(0, NODE_COUNT - 1), math.random(0, NODE_COUNT - 1)
        edges[i].a, edges[i].b = a, b
        local dx, dy, dz = nodes[a].x - nodes[b].x, nodes[a].y - nodes[b].y, nodes[a].z - nodes[b].z
        edges[i].dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        edges[i].cost = math.random() * 10.0
    end
    local edge_size = ffi.sizeof("Edge") * EDGE_COUNT
    local pEB = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = edge_size, usage = bit.bor(vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT) }), nil, pEB)
    edge_buf = pEB[0]; local e_alloc = device_heap:malloc(edge_size); vk.vkBindBufferMemory(device, edge_buf, e_alloc.memory, e_alloc.offset)
    staging.new(physical_device, device, host_heap, edge_size + 1024):upload_buffer(edge_buf, edges, 0, queue, graphics_family)

    local sol_count = NODE_COUNT * 8
    initial_solutions = ffi.new("Solution[?]", sol_count)
    for i = 0, sol_count - 1 do initial_solutions[i].dist, initial_solutions[i].cost, initial_solutions[i].parent_node = 1e9, 1e9, 0xFFFFFFFF end
    for i = 0, 9 do initial_solutions[i * 8].dist, initial_solutions[i * 8].cost = 0, 0 end
    local sol_size = ffi.sizeof("Solution") * sol_count
    local pSB = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = sol_size, usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT) }), nil, pSB)
    pareto_buf = pSB[0]; local s_alloc = device_heap:malloc(sol_size); vk.vkBindBufferMemory(device, pareto_buf, s_alloc.memory, s_alloc.offset)
    staging.new(physical_device, device, host_heap, sol_size + 1024):upload_buffer(pareto_buf, initial_solutions, 0, queue, graphics_family)

    local pIB = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size = ffi.sizeof("InteractiveData"), usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) }), nil, pIB)
    interactive_buf = pIB[0]; local i_alloc = host_heap:malloc(ffi.sizeof("InteractiveData")); vk.vkBindBufferMemory(device, interactive_buf, i_alloc.memory, i_alloc.offset)
    M.interactive_ptr = ffi.cast("InteractiveData*", i_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, node_buf, 0, node_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, edge_buf, 0, edge_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pareto_buf, 0, sol_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, interactive_buf, 0, ffi.sizeof("InteractiveData"), 3)

    layout_graph = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 84 }}))
    pipe_search = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/search.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local vert_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/graph.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/graph.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local edge_frag = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/edge.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local edge_vert = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/edge.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local pareto_vert = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/pareto.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))

    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, vert_mod, frag_mod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, edge_vert, edge_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive = true })
    pipe_pareto = pipeline.create_graphics_pipeline(device, layout_graph, pareto_vert, frag_mod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_graph = pSem[0]
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_pareto = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cbs_graph = command.allocate_buffers(device, pool, sw_graph.image_count)
    cbs_pareto = command.allocate_buffers(device, pool, sw_pareto.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    M.staging = staging.new(physical_device, device, host_heap, sol_size + 1024)
end

function M.update()
    local status, err = pcall(function()
        local current_ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = current_ticks - M.last_frame_time
        if elapsed < FRAME_TIME then sdl.SDL_Delay(FRAME_TIME - elapsed); current_ticks = tonumber(sdl.SDL_GetTicks()) end
        M.last_frame_time = current_ticks
        M.current_time = M.current_time + 0.016

        if M.current_time - M.last_reset > RESET_INTERVAL then
            M.last_reset = M.current_time
            M.staging:upload_buffer(pareto_buf, initial_solutions, 0, queue, graphics_family)
        end

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
        resource.tick(); M.angle = M.angle + 0.005

        if _MOUSE_WINDOW == win_pareto_id then
            M.interactive_ptr.mouse_x = (_MOUSE_X / sw_pareto.extent.width) * 2 - 1
            M.interactive_ptr.mouse_y = (_MOUSE_Y / sw_pareto.extent.height) * 2 - 1
        else
            M.interactive_ptr.mouse_x = 2.0
        end

        local idx_graph = sw_graph:acquire_next_image(image_available_graph)
        local idx_pareto = sw_pareto:acquire_next_image(image_available_pareto)
        if idx_graph == nil or idx_pareto == nil then return end

        local view = math_utils.look_at({math.cos(M.angle)*18, 6, math.sin(M.angle)*18}, {0,0,0}, {0,1,0})
        local proj = math_utils.perspective(math.rad(45), sw_graph.extent.width/sw_graph.extent.height, 0.1, 100.0)
        local mvp = math_utils.multiply(proj, view)
        
        local ox, oy, oz = math.sin(M.current_time*0.4)*5, 0, math.cos(M.current_time*0.4)*5
        local pc = ffi.new("GraphPC"); for i=1,16 do pc.mvp[i-1] = mvp[i] end
        pc.obs_x, pc.obs_y, pc.obs_z, pc.obs_r = ox, oy, oz, 3.0

        local cb_g = cbs_graph[idx_graph + 1]
        vk.vkResetCommandBuffer(cb_g, 0); vk.vkBeginCommandBuffer(cb_g, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        
        local search_pc = ffi.new("SearchPC", { node_count = NODE_COUNT, edge_count = EDGE_COUNT, iter = 0, obs_x=ox, obs_y=oy, obs_z=oz, obs_r=3.0 })
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_search)
        vk.vkCmdBindDescriptorSets(cb_g, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, search_pc)
        vk.vkCmdDispatch(cb_g, math.ceil(EDGE_COUNT / 256), 1, 1)

        local mem_bar = ffi.new("VkMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT) }})
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT), 0, 1, mem_bar, 0, nil, 0, nil)

        local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw_graph.images[idx_graph]), subresourceRange=range, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw_graph.views[idx_graph]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.005, 0.005, 0.01, 1.0}
        vk.vkCmdBeginRendering(cb_g, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw_graph.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
        vk.vkCmdSetViewport(cb_g, 0, 1, ffi.new("VkViewport", { width=sw_graph.extent.width, height=sw_graph.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(cb_g, 0, 1, ffi.new("VkRect2D", { extent=sw_graph.extent }))
        vk.vkCmdBindDescriptorSets(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        
        -- DRAW OBSTACLE FIRST (So nodes are drawn on top)
        pc.mode = 1 -- Obstacle mode
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, pc)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb_g, 1, 1, NODE_COUNT, 0)

        -- DRAW OTHERS
        pc.mode = 0 -- Regular mode
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, pc)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges); vk.vkCmdDraw(cb_g, EDGE_COUNT * 2, 1, 0, 0)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb_g, NODE_COUNT, 1, 0, 0)
        
        vk.vkCmdEndRendering(cb_g)

        bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb_g)

        local cb_p = cbs_pareto[idx_pareto + 1]
        vk.vkResetCommandBuffer(cb_p, 0); vk.vkBeginCommandBuffer(cb_p, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        bar[0].image, bar[0].oldLayout, bar[0].newLayout = ffi.cast("VkImage", sw_pareto.images[idx_pareto]), vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        vk.vkCmdPipelineBarrier(cb_p, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
        color_attach[0].imageView, color_attach[0].clearValue.color.float32 = ffi.cast("VkImageView", sw_pareto.views[idx_pareto]), {0.01, 0.01, 0.01, 1.0}
        vk.vkCmdBeginRendering(cb_p, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw_pareto.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
        vk.vkCmdSetViewport(cb_p, 0, 1, ffi.new("VkViewport", { width=sw_pareto.extent.width, height=sw_pareto.extent.height, maxDepth=1 })); vk.vkCmdSetScissor(cb_p, 0, 1, ffi.new("VkRect2D", { extent=sw_pareto.extent }))
        vk.vkCmdBindPipeline(cb_p, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_pareto)
        vk.vkCmdBindDescriptorSets(cb_p, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdDraw(cb_p, NODE_COUNT * 8, 1, 0, 0)
        vk.vkCmdEndRendering(cb_p)
        bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        vk.vkCmdPipelineBarrier(cb_p, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb_p)

        local submit_info = ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=2, pWaitSemaphores=ffi.new("VkSemaphore[2]", {image_available_graph, image_available_pareto}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[2]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=2, pCommandBuffers=ffi.new("VkCommandBuffer[2]", {cb_g, cb_p}), signalSemaphoreCount=2, pSignalSemaphores=ffi.new("VkSemaphore[2]", {sw_graph.semaphores[idx_graph], sw_pareto.semaphores[idx_pareto]}) })
        vk.vkQueueSubmit(queue, 1, submit_info, frame_fence)
        sw_graph:present(queue, idx_graph, sw_graph.semaphores[idx_graph]); sw_pareto:present(queue, idx_pareto, sw_pareto.semaphores[idx_pareto])
    end)
    if not status then print("M.update: ERROR:", err) end
end

return M
