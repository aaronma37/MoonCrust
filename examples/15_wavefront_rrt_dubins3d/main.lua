local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
    reset_time = 0,
}

local FPS_LIMIT = 240
local FRAME_TIME = 1000 / FPS_LIMIT
local RESET_INTERVAL = 25.0

local MAX_NODES = 90000
local MAX_FRONTIER = 320
local SAMPLES_PER_FRONTIER = 3
local PLANNING_SUBSTEPS_PER_FRAME = 6
local STEP_DIST = 0.36
local MAX_YAW_DELTA = 1.35
local MAX_PITCH_DELTA = 0.70
local OBS_COUNT = 20
local MAX_SOLUTION_POINTS = 2048

local device, queue, graphics_family, sw
local pipe_nodes, pipe_edges, pipe_expand, pipe_solution_lines, pipe_solution_points
local layout_graph, bindless_set
local image_available, cb, planning_cb, frame_fence
local tree_ptr, stats_ptr, solution_curr_ptr, solution_prev_ptr, frontier_next_ptr, frontier_curr_ptr
local iter = 0
local current_solution_count = 0
local previous_solution_count = 0
local solution_blend = 1.0
local last_goal_idx = 0xFFFFFFFF

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local txt = f:read("*all"); f:close()
    return txt
end

local function chaikin_smooth(points)
    local n = #points; if n < 3 then return points end
    local out = { points[1] }
    for i = 1, n - 1 do
        local a, b = points[i], points[i + 1]
        out[#out + 1] = { x = 0.75 * a.x + 0.25 * b.x, y = 0.75 * a.y + 0.25 * b.y, z = 0.75 * a.z + 0.25 * b.z }
        out[#out + 1] = { x = 0.25 * a.x + 0.75 * b.x, y = 0.25 * a.y + 0.75 * b.y, z = 0.25 * a.z + 0.75 * b.z }
    end
    out[#out + 1] = points[n]
    return out
end

local function write_solution(ptr, points)
    local count = math.min(#points, MAX_SOLUTION_POINTS)
    for i = 1, count do local p = points[i]; ptr[i - 1].x, ptr[i - 1].y, ptr[i - 1].z, ptr[i - 1].w = p.x, p.y, p.z, 0.0 end
    return count
end

local function rebuild_solution_from_goal(goal_idx)
    if goal_idx == nil or goal_idx == 0xFFFFFFFF then return end
    previous_solution_count = current_solution_count
    if current_solution_count > 0 then ffi.copy(solution_prev_ptr, solution_curr_ptr, ffi.sizeof("PathPoint") * current_solution_count) end
    local rev = {}; local cur = goal_idx
    for _ = 1, MAX_SOLUTION_POINTS do
        if cur == 0xFFFFFFFF then break end
        local n = tree_ptr[cur]; rev[#rev + 1] = { x = n.x, y = n.y, z = n.z }
        if cur == 0 then break end
        cur = n.parent
    end
    local path = {}; for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
    current_solution_count = write_solution(solution_curr_ptr, chaikin_smooth(path)); solution_blend = 0.0
end

local function reset_problem()
    stats_ptr.node_count, stats_ptr.curr_count, stats_ptr.next_count, stats_ptr.goal_idx = 1, 1, 0, 0xFFFFFFFF
    local root = tree_ptr[0]
    root.x, root.y, root.z, root.heading, root.pitch, root.cost, root.parent, root.flags = -8.5, -2.0, -8.5, 0.78, 0.05, 0.0, 0, 1
    frontier_curr_ptr[0] = 0; iter = 0; M.reset_time = M.current_time; last_goal_idx = 0xFFFFFFFF
end

local function advance_frontier()
    if iter == 0 then return end
    local next_count = tonumber(stats_ptr.next_count); if next_count > MAX_FRONTIER then next_count = MAX_FRONTIER end
    if next_count > 0 then
        for i = 0, next_count - 1 do frontier_curr_ptr[i] = frontier_next_ptr[i] end
        stats_ptr.curr_count, stats_ptr.next_count = next_count, 0
    else stats_ptr.curr_count = 0 end
end

function M.init()
    print("Example 15: Wavefront-RRT (using mc.gpu StdLib)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct TreeNode { float x, y, z, heading, pitch, cost; uint32_t parent, flags; } TreeNode;
        typedef struct Stats { uint32_t node_count, curr_count, next_count, goal_idx; } Stats;
        typedef struct PathPoint { float x, y, z, w; } PathPoint;
        typedef struct GraphPC { float mvp[16], goal_x, goal_y, goal_z, goal_r, sim_t, pad_a, pad_b, pad_c; uint32_t node_count, mode, obs_count; float solution_blend; } GraphPC;
        typedef struct ExpandPC { uint32_t max_nodes, max_frontier, samples_per_frontier, curr_count; float step_dist, max_yaw_delta, max_pitch_delta, sim_t, goal_x, goal_y, goal_z, goal_r; uint32_t obs_count, iter, pad0, pad1; } ExpandPC;
    ]]

    -- 1. Use mc.buffer factories
    local tree_size, frontier_size, stats_size, path_size = ffi.sizeof("TreeNode") * MAX_NODES, ffi.sizeof("uint32_t") * MAX_FRONTIER, ffi.sizeof("Stats"), ffi.sizeof("PathPoint") * MAX_SOLUTION_POINTS
    local b_tree = mc.buffer(tree_size, "storage", nil, true)
    local b_f_curr = mc.buffer(frontier_size, "storage", nil, true)
    local b_f_next = mc.buffer(frontier_size, "storage", nil, true)
    local b_stats = mc.buffer(stats_size, "storage", nil, true)
    local b_s_curr = mc.buffer(path_size, "storage", nil, true)
    local b_s_prev = mc.buffer(path_size, "storage", nil, true)

    tree_ptr, frontier_curr_ptr, frontier_next_ptr, stats_ptr, solution_curr_ptr, solution_prev_ptr = ffi.cast("TreeNode*", b_tree.allocation.ptr), ffi.cast("uint32_t*", b_f_curr.allocation.ptr), ffi.cast("uint32_t*", b_f_next.allocation.ptr), ffi.cast("Stats*", b_stats.allocation.ptr), ffi.cast("PathPoint*", b_s_curr.allocation.ptr), ffi.cast("PathPoint*", b_s_prev.allocation.ptr)

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_tree.handle, 0, tree_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_f_curr.handle, 0, frontier_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_f_next.handle, 0, frontier_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_stats.handle, 0, stats_size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_s_curr.handle, 0, path_size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_s_prev.handle, 0, path_size, 5)

    -- 3. Pipelines
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("GraphPC") }}))
    pipe_expand = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/expand.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/graph.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/graph.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/edge.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/edge.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive = true })
    pipe_solution_lines = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/solution.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/solution.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })
    pipe_solution_points = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/solution.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/graph.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })

    -- 4. Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cb, planning_cb = command.allocate_buffers(device, pool, 1)[1], command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    reset_problem()
end

function M.update()
    
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    M.current_time = M.current_time + 0.016
    local gx, gy, gz = 4.8, 1.0, 4.8
    for _ = 1, PLANNING_SUBSTEPS_PER_FRAME do
        advance_frontier()
        local node_count, goal_idx, curr_count = tonumber(stats_ptr.node_count), tonumber(stats_ptr.goal_idx), tonumber(stats_ptr.curr_count)
        if M.current_time - M.reset_time > RESET_INTERVAL or node_count >= (MAX_NODES - 256) or goal_idx ~= 0xFFFFFFFF or curr_count == 0 then reset_problem(); curr_count = tonumber(stats_ptr.curr_count) end
        local total_exp = curr_count * SAMPLES_PER_FRONTIER
        if curr_count > 0 and total_exp > 0 then
            local epc = ffi.new("ExpandPC", { max_nodes = MAX_NODES, max_frontier = MAX_FRONTIER, samples_per_frontier = SAMPLES_PER_FRONTIER, curr_count = curr_count, step_dist = STEP_DIST, max_yaw_delta = MAX_YAW_DELTA, max_pitch_delta = MAX_PITCH_DELTA, sim_t = M.current_time, goal_x = gx, goal_y = gy, goal_z = gz, goal_r = 1.3, obs_count = OBS_COUNT, iter = iter })
            vk.vkResetCommandBuffer(planning_cb, 0); vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
            vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_expand); vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil); vk.vkCmdPushConstants(planning_cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("ExpandPC"), epc); vk.vkCmdDispatch(planning_cb, math.ceil(total_exp / 256), 1, 1); vk.vkEndCommandBuffer(planning_cb)
            vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }) }), frame_fence); vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence })); iter = iter + 1
        end
    end
    local img_idx = sw:acquire_next_image(image_available); if img_idx == nil then return end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local view = mc.mat4_look_at({ math.cos(M.angle) * 22.0, 9.0, math.sin(M.angle) * 22.0 }, { 0, 0, 0 }, { 0, 1, 0 })
    local proj = mc.mat4_perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 100.0)
    local mvp = mc.mat4_multiply(proj, view); M.angle = M.angle + 0.003
    local gpc = ffi.new("GraphPC"); for i = 1, 16 do gpc.mvp[i - 1] = mvp.m[i - 1] end
    gpc.goal_x, gpc.goal_y, gpc.goal_z, gpc.goal_r, gpc.sim_t, gpc.node_count, gpc.obs_count, gpc.solution_blend = gx, gy, gz, 1.3, M.current_time, stats_ptr.node_count, OBS_COUNT, solution_blend
    local goal_now = tonumber(stats_ptr.goal_idx); if goal_now ~= 0xFFFFFFFF and goal_now ~= last_goal_idx then rebuild_solution_from_goal(goal_now); last_goal_idx = goal_now end
    if solution_blend < 1.0 then solution_blend = math.min(1.0, solution_blend + 0.09); gpc.solution_blend = solution_blend end
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[img_idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.008, 0.008, 0.015, 1.0 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent })); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    gpc.mode = 1; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb, 1 + OBS_COUNT, 1, 0, 0)
    gpc.mode = 0; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges); vk.vkCmdDraw(cb, stats_ptr.node_count > 1 and (stats_ptr.node_count - 1) * 2 or 0, 1, 0, 0)
    if previous_solution_count > 1 then gpc.mode = 3; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_lines); vk.vkCmdDraw(cb, previous_solution_count, 1, 0, 0) end
    if current_solution_count > 1 then gpc.mode = 2; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_lines); vk.vkCmdDraw(cb, current_solution_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_points); vk.vkCmdDraw(cb, current_solution_count, 1, 0, 0) end
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes); vk.vkCmdDraw(cb, stats_ptr.node_count, 1, 0, 0); vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[img_idx] }) }), frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
