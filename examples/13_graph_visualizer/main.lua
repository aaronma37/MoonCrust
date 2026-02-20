local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")

local M = { angle = 0 }

local device, queue, graphics_family, sw, graph
local pipe_nodes, pipe_edges, pipe_text, layout_graph
local bindless_set, image_available_sem, frame_fence, cb

function M.init()
    print("Example 13: RENDER GRAPH VISUALIZER (using mc.gpu StdLib)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct VisNode { float x, y, z, p1; float r, g, b, p2; } VisNode;
        typedef struct VisEdge { uint32_t a, b; } VisEdge;
        typedef struct VisPC { float mvp[16]; uint32_t mode; float tx, ty, tz; } VisPC;
    ]]

    graph = render_graph.new(device)
    local res_physics = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, nil)
    local res_shadow = graph:register_resource("ShadowMap", render_graph.TYPE_IMAGE, nil)
    local res_scene = graph:register_resource("SceneColor", render_graph.TYPE_IMAGE, nil)
    local res_ui = graph:register_resource("UIBuffer", render_graph.TYPE_BUFFER, nil)

    graph:add_pass("Physics", function() end):using(res_physics, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    graph:add_pass("Shadows", function() end):using(res_shadow, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    graph:add_pass("MainRender", function() end):using(res_physics, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT):using(res_shadow, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL):using(res_scene, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    graph:add_pass("UI_Pass", function() end):using(res_ui, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    graph:add_pass("PostProcess", function() end):using(res_scene, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL):using(res_ui, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    local data = graph:get_introspection_data()
    M.node_data = ffi.new("VisNode[?]", #data.passes)
    local edge_list = ffi.new("VisEdge[?]", 20)
    local edge_count = 0

    for i, pass in ipairs(data.passes) do
        M.node_data[i-1].x = (i - (#data.passes/2) - 0.5) * 4.0
        M.node_data[i-1].y = math.sin(i * 1.5) * 2.0
        M.node_data[i-1].z = 0
        M.node_data[i-1].r, M.node_data[i-1].g, M.node_data[i-1].b = 0.2, 0.8, 0.4
        for _, dep in ipairs(pass.deps) do
            for j = 1, i - 1 do
                for _, prev_dep in ipairs(data.passes[j].deps) do
                    if prev_dep.res_id == dep.res_id then
                        edge_list[edge_count].a = j - 1
                        edge_list[edge_count].b = i - 1
                        edge_count = edge_count + 1
                        break
                    end
                end
            end
        end
    end

    -- 1. Use mc.buffer factory
    local node_buffer = mc.buffer(ffi.sizeof(M.node_data), "storage", M.node_data)
    local edge_buffer = mc.buffer(ffi.sizeof(edge_list), "storage", edge_list)
    M.edge_count = edge_count
    M.node_count = #data.passes

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, node_buffer.handle, 0, ffi.sizeof(M.node_data), 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, edge_buffer.handle, 0, ffi.sizeof(edge_list), 1)

    -- 3. Pipelines
    layout_graph = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags=bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset=0, size = 84 }}))
    local vs = shader.create_module(device, shader.compile_glsl(io.open("examples/13_graph_visualizer/vis.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local fs = shader.create_module(device, shader.compile_glsl(io.open("examples/13_graph_visualizer/vis.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local tvs = shader.create_module(device, shader.compile_glsl(io.open("examples/13_graph_visualizer/text.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local tfs = shader.create_module(device, shader.compile_glsl(io.open("examples/13_graph_visualizer/text.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, vs, fs, { topology=vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, vs, fs, { topology=vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive = true })
    pipe_text = pipeline.create_graphics_pipeline(device, layout_graph, tvs, tfs, { topology=vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, additive = true })

    -- 4. Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
end

function M.update()
    
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    local aspect = sw.extent.width / sw.extent.height
    local proj = mc.mat4_perspective(mc.rad(45), aspect, 0.1, 100.0)
    local view = mc.mat4_look_at({0, 0, 20}, {0,0,0}, {0,1,0})
    local mvp = mc.mat4_multiply(proj, view)
    local pc = ffi.new("VisPC"); for i=1,16 do pc.mvp[i-1] = mvp.m[i-1] end

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange=range, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color.float32 = {0.02, 0.02, 0.04, 1.0}
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    
    -- Edges
    pc.mode = 1
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, pc)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges); vk.vkCmdDraw(cb, M.edge_count * 2, 1, 0, 0)

    -- Nodes
    pc.mode = 0
    vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, pc)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb, M.node_count, 1, 0, 0)
    
    -- Positioned Text
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_text)
    for i=0, 2 do
        pc.mode = i
        pc.tx, pc.ty, pc.tz = M.node_data[i].x, M.node_data[i].y, M.node_data[i].z
        vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 84, pc)
        vk.vkCmdDraw(cb, 3, 1, 0, 0)
    end

    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
