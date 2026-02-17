local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local resource = require("vulkan.resource")
local sdl = require("vulkan.sdl")
local math_utils = require("examples.15_wavefront_rrt_dubins3d.math")
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

local device, queue, graphics_family
local sw
local pipe_nodes, pipe_edges, pipe_expand, pipe_solution_lines, pipe_solution_points
local layout_graph
local bindless_set

local tree_buf, frontier_curr_buf, frontier_next_buf, stats_buf, solution_curr_buf, solution_prev_buf
local tree_ptr, frontier_curr_ptr, frontier_next_ptr, stats_ptr, solution_curr_ptr, solution_prev_ptr

local image_available
local cbs
local planning_cb
local frame_fence
local iter = 0
local push_const_size = 0
local current_solution_count = 0
local previous_solution_count = 0
local solution_blend = 1.0
local last_goal_idx = 0xFFFFFFFF

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local txt = f:read("*all")
    f:close()
    return txt
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function make_buffer(size, usage)
    local pB = ffi.new("VkBuffer[1]")
    local info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = size,
        usage = usage,
    })
    local res = vk.vkCreateBuffer(device, info, nil, pB)
    if res ~= vk.VK_SUCCESS then
        error("vkCreateBuffer failed: " .. tostring(res))
    end
    return pB[0]
end

local function chaikin_smooth(points)
    local n = #points
    if n < 3 then
        return points
    end

    local out = {}
    out[#out + 1] = points[1]
    for i = 1, n - 1 do
        local a = points[i]
        local b = points[i + 1]
        out[#out + 1] = {
            x = 0.75 * a.x + 0.25 * b.x,
            y = 0.75 * a.y + 0.25 * b.y,
            z = 0.75 * a.z + 0.25 * b.z,
        }
        out[#out + 1] = {
            x = 0.25 * a.x + 0.75 * b.x,
            y = 0.25 * a.y + 0.75 * b.y,
            z = 0.25 * a.z + 0.75 * b.z,
        }
    end
    out[#out + 1] = points[n]
    return out
end

local function write_solution(ptr, points)
    local count = math.min(#points, MAX_SOLUTION_POINTS)
    for i = 1, count do
        local p = points[i]
        ptr[i - 1].x = p.x
        ptr[i - 1].y = p.y
        ptr[i - 1].z = p.z
        ptr[i - 1].w = 0.0
    end
    return count
end

local function rebuild_solution_from_goal(goal_idx)
    if goal_idx == nil or goal_idx == 0xFFFFFFFF then
        return
    end

    previous_solution_count = current_solution_count
    if current_solution_count > 0 then
        ffi.copy(solution_prev_ptr, solution_curr_ptr, ffi.sizeof("PathPoint") * current_solution_count)
    end

    local rev = {}
    local cur = goal_idx
    for _ = 1, MAX_SOLUTION_POINTS do
        if cur == 0xFFFFFFFF then
            break
        end
        local n = tree_ptr[cur]
        rev[#rev + 1] = { x = n.x, y = n.y, z = n.z }
        if cur == 0 then
            break
        end
        cur = n.parent
    end

    local path = {}
    for i = #rev, 1, -1 do
        path[#path + 1] = rev[i]
    end
    path = chaikin_smooth(path)

    current_solution_count = write_solution(solution_curr_ptr, path)
    solution_blend = 0.0
end

local function reset_problem()
    stats_ptr.node_count = 1
    stats_ptr.curr_count = 1
    stats_ptr.next_count = 0
    stats_ptr.goal_idx = 0xFFFFFFFF

    local root = tree_ptr[0]
    root.x = -8.5
    root.y = -2.0
    root.z = -8.5
    root.heading = 0.78
    root.pitch = 0.05
    root.cost = 0.0
    root.parent = 0
    root.flags = 1

    frontier_curr_ptr[0] = 0

    iter = 0
    M.reset_time = M.current_time
    last_goal_idx = 0xFFFFFFFF
end

local function advance_frontier()
    -- On the very first frame, keep the seeded frontier (root node) for expansion.
    if iter == 0 then
        return
    end

    local next_count = tonumber(stats_ptr.next_count)
    if next_count > MAX_FRONTIER then
        next_count = MAX_FRONTIER
    end

    if next_count > 0 then
        for i = 0, next_count - 1 do
            frontier_curr_ptr[i] = frontier_next_ptr[i]
        end
        stats_ptr.curr_count = next_count
        stats_ptr.next_count = 0
    else
        stats_ptr.curr_count = 0
    end
end

function M.init()
    print("Example 15: Wavefront-RRT (3D Dubins Dynamics, single objective)")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct TreeNode {
            float x, y, z, heading;
            float pitch, cost;
            uint32_t parent;
            uint32_t flags;
        } TreeNode;

        typedef struct Stats {
            uint32_t node_count;
            uint32_t curr_count;
            uint32_t next_count;
            uint32_t goal_idx;
        } Stats;

        typedef struct PathPoint {
            float x, y, z, w;
        } PathPoint;

        typedef struct GraphPC {
            float mvp[16];
            float goal_x, goal_y, goal_z, goal_r;
            float sim_t;
            float pad_a, pad_b, pad_c;
            uint32_t node_count;
            uint32_t mode;
            uint32_t obs_count;
            float solution_blend;
        } GraphPC;

        typedef struct ExpandPC {
            uint32_t max_nodes;
            uint32_t max_frontier;
            uint32_t samples_per_frontier;
            uint32_t curr_count;
            float step_dist;
            float max_yaw_delta;
            float max_pitch_delta;
            float sim_t;
            float goal_x, goal_y, goal_z, goal_r;
            uint32_t obs_count;
            uint32_t iter;
            uint32_t pad0;
            uint32_t pad1;
        } ExpandPC;
    ]]

    push_const_size = ffi.sizeof("GraphPC")

    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    local host_heap = heap.new(
        physical_device,
        device,
        heap.find_memory_type(
            physical_device,
            0xFFFFFFFF,
            bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
        ),
        256 * 1024 * 1024
    )

    local tree_size = ffi.sizeof("TreeNode") * MAX_NODES
    local frontier_size = ffi.sizeof("uint32_t") * MAX_FRONTIER
    local stats_size = ffi.sizeof("Stats")
    local path_size = ffi.sizeof("PathPoint") * MAX_SOLUTION_POINTS

    tree_buf = make_buffer(tree_size, bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT))
    frontier_curr_buf = make_buffer(frontier_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    frontier_next_buf = make_buffer(frontier_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    stats_buf = make_buffer(stats_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    solution_curr_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    solution_prev_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)

    local tree_alloc = host_heap:malloc(tree_size)
    local front_a_alloc = host_heap:malloc(frontier_size)
    local front_b_alloc = host_heap:malloc(frontier_size)
    local stats_alloc = host_heap:malloc(stats_size)
    local solution_curr_alloc = host_heap:malloc(path_size)
    local solution_prev_alloc = host_heap:malloc(path_size)

    vk.vkBindBufferMemory(device, tree_buf, tree_alloc.memory, tree_alloc.offset)
    vk.vkBindBufferMemory(device, frontier_curr_buf, front_a_alloc.memory, front_a_alloc.offset)
    vk.vkBindBufferMemory(device, frontier_next_buf, front_b_alloc.memory, front_b_alloc.offset)
    vk.vkBindBufferMemory(device, stats_buf, stats_alloc.memory, stats_alloc.offset)
    vk.vkBindBufferMemory(device, solution_curr_buf, solution_curr_alloc.memory, solution_curr_alloc.offset)
    vk.vkBindBufferMemory(device, solution_prev_buf, solution_prev_alloc.memory, solution_prev_alloc.offset)

    tree_ptr = ffi.cast("TreeNode*", tree_alloc.ptr)
    frontier_curr_ptr = ffi.cast("uint32_t*", front_a_alloc.ptr)
    frontier_next_ptr = ffi.cast("uint32_t*", front_b_alloc.ptr)
    stats_ptr = ffi.cast("Stats*", stats_alloc.ptr)
    solution_curr_ptr = ffi.cast("PathPoint*", solution_curr_alloc.ptr)
    solution_prev_ptr = ffi.cast("PathPoint*", solution_prev_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, tree_buf, 0, tree_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, frontier_curr_buf, 0, frontier_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, frontier_next_buf, 0, frontier_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stats_buf, 0, stats_size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, solution_curr_buf, 0, path_size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, solution_prev_buf, 0, path_size, 5)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT),
        offset = 0,
        size = push_const_size,
    }}))

    local expand_mod = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/expand.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT))
    local graph_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/graph.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local graph_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/graph.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local edge_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/edge.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local edge_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/edge.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local solution_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/solution.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local solution_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/15_wavefront_rrt_dubins3d/solution.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_expand = pipeline.create_compute_pipeline(device, layout_graph, expand_mod)
    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, graph_vert, graph_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, edge_vert, edge_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive = true })
    pipe_solution_lines = pipeline.create_graphics_pipeline(device, layout_graph, solution_vert, solution_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })
    pipe_solution_points = pipeline.create_graphics_pipeline(device, layout_graph, solution_vert, graph_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem)
    image_available = pSem[0]

    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    planning_cb = command.allocate_buffers(device, pool, 1)[1]

    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        flags = vk.VK_FENCE_CREATE_SIGNALED_BIT,
    }), nil, pF)
    frame_fence = pF[0]

    reset_problem()
end

function M.update()
    local ok, err = pcall(function()
        local current_ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = current_ticks - M.last_frame_time
        if elapsed < FRAME_TIME then
            sdl.SDL_Delay(FRAME_TIME - elapsed)
            current_ticks = tonumber(sdl.SDL_GetTicks())
        end
        M.last_frame_time = current_ticks
        M.current_time = M.current_time + 0.016

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        local gx = 4.8
        local gy = 1.0
        local gz = 4.8

        for _ = 1, PLANNING_SUBSTEPS_PER_FRAME do
            advance_frontier()
            local node_count = tonumber(stats_ptr.node_count)
            local goal_idx = tonumber(stats_ptr.goal_idx)
            local curr_count = tonumber(stats_ptr.curr_count)

            if M.current_time - M.reset_time > RESET_INTERVAL or node_count >= (MAX_NODES - 256) or goal_idx ~= 0xFFFFFFFF or curr_count == 0 then
                reset_problem()
                curr_count = tonumber(stats_ptr.curr_count)
            end

            local total_expansions = curr_count * SAMPLES_PER_FRONTIER
            if curr_count > 0 and total_expansions > 0 then
                local epc = ffi.new("ExpandPC", {
                    max_nodes = MAX_NODES,
                    max_frontier = MAX_FRONTIER,
                    samples_per_frontier = SAMPLES_PER_FRONTIER,
                    curr_count = curr_count,
                    step_dist = STEP_DIST,
                    max_yaw_delta = MAX_YAW_DELTA,
                    max_pitch_delta = MAX_PITCH_DELTA,
                    sim_t = M.current_time,
                    goal_x = gx, goal_y = gy, goal_z = gz, goal_r = 1.3,
                    obs_count = OBS_COUNT,
                    iter = iter,
                })

                vk.vkResetCommandBuffer(planning_cb, 0)
                vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
                vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_expand)
                vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
                vk.vkCmdPushConstants(planning_cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("ExpandPC"), epc)
                vk.vkCmdDispatch(planning_cb, math.ceil(total_expansions / 256), 1, 1)
                vk.vkEndCommandBuffer(planning_cb)

                local plan_submit = ffi.new("VkSubmitInfo", {
                    sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                    commandBufferCount = 1,
                    pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }),
                })
                vk.vkQueueSubmit(queue, 1, plan_submit, frame_fence)
                vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
                vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
                iter = iter + 1
            end
        end

        local idx = sw:acquire_next_image(image_available)
        if idx == nil then return end

        local cb = cbs[idx + 1]
        vk.vkResetCommandBuffer(cb, 0)
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        local view = math_utils.look_at({ math.cos(M.angle) * 22.0, 9.0, math.sin(M.angle) * 22.0 }, { 0, 0, 0 }, { 0, 1, 0 })
        local proj = math_utils.perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 100.0)
        local mvp = math_utils.multiply(proj, view)
        M.angle = M.angle + 0.003

        local gpc = ffi.new("GraphPC")
        for i = 1, 16 do gpc.mvp[i - 1] = mvp[i] end
        gpc.goal_x, gpc.goal_y, gpc.goal_z, gpc.goal_r = gx, gy, gz, 1.3
        gpc.sim_t = M.current_time
        gpc.node_count = stats_ptr.node_count
        gpc.obs_count = OBS_COUNT
        gpc.solution_blend = solution_blend

        local goal_idx_now = tonumber(stats_ptr.goal_idx)
        if goal_idx_now ~= 0xFFFFFFFF and goal_idx_now ~= last_goal_idx then
            rebuild_solution_from_goal(goal_idx_now)
            last_goal_idx = goal_idx_now
        end
        if solution_blend < 1.0 then
            solution_blend = math.min(1.0, solution_blend + 0.09)
            gpc.solution_blend = solution_blend
        end

        local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            image = ffi.cast("VkImage", sw.images[idx]),
            subresourceRange = range,
            dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[idx])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32 = { 0.008, 0.008, 0.015, 1.0 }

        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", {
            sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
            renderArea = { extent = sw.extent },
            layerCount = 1,
            colorAttachmentCount = 1,
            pColorAttachments = color_attach,
        }))

        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

        gpc.mode = 1
        vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, gpc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes)
        vk.vkCmdDraw(cb, 1 + OBS_COUNT, 1, 0, 0)

        gpc.mode = 0
        vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, gpc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges)
        local edge_draw = 0
        if stats_ptr.node_count > 1 then
            edge_draw = (stats_ptr.node_count - 1) * 2
        end
        vk.vkCmdDraw(cb, edge_draw, 1, 0, 0)

        if previous_solution_count > 1 then
            gpc.mode = 3
            vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, gpc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_lines)
            vk.vkCmdDraw(cb, previous_solution_count, 1, 0, 0)
        end

        if current_solution_count > 1 then
            gpc.mode = 2
            vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, gpc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_lines)
            vk.vkCmdDraw(cb, current_solution_count, 1, 0, 0)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_solution_points)
            vk.vkCmdDraw(cb, current_solution_count, 1, 0, 0)
        end

        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes)
        vk.vkCmdDraw(cb, stats_ptr.node_count, 1, 0, 0)

        vk.vkCmdEndRendering(cb)

        bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        bar[0].dstAccessMask = 0
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb)

        local submit_info = ffi.new("VkSubmitInfo", {
            sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            waitSemaphoreCount = 1,
            pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }),
            pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }),
            commandBufferCount = 1,
            pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }),
            signalSemaphoreCount = 1,
            pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }),
        })

        vk.vkQueueSubmit(queue, 1, submit_info, frame_fence)
        sw:present(queue, idx, sw.semaphores[idx])
    end)

    if not ok then
        print("M.update: ERROR:", err)
    end
end

return M
