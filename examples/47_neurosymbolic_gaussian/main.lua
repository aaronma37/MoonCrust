local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")
local input = require("mc.input")
local bit = require("bit")

local M = { cam_pos = {0, 0, 10}, cam_rot = {0, 0}, current_time = 0 }

-- CONFIG
local GAUSSIAN_COUNT = 65536
-- MLP 3 -> 16 -> 9
-- W1: 3x16 (48), B1: 16, W2: 16x9 (144), B2: 9. Total: 217
local WEIGHT_COUNT = 48 + 16 + 144 + 9

local device, queue, graphics_family, sw, pipe_layout, pipe_gen, pipe_project, pipe_sort, pipe_render
local bindless_set, cb, frame_fence, image_available
local weight_buf, g_buffer, p_buffer, s_buffer
local graph, sw_res = {}, {}

ffi.cdef[[
    typedef struct ProjectPC {
        mc_mat4 view;
        mc_mat4 proj;
        float focal_y, focal_x;
        uint32_t g_id, p_id, s_id, count;
    } ProjectPC;

    typedef struct GenPC {
        uint32_t weightBuf, g_id, count;
        float time;
    } GenPC;

    typedef struct SortPC {
        uint32_t buf, j, k;
    } SortPC;

    typedef struct RenderPC {
        uint32_t p_id, s_id;
        float sw, sh;
    } RenderPC;
]]

function M.init()
    print("Example 47: NEURO-SYMBOLIC GAUSSIAN GENERATION")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    -- 1. Initialize Neural Weights (Xavier)
    local w_data = ffi.new("float[?]", WEIGHT_COUNT)
    for i = 0, WEIGHT_COUNT - 1 do
        local scale = (i < 48) and math.sqrt(1.0/3.0) or math.sqrt(1.0/16.0)
        w_data[i] = (math.random() - 0.5) * 2.0 * scale
    end
    weight_buf = mc.buffer(ffi.sizeof(w_data), "storage", w_data)
    g_buffer = mc.buffer(64 * GAUSSIAN_COUNT, "storage") -- sizeof(Gaussian) is 64
    p_buffer = mc.buffer(44 * GAUSSIAN_COUNT, "storage") -- sizeof(Projected) is 44
    s_buffer = mc.buffer(8 * GAUSSIAN_COUNT, "storage")  -- sizeof(SortEntry) is 8

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, weight_buf.handle, 0, weight_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, g_buffer.handle, 0, g_buffer.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, p_buffer.handle, 0, p_buffer.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, s_buffer.handle, 0, s_buffer.size, 3)

    -- 3. Pipelines
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL, offset = 0, size = 256 }}))
    
    pipe_gen = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/47_neurosymbolic_gaussian/generator.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_project = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/47_neurosymbolic_gaussian/project.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_sort = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/47_neurosymbolic_gaussian/sort.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/47_neurosymbolic_gaussian/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), 
        shader.create_module(device, shader.compile_glsl(io.open("examples/47_neurosymbolic_gaussian/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, alpha_blend = true })

    -- 4. Sync
    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available = pS[0]

    -- 5. Render Graph
    local rg = require("vulkan.graph")
    graph = rg.new(device)
    for i=0, sw.image_count-1 do sw_res[i] = graph:register_resource("SW_"..i, rg.TYPE_IMAGE, sw.images[i]) end
    graph.w_buf = graph:register_resource("Weights", rg.TYPE_BUFFER, weight_buf.handle)
    graph.g_buf = graph:register_resource("Gaussians", rg.TYPE_BUFFER, g_buffer.handle)
    graph.p_buf = graph:register_resource("Projected", rg.TYPE_BUFFER, p_buffer.handle)
    graph.s_buf = graph:register_resource("Sort", rg.TYPE_BUFFER, s_buffer.handle)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFF); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    
    input.tick(); M.current_time = M.current_time + 0.016
    
    -- Camera
    local dx, dy = input.mouse_delta()
    if input.mouse_down(3) then 
        M.cam_rot[1] = M.cam_rot[1] - dx * 0.005
        M.cam_rot[2] = math.max(-math.pi/2, math.min(math.pi/2, M.cam_rot[2] - dy * 0.005))
    end
    local fwd = { math.sin(M.cam_rot[1]) * math.cos(M.cam_rot[2]), math.sin(M.cam_rot[2]), -math.cos(M.cam_rot[1]) * math.cos(M.cam_rot[2]) }
    local right = { math.cos(M.cam_rot[1]), 0, math.sin(M.cam_rot[1]) }
    local speed = 10.0 * 0.016; if input.key_down(input.SCANCODE_LSHIFT) then speed = 30.0 * 0.016 end
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + fwd[1]*speed, M.cam_pos[2] + fwd[2]*speed, M.cam_pos[3] + fwd[3]*speed end
    if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - fwd[1]*speed, M.cam_pos[2] - fwd[2]*speed, M.cam_pos[3] - fwd[3]*speed end
    if input.key_down(input.SCANCODE_A) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - right[1]*speed, M.cam_pos[2] - right[2]*speed, M.cam_pos[3] - right[3]*speed end
    if input.key_down(input.SCANCODE_D) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + right[1]*speed, M.cam_pos[2] + right[2]*speed, M.cam_pos[3] + right[3]*speed end

    local view = mc.math.mat4_look_at(M.cam_pos, {M.cam_pos[1] + fwd[1], M.cam_pos[2] + fwd[2], M.cam_pos[3] + fwd[3]}, {0, 1, 0})
    local fov = 70; local aspect = sw.extent.width / sw.extent.height
    local proj = mc.math.mat4_perspective(mc.math.rad(fov), aspect, 0.1, 1000.0)
    local focal_y = sw.extent.height / (2.0 * math.tan(mc.math.rad(fov) * 0.5))
    local focal_x = focal_y

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()
    
    -- Pass 1: NeuroSymbolic Generation
    graph:add_pass("Generate", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 16, ffi.new("GenPC", {0, 1, GAUSSIAN_COUNT, M.current_time}))
        vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
    end):using(graph.w_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(graph.g_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- Pass 2: Projection
    graph:add_pass("Project", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_project)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        local pc = ffi.new("ProjectPC", { view = view, proj = proj, focal_y = focal_y, focal_x = focal_x, g_id = 1, p_id = 2, s_id = 3, count = GAUSSIAN_COUNT })
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, ffi.sizeof("ProjectPC"), pc)
        vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
    end):using(graph.g_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(graph.p_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(graph.s_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- Pass 3: Bitonic Sort
    local num_stages = 0; local temp = GAUSSIAN_COUNT; while temp > 1 do temp = temp / 2; num_stages = num_stages + 1 end
    for stage = 0, num_stages - 1 do for p = stage, 0, -1 do
        graph:add_pass("Sort", function(c)
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sort)
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
            vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 12, ffi.new("SortPC", {3, bit.lshift(1, p), bit.lshift(1, stage + 1)}))
            vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
        end):using(graph.s_buf, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    end end

    -- Pass 4: Render
    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05,0.05,0.1,1}
        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 })); vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 16, ffi.new("RenderPC", { 2, 3, sw.extent.width, sw.extent.height }))
        vk.vkCmdDraw(c, GAUSSIAN_COUNT * 6, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(graph.p_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(graph.s_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(sw_res[idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("Present", function(c) end):using(sw_res[idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
