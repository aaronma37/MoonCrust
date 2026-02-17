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

local M = {}

-- State
local device, queue, graphics_family, sw, graph
local pipe_nodes, pipe_edges, layout_graph
local node_buf, edge_buf, bindless_set
local image_available_sem, frame_fence, cbs

function M.init()
    print("Example 13: RENDER GRAPH VISUALIZER")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    resource.init(device)

    -- Define shared data structures
    ffi.cdef[[
        typedef struct VisNode { float x, y, z, p1; float r, g, b, p2; } VisNode;
        typedef struct VisEdge { uint32_t a, b; } VisEdge;
        typedef struct VisPC { float mvp[16]; uint32_t mode; } VisPC;
    ]]

    -- 1. Create a dummy graph to visualize
    graph = render_graph.new(device)
    
    -- Register some dummy resources
    local res_physics = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, nil)
    local res_shadow = graph:register_resource("ShadowMap", render_graph.TYPE_IMAGE, nil)
    local res_scene = graph:register_resource("SceneColor", render_graph.TYPE_IMAGE, nil)
    local res_ui = graph:register_resource("UIBuffer", render_graph.TYPE_BUFFER, nil)

    -- Build dependencies
    graph:add_pass("Physics", function() end):using(res_physics, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    graph:add_pass("Shadows", function() end):using(res_shadow, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    graph:add_pass("MainRender", function() end)
        :using(res_physics, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
        :using(res_shadow, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
        :using(res_scene, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    graph:add_pass("UI_Pass", function() end)
        :using(res_ui, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    graph:add_pass("PostProcess", function() end)
        :using(res_scene, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
        :using(res_ui, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- 2. Build Visualization Geometry from Graph data
    local data = graph:get_introspection_data()
    local nodes = ffi.new("VisNode[?]", #data.passes)
    local edges = ffi.new("VisEdge[?]", 20) -- Max expected edges
    local edge_count = 0

    for i, pass in ipairs(data.passes) do
        nodes[i-1].x = (i - (#data.passes/2)) * 4.0
        nodes[i-1].y = math.sin(i) * 2.0
        nodes[i-1].z = 0
        nodes[i-1].r, nodes[i-1].g, nodes[i-1].b = 0.2, 0.8, 0.4
        
        -- Create edges for dependencies (Simplified: find previous pass that used this resource)
        for _, dep in ipairs(pass.deps) do
            for j = 1, i - 1 do
                for _, prev_dep in ipairs(data.passes[j].deps) do
                    if prev_dep.res_id == dep.res_id then
                        edges[edge_count].a = j - 1
                        edges[edge_count].b = i - 1
                        edge_count = edge_count + 1
                        break
                    end
                end
            end
        end
    end

    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 64 * 1024 * 1024)
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 32 * 1024 * 1024)

    node_buf = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size=ffi.sizeof(nodes), usage=bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)}), nil, node_buf)
    local n_alloc = device_heap:malloc(ffi.sizeof(nodes)); vk.vkBindBufferMemory(device, node_buf[0], n_alloc.memory, n_alloc.offset)
    staging.new(physical_device, device, host_heap, 1024*1024):upload_buffer(node_buf[0], nodes, 0, queue, graphics_family)

    edge_buf = ffi.new("VkBuffer[1]"); vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, size=ffi.sizeof(edges), usage=bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)}), nil, edge_buf)
    local e_alloc = device_heap:malloc(ffi.sizeof(edges)); vk.vkBindBufferMemory(device, edge_buf[0], e_alloc.memory, e_alloc.offset)
    staging.new(physical_device, device, host_heap, 1024*1024):upload_buffer(edge_buf[0], edges, 0, queue, graphics_family)
    M.edge_count = edge_count

    -- 3. Descriptors
    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, {bl_layout})[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, node_buf[0], 0, ffi.sizeof(nodes), 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, edge_buf[0], 0, ffi.sizeof(edges), 1)

    -- 4. Pipelines (Reuse MOO shaders but slightly simpler)
    layout_graph = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags=vk.VK_SHADER_STAGE_VERTEX_BIT, offset=0, size=68 }}))
    local vert_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/graph.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/graph.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local edge_vert = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/edge.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local edge_frag = shader.create_module(device, shader.compile_glsl(io.open("examples/10_moo_graph_search/edge.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, vert_mod, frag_mod)
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, edge_vert, edge_frag, { topology=vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive=true })

    -- 5. Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end

    local aspect = sw.extent.width / sw.extent.height
    local proj = math_utils.perspective(math.rad(45), aspect, 0.1, 100.0)
    local view = math_utils.look_at({0, 0, 15}, {0,0,0}, {0,1,0})
    local mvp = math_utils.multiply(proj, view)
    local pc = ffi.new("VisPC"); for i=1,16 do pc.mvp[i-1] = mvp[i] end; pc.mode = 0

    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange=range, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05, 0.05, 0.08, 1.0}
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 68, pc)
    
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges); vk.vkCmdDraw(cb, M.edge_count * 2, 1, 0, 0)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb, 5, 1, 0, 0) -- 5 dummy passes
    
    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
