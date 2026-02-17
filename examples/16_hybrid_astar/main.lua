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
local math_utils = require("examples.16_hybrid_astar.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
    last_reset = 0,
}

local FPS_LIMIT = 120
local FRAME_TIME = 1000 / FPS_LIMIT
local RESET_INTERVAL = 16.0

local NX, NY, NZ = 32, 14, 32
local NH, NP = 16, 7
local STATE_COUNT = NX * NY * NZ * NH * NP
local MAX_FRONTIER = 65536
local INF_COST = 0x3FFFFFFF
local SUBSTEPS = 1
local MAX_PATH_POINTS = 4096
local MAX_VIS_POINTS = NX * NY * NZ
local MAX_MARKERS = 48
local VIS_EXTRACT_PERIOD = 8
local SOLUTION_HOLD_TIME = 2.5

local START_X, START_Y, START_Z, START_H, START_P = 3, 2, 3, 2, 3
local GOAL_X, GOAL_Y, GOAL_Z = 27, 11, 27

local device, queue, graphics_family
local sw
local layout_graph
local bindless_set
local pipe_expand, pipe_points, pipe_lines

local cost_buf, parent_buf, open_curr_buf, open_next_buf, occupancy_buf, stats_buf
local vis_buf, path_buf, marker_buf
local cost_ptr, parent_ptr, open_curr_ptr, open_next_ptr, occupancy_ptr, stats_ptr
local vis_ptr, path_ptr, marker_ptr

local image_available
local draw_cbs, planning_cb
local frame_fence

local visited_count = 0
local path_count = 0
local marker_count = 0
local iter = 0
local push_graph_size = 0
local frame_id = 0
local solution_latched = false
local solution_latched_time = 0.0

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local t = f:read("*all")
    f:close()
    return t
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function idx_state(x, y, z, h, p)
    return (((((z * NY + y) * NX + x) * NH + h) * NP) + p)
end

local function decode_state(s)
    local p = s % NP
    s = math.floor(s / NP)
    local h = s % NH
    s = math.floor(s / NH)
    local x = s % NX
    s = math.floor(s / NX)
    local y = s % NY
    local z = math.floor(s / NY)
    return x, y, z, h, p
end

local function world_x(x)
    return ((x / (NX - 1)) - 0.5) * 20.0
end

local function world_y(y)
    return ((y / (NY - 1)) - 0.5) * 10.0
end

local function world_z(z)
    return ((z / (NZ - 1)) - 0.5) * 20.0
end

local function grid_x(xw)
    return clamp(math.floor(((xw / 20.0) + 0.5) * (NX - 1) + 0.5), 0, NX - 1)
end

local function grid_y(yw)
    return clamp(math.floor(((yw / 10.0) + 0.5) * (NY - 1) + 0.5), 0, NY - 1)
end

local function grid_z(zw)
    return clamp(math.floor(((zw / 20.0) + 0.5) * (NZ - 1) + 0.5), 0, NZ - 1)
end

local function occ_idx(x, y, z)
    return (z * NY + y) * NX + x
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

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x = x
    ptr[i].y = y
    ptr[i].z = z
    ptr[i].size = size
    ptr[i].r = r
    ptr[i].g = g
    ptr[i].b = b
    ptr[i].a = a
end

local function reset_search()
    for i = 0, STATE_COUNT - 1 do
        cost_ptr[i] = INF_COST
        parent_ptr[i] = 0xFFFFFFFF
    end
    for i = 0, MAX_FRONTIER - 1 do
        open_curr_ptr[i] = 0
        open_next_ptr[i] = 0
    end

    local sidx = idx_state(START_X, START_Y, START_Z, START_H, START_P)
    cost_ptr[sidx] = 0
    parent_ptr[sidx] = sidx
    open_curr_ptr[0] = sidx

    stats_ptr.curr_count = 1
    stats_ptr.next_count = 0
    stats_ptr.goal_state = 0xFFFFFFFF
    stats_ptr.best_goal_cost = INF_COST
    stats_ptr.expanded = 0

    path_count = 0
    iter = 0
    solution_latched = false
    solution_latched_time = 0.0
    M.last_reset = M.current_time
end

local function update_occupancy(t)
    for i = 0, NX * NY * NZ - 1 do
        occupancy_ptr[i] = 0
    end

    local sx, sy, sz = world_x(START_X), world_y(START_Y), world_z(START_Z)
    local gx, gy, gz = world_x(GOAL_X), world_y(GOAL_Y), world_z(GOAL_Z)

    marker_count = 0
    set_draw_point(marker_ptr, marker_count, sx, sy, sz, 11.0, 0.2, 1.0, 0.3, 1.0); marker_count = marker_count + 1
    set_draw_point(marker_ptr, marker_count, gx, gy, gz, 12.0, 1.0, 1.0, 0.2, 1.0); marker_count = marker_count + 1

    local obs_count = 12
    local vx, vy, vz = gx - sx, gy - sy, gz - sz
    local vlen = math.sqrt(vx * vx + vy * vy + vz * vz)
    if vlen < 1e-6 then vlen = 1 end
    vx, vy, vz = vx / vlen, vy / vlen, vz / vlen

    for i = 0, obs_count - 1 do
        local base = 0.08 + 0.84 * (math.abs(math.sin((i + 1) * 9.173)) % 1.0)
        local along = clamp(base + 0.11 * math.sin(t * (0.33 + 0.03 * i) + i * 0.77), 0.08, 0.92)
        local cx = sx + vx * (vlen * along)
        local cy = sy + vy * (vlen * along)
        local cz = sz + vz * (vlen * along)

        local ox = cx + math.sin(t * (0.49 + 0.05 * i) + i * 0.41) * (1.6 + 0.2 * (i % 3))
        local oy = cy + math.cos(t * (0.43 + 0.04 * i) + i * 1.1) * (1.1 + 0.15 * (i % 2))
        local oz = cz + math.cos(t * (0.53 + 0.02 * i) + i * 0.29) * (1.5 + 0.22 * ((i + 1) % 3))

        local rr = 0.7 + 0.08 * (i % 4)
        set_draw_point(marker_ptr, marker_count, ox, oy, oz, rr * 28.0, 1.0, 0.18, 0.18, 0.95)
        marker_count = marker_count + 1

        local minx, maxx = grid_x(ox - rr), grid_x(ox + rr)
        local miny, maxy = grid_y(oy - rr), grid_y(oy + rr)
        local minz, maxz = grid_z(oz - rr), grid_z(oz + rr)

        for z = minz, maxz do
            local wz = world_z(z)
            for y = miny, maxy do
                local wy = world_y(y)
                for x = minx, maxx do
                    local wx = world_x(x)
                    local dx, dy, dz = wx - ox, wy - oy, wz - oz
                    if dx * dx + dy * dy + dz * dz <= rr * rr then
                        occupancy_ptr[occ_idx(x, y, z)] = 1
                    end
                end
            end
        end
    end
end

local function advance_frontier()
    -- Preserve seeded frontier on first planning frame.
    if iter == 0 then
        return
    end

    local next_count = tonumber(stats_ptr.next_count)
    if next_count > MAX_FRONTIER then next_count = MAX_FRONTIER end
    if next_count <= 0 then
        stats_ptr.curr_count = 0
        return
    end

    for i = 0, next_count - 1 do
        open_curr_ptr[i] = open_next_ptr[i]
    end
    stats_ptr.curr_count = next_count
    stats_ptr.next_count = 0
end

local function extract_visited_points()
    visited_count = 0
    for z = 0, NZ - 1 do
        for y = 0, NY - 1 do
            for x = 0, NX - 1 do
                local best = INF_COST
                for h = 0, NH - 1 do
                    for p = 0, NP - 1 do
                        local c = cost_ptr[idx_state(x, y, z, h, p)]
                        if c < best then best = c end
                    end
                end
                if best < INF_COST and visited_count < MAX_VIS_POINTS then
                    local t = clamp(best / 1400.0, 0.0, 1.0)
                    set_draw_point(vis_ptr, visited_count, world_x(x), world_y(y), world_z(z), 2.0, 0.10, 0.28 + 0.52 * (1.0 - t), 0.82 + 0.16 * (1.0 - t), 0.24)
                    visited_count = visited_count + 1
                end
            end
        end
    end
end

local function smooth_path(points)
    if #points < 3 then return points end
    local out = {}
    out[#out + 1] = points[1]
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        out[#out + 1] = { x = 0.75 * a.x + 0.25 * b.x, y = 0.75 * a.y + 0.25 * b.y, z = 0.75 * a.z + 0.25 * b.z }
        out[#out + 1] = { x = 0.25 * a.x + 0.75 * b.x, y = 0.25 * a.y + 0.75 * b.y, z = 0.25 * a.z + 0.75 * b.z }
    end
    out[#out + 1] = points[#points]
    return out
end

local function extract_path()
    path_count = 0
    local gstate = tonumber(stats_ptr.goal_state)
    if gstate == 0xFFFFFFFF then return end

    local rev = {}
    local cur = gstate
    for _ = 1, MAX_PATH_POINTS do
        local x, y, z = decode_state(cur)
        rev[#rev + 1] = { x = world_x(x), y = world_y(y), z = world_z(z) }
        local p = tonumber(parent_ptr[cur])
        if p == 0xFFFFFFFF or p == cur then break end
        cur = p
    end

    local path = {}
    for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
    path = smooth_path(path)

    for i = 1, math.min(#path, MAX_PATH_POINTS) do
        local p = path[i]
        set_draw_point(path_ptr, i - 1, p.x, p.y, p.z, 6.5, 3.9, 2.8, 0.35, 0.98)
        path_count = path_count + 1
    end
end

function M.init()
    print("Example 16: Hybrid A* 3D (x/y/z + yaw/pitch)")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct Stats {
            uint32_t curr_count;
            uint32_t next_count;
            uint32_t goal_state;
            uint32_t best_goal_cost;
            uint32_t expanded;
        } Stats;

        typedef struct DrawPoint {
            float x, y, z, size;
            float r, g, b, a;
        } DrawPoint;

        typedef struct GraphPC {
            float mvp[16];
            uint32_t mode;
            uint32_t count;
            uint32_t pad0;
            uint32_t pad1;
        } GraphPC;

        typedef struct ExpandPC {
            uint32_t curr_count;
            uint32_t nx;
            uint32_t ny;
            uint32_t nz;
            uint32_t nh;
            uint32_t np;
            uint32_t max_frontier;
            uint32_t goal_x;
            uint32_t goal_y;
            uint32_t goal_z;
            uint32_t iter;
        } ExpandPC;
    ]]

    push_graph_size = ffi.sizeof("GraphPC")

    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    local host_heap = heap.new(
        physical_device,
        device,
        heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)),
        768 * 1024 * 1024
    )

    local cost_size = ffi.sizeof("uint32_t") * STATE_COUNT
    local parent_size = ffi.sizeof("uint32_t") * STATE_COUNT
    local frontier_size = ffi.sizeof("uint32_t") * MAX_FRONTIER
    local occ_size = ffi.sizeof("uint32_t") * (NX * NY * NZ)
    local stats_size = ffi.sizeof("Stats")
    local vis_size = ffi.sizeof("DrawPoint") * MAX_VIS_POINTS
    local path_size = ffi.sizeof("DrawPoint") * MAX_PATH_POINTS
    local marker_size = ffi.sizeof("DrawPoint") * MAX_MARKERS

    cost_buf = make_buffer(cost_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    parent_buf = make_buffer(parent_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    open_curr_buf = make_buffer(frontier_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    open_next_buf = make_buffer(frontier_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    occupancy_buf = make_buffer(occ_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    stats_buf = make_buffer(stats_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    vis_buf = make_buffer(vis_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    path_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    marker_buf = make_buffer(marker_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)

    local cost_alloc = host_heap:malloc(cost_size)
    local parent_alloc = host_heap:malloc(parent_size)
    local curr_alloc = host_heap:malloc(frontier_size)
    local next_alloc = host_heap:malloc(frontier_size)
    local occ_alloc = host_heap:malloc(occ_size)
    local stats_alloc = host_heap:malloc(stats_size)
    local vis_alloc = host_heap:malloc(vis_size)
    local path_alloc = host_heap:malloc(path_size)
    local marker_alloc = host_heap:malloc(marker_size)

    vk.vkBindBufferMemory(device, cost_buf, cost_alloc.memory, cost_alloc.offset)
    vk.vkBindBufferMemory(device, parent_buf, parent_alloc.memory, parent_alloc.offset)
    vk.vkBindBufferMemory(device, open_curr_buf, curr_alloc.memory, curr_alloc.offset)
    vk.vkBindBufferMemory(device, open_next_buf, next_alloc.memory, next_alloc.offset)
    vk.vkBindBufferMemory(device, occupancy_buf, occ_alloc.memory, occ_alloc.offset)
    vk.vkBindBufferMemory(device, stats_buf, stats_alloc.memory, stats_alloc.offset)
    vk.vkBindBufferMemory(device, vis_buf, vis_alloc.memory, vis_alloc.offset)
    vk.vkBindBufferMemory(device, path_buf, path_alloc.memory, path_alloc.offset)
    vk.vkBindBufferMemory(device, marker_buf, marker_alloc.memory, marker_alloc.offset)

    cost_ptr = ffi.cast("uint32_t*", cost_alloc.ptr)
    parent_ptr = ffi.cast("uint32_t*", parent_alloc.ptr)
    open_curr_ptr = ffi.cast("uint32_t*", curr_alloc.ptr)
    open_next_ptr = ffi.cast("uint32_t*", next_alloc.ptr)
    occupancy_ptr = ffi.cast("uint32_t*", occ_alloc.ptr)
    stats_ptr = ffi.cast("Stats*", stats_alloc.ptr)
    vis_ptr = ffi.cast("DrawPoint*", vis_alloc.ptr)
    path_ptr = ffi.cast("DrawPoint*", path_alloc.ptr)
    marker_ptr = ffi.cast("DrawPoint*", marker_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, cost_buf, 0, cost_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, parent_buf, 0, parent_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, open_curr_buf, 0, frontier_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, open_next_buf, 0, frontier_size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, occupancy_buf, 0, occ_size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stats_buf, 0, stats_size, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, vis_buf, 0, vis_size, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, path_buf, 0, path_size, 7)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, marker_buf, 0, marker_size, 8)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT),
        offset = 0,
        size = push_graph_size,
    }}))

    local expand_mod = shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/expand.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT))
    local draw_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local point_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local line_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_expand = pipeline.create_compute_pipeline(device, layout_graph, expand_mod)
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, point_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, line_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem)
    image_available = pSem[0]

    local pool = command.create_pool(device, graphics_family)
    draw_cbs = command.allocate_buffers(device, pool, sw.image_count)
    planning_cb = command.allocate_buffers(device, pool, 1)[1]

    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF)
    frame_fence = pF[0]

    reset_search()
end

function M.update()
    local ok, err = pcall(function()
        frame_id = frame_id + 1
        local ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = ticks - M.last_frame_time
        if elapsed < FRAME_TIME then
            sdl.SDL_Delay(FRAME_TIME - elapsed)
            ticks = tonumber(sdl.SDL_GetTicks())
        end
        M.last_frame_time = ticks
        M.current_time = M.current_time + 0.016

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        update_occupancy(M.current_time)

        if not solution_latched then
        -- Frontier is advanced from results produced in the previous frame.
        advance_frontier()
        local curr_count = tonumber(stats_ptr.curr_count)
        if curr_count > 0 and curr_count <= MAX_FRONTIER then
            local epc = ffi.new("ExpandPC", {
                curr_count = curr_count,
                nx = NX,
                ny = NY,
                nz = NZ,
                nh = NH,
                np = NP,
                max_frontier = MAX_FRONTIER,
                goal_x = GOAL_X,
                goal_y = GOAL_Y,
                goal_z = GOAL_Z,
                iter = iter,
            })

            vk.vkResetCommandBuffer(planning_cb, 0)
            vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
            vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_expand)
            vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
            vk.vkCmdPushConstants(planning_cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("ExpandPC"), epc)
            vk.vkCmdDispatch(planning_cb, math.ceil(curr_count / 256), 1, 1)
            vk.vkEndCommandBuffer(planning_cb)

            local submit_plan = ffi.new("VkSubmitInfo", {
                sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                commandBufferCount = 1,
                pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }),
            })
            -- No blocking wait here: draw submission below is ordered after this on the same queue.
            vk.vkQueueSubmit(queue, 1, submit_plan, ffi.cast("VkFence", 0))
            iter = iter + 1
        end
        end

        if frame_id % VIS_EXTRACT_PERIOD == 0 or solution_latched then
            extract_visited_points()
            extract_path()
        end

        if not solution_latched and tonumber(stats_ptr.goal_state) ~= 0xFFFFFFFF then
            solution_latched = true
            solution_latched_time = M.current_time
            extract_path()
        end

        local should_reset_for_timeout = (M.current_time - M.last_reset > RESET_INTERVAL)
        local should_reset_for_dead_frontier = (tonumber(stats_ptr.curr_count) == 0 and not solution_latched)
        local should_reset_after_solution = (solution_latched and (M.current_time - solution_latched_time) > SOLUTION_HOLD_TIME)
        if should_reset_for_timeout or should_reset_for_dead_frontier or should_reset_after_solution then
            reset_search()
        end

        local idx = sw:acquire_next_image(image_available)
        if idx == nil then return end

        local cb = draw_cbs[idx + 1]
        vk.vkResetCommandBuffer(cb, 0)
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        local view = math_utils.look_at({ math.cos(M.angle) * 24.0, 14.0, math.sin(M.angle) * 24.0 }, { 0, 0, 0 }, { 0, 1, 0 })
        local proj = math_utils.perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 120.0)
        local mvp = math_utils.multiply(proj, view)
        M.angle = M.angle + 0.002

        local gpc = ffi.new("GraphPC")
        for i = 1, 16 do gpc.mvp[i - 1] = mvp[i] end

        local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = range, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[idx])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32 = { 0.01, 0.01, 0.015, 1.0 }

        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

        gpc.mode = 0
        gpc.count = visited_count
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_graph_size, gpc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, visited_count, 1, 0, 0)

        if path_count > 1 then
            gpc.mode = 1
            gpc.count = path_count
            vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_graph_size, gpc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
            vk.vkCmdDraw(cb, path_count, 1, 0, 0)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
            vk.vkCmdDraw(cb, path_count, 1, 0, 0)
        end

        gpc.mode = 2
        gpc.count = marker_count
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_graph_size, gpc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, marker_count, 1, 0, 0)

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
