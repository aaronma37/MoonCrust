local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")

local M = {}

-- SPH CONFIG
local PARTICLE_COUNT = 128 * 1024 
local GRID_SIZE = 0.1

-- State
local device, queue, graphics_family, sw, pipe_hash, pipe_sort, pipe_dens, pipe_force, pipe_render
local bindless_set, cbs, pFenceArr, image_available_sem, frame_fence
local graph, g_swImages = {}, {}
local g_pBuf, g_sBuf

function M.init()
    print("Example 09: FLUID SPH (Full Physics - using mc.gpu StdLib)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct HashPC { uint32_t p_id, s_id, count; float grid; } HashPC;
        typedef struct SortPC { uint32_t buf, j, k; } SortPC;
        typedef struct PhysicsPC { uint32_t p_id, s_id, count; float dt, grid; } PhysicsPC;
        typedef struct RenderPC { float dt; uint32_t buf; } RenderPC;
    ]]

    local p_size = 32 * PARTICLE_COUNT; local s_size = 8 * PARTICLE_COUNT

    -- 1. Initial data for staging
    local initial_data = ffi.new("float[?]", p_size / 4)
    for i = 0, PARTICLE_COUNT - 1 do
        local offset = i * 8
        initial_data[offset+0] = (math.random() * 2.0) - 1.0
        initial_data[offset+1] = (math.random() * 2.0) + 4.0 -- Spawn HIGH (Y+)
        initial_data[offset+2] = (math.random() * 2.0) - 1.0
    end

    -- 2. Use mc.gpu factories
    local particle_buffer = mc.buffer(p_size, "storage", initial_data)
    local sort_buffer = mc.buffer(s_size, "storage")

    -- 3. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer.handle, 0, p_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sort_buffer.handle, 0, s_size, 1)

    -- 4. Pipelines
    M.layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), offset = 0, size = 32 }}))
    pipe_hash = pipeline.create_compute_pipeline(device, M.layout, shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/hash.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_sort = pipeline.create_compute_pipeline(device, M.layout, shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/sort.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_dens = pipeline.create_compute_pipeline(device, M.layout, shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/density.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_force = pipeline.create_compute_pipeline(device, M.layout, shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/force.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, M.layout, shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/09_fluid_sph/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { cull_mode = vk.VK_CULL_MODE_NONE, topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })

    -- 5. Render Graph
    graph = render_graph.new(device)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end
    g_pBuf = graph:register_resource("Particles", render_graph.TYPE_BUFFER, particle_buffer.handle)
    g_sBuf = graph:register_resource("Sort", render_graph.TYPE_BUFFER, sort_buffer.handle)

    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]; pFenceArr = ffi.new("VkFence[1]", {frame_fence})
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available_sem = pS[0]
end

function M.update()
    
    vk.vkWaitForFences(device, 1, pFenceArr, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, pFenceArr)
    local img_idx = sw:acquire_next_image(image_available_sem)
    if not img_idx then return end
    
    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})
    
    graph:reset()
    graph:add_pass("Hash", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_hash)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, M.layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 16, ffi.new("HashPC", {0, 1, PARTICLE_COUNT, GRID_SIZE}))
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(g_sBuf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    local num_stages = 0; local temp = PARTICLE_COUNT; while temp > 1 do temp = temp / 2; num_stages = num_stages + 1 end
    for stage = 0, num_stages - 1 do for pass = stage, 0, -1 do
        graph:add_pass("Sort", function(c)
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sort)
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.layout, 0, 1, pSetsArr, 0, nil)
            vk.vkCmdPushConstants(c, M.layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 12, ffi.new("SortPC", {1, bit.lshift(1, pass), bit.lshift(1, stage + 1)}))
            vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
        end):using(g_sBuf, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    end end

    graph:add_pass("Density", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_dens)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, M.layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 20, ffi.new("PhysicsPC", {0, 1, PARTICLE_COUNT, 0.016, GRID_SIZE}))
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_sBuf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(g_pBuf, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Force", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_force)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, M.layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 20, ffi.new("PhysicsPC", {0, 1, PARTICLE_COUNT, 0.016, GRID_SIZE}))
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_sBuf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(g_pBuf, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32[3] = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 })); vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, M.layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 8, ffi.new("RenderPC", {0.016, 0}))
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT):using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("Present", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence)
    sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
