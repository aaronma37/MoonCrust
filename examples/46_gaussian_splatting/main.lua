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

local M = { cam_pos = {0, 0, 5}, cam_rot = {0, 0}, current_time = 0 }

-- CONFIG
local GAUSSIAN_COUNT = 65536 -- 2^16 for bitonic sort

local device, queue, graphics_family, sw, pipe_layout, pipe_project, pipe_sort, pipe_render
local bindless_set, cb, frame_fence, image_available
local g_buffer, p_buffer, s_buffer
local graph, sw_res = {}, {}

ffi.cdef[[
    typedef struct Gaussian {
        float pos[3]; float opacity;
        float scale[3]; float pad1;
        float rot[4];
        float color[3]; float pad2;
    } Gaussian;

    typedef struct Projected {
        float pos[2];
        float cov[3];
        float color[4];
        float depth;
    } Projected;

    typedef struct SortEntry {
        uint32_t key;
        uint32_t value;
    } SortEntry;

    typedef struct ProjectPC {
        mc_mat4 view;
        mc_mat4 proj;
        float focal_y, focal_x;
        uint32_t g_id, p_id, s_id, count;
    } ProjectPC;

    typedef struct SortPC {
        uint32_t buf, j, k;
    } SortPC;

    typedef struct RenderPC {
        uint32_t p_id, s_id;
        float sw, sh;
    } RenderPC;
]]

function M.init()
    print("Example 46: 3D GAUSSIAN SPLATTING")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    -- 1. Generate Test Data (a sphere of splats)
    local g_data = ffi.new("Gaussian[?]", GAUSSIAN_COUNT)
    for i = 0, GAUSSIAN_COUNT - 1 do
        -- Random sphere position
        local phi = math.acos(2.0 * math.random() - 1.0)
        local theta = 2.0 * math.pi * math.random()
        local r = 2.0 + math.random() * 0.5
        g_data[i].pos[0] = r * math.sin(phi) * math.cos(theta)
        g_data[i].pos[1] = r * math.sin(phi) * math.sin(theta)
        g_data[i].pos[2] = r * math.cos(phi)
        
        g_data[i].opacity = 0.5 + math.random() * 0.5
        g_data[i].scale[0] = 0.02 + math.random() * 0.03
        g_data[i].scale[1] = 0.02 + math.random() * 0.03
        g_data[i].scale[2] = 0.02 + math.random() * 0.03
        
        -- Identity quaternion for now
        g_data[i].rot[0], g_data[i].rot[1], g_data[i].rot[2], g_data[i].rot[3] = 1, 0, 0, 0
        
        -- Rainbow colors
        g_data[i].color[0] = 0.5 + 0.5 * math.cos(theta)
        g_data[i].color[1] = 0.5 + 0.5 * math.sin(theta)
        g_data[i].color[2] = 0.5 + 0.5 * math.sin(phi)
    end

    g_buffer = mc.buffer(ffi.sizeof(g_data), "storage", g_data)
    p_buffer = mc.buffer(ffi.sizeof("Projected") * GAUSSIAN_COUNT, "storage")
    s_buffer = mc.buffer(ffi.sizeof("SortEntry") * GAUSSIAN_COUNT, "storage")

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, g_buffer.handle, 0, g_buffer.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, p_buffer.handle, 0, p_buffer.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, s_buffer.handle, 0, s_buffer.size, 2)

    -- 3. Pipelines
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL, offset = 0, size = 256 }}))
    
    pipe_project = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/46_gaussian_splatting/project.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_sort = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/46_gaussian_splatting/sort.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/46_gaussian_splatting/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), 
        shader.create_module(device, shader.compile_glsl(io.open("examples/46_gaussian_splatting/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, alpha_blend = true })

    -- 4. Sync
    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available = pS[0]

    -- 5. Render Graph
    local rg = require("vulkan.graph")
    graph = rg.new(device)
    for i=0, sw.image_count-1 do sw_res[i] = graph:register_resource("SW_"..i, rg.TYPE_IMAGE, sw.images[i]) end
    graph.g_buf = graph:register_resource("Gaussians", rg.TYPE_BUFFER, g_buffer.handle)
    graph.p_buf = graph:register_resource("Projected", rg.TYPE_BUFFER, p_buffer.handle)
    graph.s_buf = graph:register_resource("Sort", rg.TYPE_BUFFER, s_buffer.handle)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFF); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    
    input.tick(); M.current_time = M.current_time + 0.016
    
    -- Camera Rotation (Mouse)
    local dx, dy = input.mouse_delta()
    if input.mouse_down(3) then -- Right click to rotate
        M.cam_rot[1] = M.cam_rot[1] - dx * 0.005
        M.cam_rot[2] = math.max(-math.pi/2, math.min(math.pi/2, M.cam_rot[2] - dy * 0.005))
    end

    -- Movement Directions
    local fwd = { math.sin(M.cam_rot[1]) * math.cos(M.cam_rot[2]), math.sin(M.cam_rot[2]), -math.cos(M.cam_rot[1]) * math.cos(M.cam_rot[2]) }
    local right = { math.cos(M.cam_rot[1]), 0, math.sin(M.cam_rot[1]) }
    local up_vec = { 0, 1, 0 }

    local speed = 5.0 * 0.016; if input.key_down(input.SCANCODE_LSHIFT) then speed = 15.0 * 0.016 end
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + fwd[1]*speed, M.cam_pos[2] + fwd[2]*speed, M.cam_pos[3] + fwd[3]*speed end
    if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - fwd[1]*speed, M.cam_pos[2] - fwd[2]*speed, M.cam_pos[3] - fwd[3]*speed end
    if input.key_down(input.SCANCODE_A) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - right[1]*speed, M.cam_pos[2] - right[2]*speed, M.cam_pos[3] - right[3]*speed end
    if input.key_down(input.SCANCODE_D) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + right[1]*speed, M.cam_pos[2] + right[2]*speed, M.cam_pos[3] + right[3]*speed end
    if input.key_down(20) then M.cam_pos[2] = M.cam_pos[2] + speed end -- Q (ScanCode 20)
    if input.key_down(8) then M.cam_pos[2] = M.cam_pos[2] - speed end -- E (ScanCode 8)

    local target = { M.cam_pos[1] + fwd[1], M.cam_pos[2] + fwd[2], M.cam_pos[3] + fwd[3] }
    local view = mc.math.mat4_look_at(M.cam_pos, target, up_vec)
    local fov = 70; local aspect = sw.extent.width / sw.extent.height
    local proj = mc.math.mat4_perspective(mc.math.rad(fov), aspect, 0.1, 100.0)
    
    -- Focal lengths for projection
    local focal_y = sw.extent.height / (2.0 * math.tan(mc.math.rad(fov) * 0.5))
    local focal_x = focal_y -- Assume square pixels

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()
    
    -- Pass 1: Projection
    graph:add_pass("Project", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_project)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        local pc = ffi.new("ProjectPC", { view = view, proj = proj, focal_y = focal_y, focal_x = focal_x, g_id = 0, p_id = 1, s_id = 2, count = GAUSSIAN_COUNT })
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, ffi.sizeof("ProjectPC"), pc)
        vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
    end):using(graph.g_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(graph.p_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(graph.s_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- Pass 2: Bitonic Sort (Multiple sub-passes)
    local num_stages = 0; local temp = GAUSSIAN_COUNT; while temp > 1 do temp = temp / 2; num_stages = num_stages + 1 end
    for stage = 0, num_stages - 1 do for pass = stage, 0, -1 do
        graph:add_pass("Sort", function(c)
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sort)
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
            vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 12, ffi.new("SortPC", {2, bit.lshift(1, pass), bit.lshift(1, stage + 1)}))
            vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
        end):using(graph.s_buf, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
    end end

    -- Pass 3: Render
    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0,0,0,1}
        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 })); vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 16, ffi.new("RenderPC", { 1, 2, sw.extent.width, sw.extent.height }))
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
