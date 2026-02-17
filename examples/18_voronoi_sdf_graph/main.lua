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
local math_utils = require("examples.18_voronoi_sdf_graph.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
    last_rebuild = 0,
}

local FPS_LIMIT = 60
local FRAME_TIME = 1000 / FPS_LIMIT
local REBUILD_INTERVAL = 0.25

local NX, NY, NZ = 52, 26, 52
local X_EXTENT, Y_EXTENT, Z_EXTENT = 20.0, 10.0, 20.0
local SITE_COUNT = 180
local MAX_VORONOI_POINTS = NX * NY * NZ
local MAX_PATH_POINTS = 8192
local MAX_MARKERS = 320

local START = { x = -8.6, y = -2.3, z = -8.6 }
local GOAL = { x = 8.4, y = 2.2, z = 8.4 }

local device, queue, graphics_family
local sw
local layout_graph
local bindless_set
local pipe_points, pipe_lines

local voronoi_buf, path_buf, marker_buf
local voronoi_ptr, path_ptr, marker_ptr
local voronoi_count = 0
local path_count = 0
local marker_count = 0

local image_available
local cbs
local frame_fence
local push_size = 0

local sites = {}
local SITE_MARGIN = 0.25
local START_GOAL_CLEARANCE = 1.35
local SITE_SPEED_SCALE = 3.0
local SITE_SWAY_SCALE = 1.2

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

local function world_x(ix)
    return ((ix / (NX - 1)) - 0.5) * X_EXTENT
end

local function world_y(iy)
    return ((iy / (NY - 1)) - 0.5) * Y_EXTENT
end

local function world_z(iz)
    return ((iz / (NZ - 1)) - 0.5) * Z_EXTENT
end

local function grid_x(x)
    return clamp(math.floor(((x / X_EXTENT) + 0.5) * (NX - 1) + 0.5), 0, NX - 1)
end

local function grid_y(y)
    return clamp(math.floor(((y / Y_EXTENT) + 0.5) * (NY - 1) + 0.5), 0, NY - 1)
end

local function grid_z(z)
    return clamp(math.floor(((z / Z_EXTENT) + 0.5) * (NZ - 1) + 0.5), 0, NZ - 1)
end

local function idx3(x, y, z)
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
    if res ~= vk.VK_SUCCESS then error("vkCreateBuffer failed: " .. tostring(res)) end
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

local function sdf_to_sites(px, py, pz)
    local best = 1e9
    local best_i = -1
    for i = 1, #sites do
        local s = sites[i]
        local dx, dy, dz = px - s.x, py - s.y, pz - s.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz) - s.r
        if d < best then
            best = d
            best_i = i
        end
    end
    return best, best_i
end

local function segment_clear(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    local n = math.max(2, math.floor(len / 0.25))
    for i = 0, n do
        local t = i / n
        local x = a.x + dx * t
        local y = a.y + dy * t
        local z = a.z + dz * t
        local sdf = sdf_to_sites(x, y, z)
        if sdf < 0.02 then
            return false
        end
    end
    return true
end

local function keep_site_clear_of_endpoints(s)
    local function push_from(p)
        local dx, dy, dz = s.x - p.x, s.y - p.y, s.z - p.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz)
        if d < START_GOAL_CLEARANCE then
            local ux, uy, uz = 1.0, 0.0, 0.0
            if d > 1e-5 then
                ux, uy, uz = dx / d, dy / d, dz / d
            end
            local push = START_GOAL_CLEARANCE - d
            s.x = s.x + ux * push
            s.y = s.y + uy * push
            s.z = s.z + uz * push
        end
    end
    push_from(START)
    push_from(GOAL)
end

local function nudge_site_from_endpoints(s, dt)
    local function nudge_from(p)
        local dx, dy, dz = s.x - p.x, s.y - p.y, s.z - p.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz)
        local ux, uy, uz = 1.0, 0.0, 0.0
        if d > 1e-5 then
            ux, uy, uz = dx / d, dy / d, dz / d
        end

        local influence = START_GOAL_CLEARANCE + 0.8
        if d < influence then
            local t = 1.0 - (d / influence)
            local accel = 2.4 * t
            s.vx = s.vx + ux * accel * dt
            s.vy = s.vy + uy * accel * dt
            s.vz = s.vz + uz * accel * dt
        end

        if d < START_GOAL_CLEARANCE then
            local push = START_GOAL_CLEARANCE - d
            local max_step = 1.1 * dt
            local step = math.min(push, max_step)
            s.x = s.x + ux * step
            s.y = s.y + uy * step
            s.z = s.z + uz * step
        end
    end

    nudge_from(START)
    nudge_from(GOAL)
end

local function clamp_site_in_bounds(s)
    local min_x, max_x = -X_EXTENT * 0.5 + s.r + SITE_MARGIN, X_EXTENT * 0.5 - s.r - SITE_MARGIN
    local min_y, max_y = -Y_EXTENT * 0.5 + s.r + SITE_MARGIN, Y_EXTENT * 0.5 - s.r - SITE_MARGIN
    local min_z, max_z = -Z_EXTENT * 0.5 + s.r + SITE_MARGIN, Z_EXTENT * 0.5 - s.r - SITE_MARGIN
    s.x = clamp(s.x, min_x, max_x)
    s.y = clamp(s.y, min_y, max_y)
    s.z = clamp(s.z, min_z, max_z)
end

local function init_sites()
    sites = {}
    for i = 1, SITE_COUNT do
        local phase = i * 1.37
        local x = math.sin(phase * 0.93) * 7.8
        local y = math.cos(phase * 1.11) * 3.2
        local z = math.cos(phase * 0.79) * 7.8
        local r = 0.58 + 0.14 * (i % 4)
        local vx = (0.22 + 0.03 * (i % 5)) * SITE_SPEED_SCALE
        local vy = (0.15 + 0.02 * (i % 4)) * SITE_SPEED_SCALE
        local vz = (0.24 + 0.025 * (i % 6)) * SITE_SPEED_SCALE
        if (i % 2) == 0 then vx = -vx end
        if (i % 3) == 0 then vy = -vy end
        if (i % 5) == 0 then vz = -vz end
        local s = {
            x = x, y = y, z = z, r = r, vx = vx, vy = vy, vz = vz,
            p1 = phase * 0.73, p2 = phase * 0.57, p3 = phase * 0.91,
        }
        keep_site_clear_of_endpoints(s)
        clamp_site_in_bounds(s)
        sites[#sites + 1] = s
    end
end

local function update_sites(dt)
    for i = 1, #sites do
        local s = sites[i]
        local sway_t = M.current_time
        local sx = math.sin(sway_t * 1.6 + s.p1) * SITE_SWAY_SCALE
        local sy = math.cos(sway_t * 1.9 + s.p2) * SITE_SWAY_SCALE * 0.85
        local sz = math.sin(sway_t * 1.4 + s.p3) * SITE_SWAY_SCALE
        s.x = s.x + (s.vx + sx) * dt
        s.y = s.y + (s.vy + sy) * dt
        s.z = s.z + (s.vz + sz) * dt

        local min_x, max_x = -X_EXTENT * 0.5 + s.r + SITE_MARGIN, X_EXTENT * 0.5 - s.r - SITE_MARGIN
        local min_y, max_y = -Y_EXTENT * 0.5 + s.r + SITE_MARGIN, Y_EXTENT * 0.5 - s.r - SITE_MARGIN
        local min_z, max_z = -Z_EXTENT * 0.5 + s.r + SITE_MARGIN, Z_EXTENT * 0.5 - s.r - SITE_MARGIN

        if s.x < min_x then s.x = min_x; s.vx = math.abs(s.vx) end
        if s.x > max_x then s.x = max_x; s.vx = -math.abs(s.vx) end
        if s.y < min_y then s.y = min_y; s.vy = math.abs(s.vy) end
        if s.y > max_y then s.y = max_y; s.vy = -math.abs(s.vy) end
        if s.z < min_z then s.z = min_z; s.vz = math.abs(s.vz) end
        if s.z > max_z then s.z = max_z; s.vz = -math.abs(s.vz) end

        nudge_site_from_endpoints(s, dt)
        clamp_site_in_bounds(s)
    end
end

local function refresh_markers()
    marker_count = 0
    set_draw_point(marker_ptr, marker_count, START.x, START.y, START.z, 11.0, 0.2, 1.0, 0.3, 1.0); marker_count = marker_count + 1
    set_draw_point(marker_ptr, marker_count, GOAL.x, GOAL.y, GOAL.z, 12.0, 1.0, 1.0, 0.2, 1.0); marker_count = marker_count + 1
    for i = 1, #sites do
        if marker_count >= MAX_MARKERS then break end
        local s = sites[i]
        set_draw_point(marker_ptr, marker_count, s.x, s.y, s.z, s.r * 30.0, 1.0, 0.18, 0.18, 0.92)
        marker_count = marker_count + 1
    end
end

local function build_voronoi_graph_and_path()
    local voxel_count = NX * NY * NZ
    local clearance = {}
    local label = {}
    local free = {}

    for z = 0, NZ - 1 do
        local wz = world_z(z)
        for y = 0, NY - 1 do
            local wy = world_y(y)
            for x = 0, NX - 1 do
                local wx = world_x(x)
                local sdf, site_i = sdf_to_sites(wx, wy, wz)
                local id = idx3(x, y, z)
                clearance[id] = sdf
                label[id] = site_i
                free[id] = sdf > 0.03
            end
        end
    end

    local is_v = {}
    local vnodes = {}
    local node_of = {}
    local dirs = {
        {1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1},
    }

    for z = 1, NZ - 2 do
        for y = 1, NY - 2 do
            for x = 1, NX - 2 do
                local id = idx3(x, y, z)
                if free[id] and clearance[id] > 0.12 then
                    local site_set = {}
                    local distinct = 0
                    local mylab = label[id]
                    site_set[mylab] = true
                    for _, d in ipairs(dirs) do
                        local nx, ny, nz = x + d[1], y + d[2], z + d[3]
                        local nid = idx3(nx, ny, nz)
                        if free[nid] then
                            local lab = label[nid]
                            if not site_set[lab] then
                                site_set[lab] = true
                                distinct = distinct + 1
                            end
                        end
                    end
                    if distinct >= 1 then
                        is_v[id] = true
                        local nidx = #vnodes + 1
                        node_of[id] = nidx
                        vnodes[nidx] = { x = x, y = y, z = z, id = id }
                    end
                end
            end
        end
    end

    local adj = {}
    for i = 1, #vnodes do adj[i] = {} end
    for i = 1, #vnodes do
        local v = vnodes[i]
        for _, d in ipairs(dirs) do
            local nx, ny, nz = v.x + d[1], v.y + d[2], v.z + d[3]
            if nx >= 0 and ny >= 0 and nz >= 0 and nx < NX and ny < NY and nz < NZ then
                local nid = idx3(nx, ny, nz)
                local j = node_of[nid]
                if j then
                    adj[i][#adj[i] + 1] = j
                end
            end
        end
    end

    local function nearest_voronoi_point(p)
        local best_i, best_d = -1, 1e9
        for i = 1, #vnodes do
            local v = vnodes[i]
            local wx, wy, wz = world_x(v.x), world_y(v.y), world_z(v.z)
            local dx, dy, dz = wx - p.x, wy - p.y, wz - p.z
            local dd = dx * dx + dy * dy + dz * dz
            if dd < best_d then
                local cand = { x = wx, y = wy, z = wz }
                if segment_clear(p, cand) then
                    best_d = dd
                    best_i = i
                end
            end
        end
        return best_i
    end

    local s_idx = nearest_voronoi_point(START)
    local g_idx = nearest_voronoi_point(GOAL)

    local path_nodes = {}
    if s_idx ~= -1 and g_idx ~= -1 then
        local parent = {}
        local seen = {}
        local q = { s_idx }
        local head = 1
        seen[s_idx] = true
        parent[s_idx] = -1

        while head <= #q do
            local u = q[head]
            head = head + 1
            if u == g_idx then break end
            local nbrs = adj[u]
            for i = 1, #nbrs do
                local v = nbrs[i]
                if not seen[v] then
                    seen[v] = true
                    parent[v] = u
                    q[#q + 1] = v
                end
            end
        end

        if seen[g_idx] then
            local cur = g_idx
            while cur ~= -1 do
                path_nodes[#path_nodes + 1] = cur
                cur = parent[cur] or -1
            end
            local rev = {}
            for i = #path_nodes, 1, -1 do rev[#rev + 1] = path_nodes[i] end
            path_nodes = rev
        end
    end

    voronoi_count = 0
    for i = 1, math.min(#vnodes, MAX_VORONOI_POINTS) do
        local v = vnodes[i]
        local wx, wy, wz = world_x(v.x), world_y(v.y), world_z(v.z)
        set_draw_point(voronoi_ptr, voronoi_count, wx, wy, wz, 2.3, 0.12, 0.45, 0.95, 0.28)
        voronoi_count = voronoi_count + 1
    end

    local function simplify_los(points)
        if #points <= 2 then
            return points
        end
        local out = { points[1] }
        local i = 1
        while i < #points do
            local best_j = i + 1
            for j = i + 2, #points do
                if segment_clear(points[i], points[j]) then
                    best_j = j
                else
                    break
                end
            end
            out[#out + 1] = points[best_j]
            i = best_j
        end
        return out
    end

    local new_path = {}
    if #path_nodes > 0 then
        local route = { { x = START.x, y = START.y, z = START.z } }
        for i = 1, #path_nodes do
            local v = vnodes[path_nodes[i]]
            route[#route + 1] = { x = world_x(v.x), y = world_y(v.y), z = world_z(v.z) }
        end
        route[#route + 1] = { x = GOAL.x, y = GOAL.y, z = GOAL.z }
        route = simplify_los(route)

        for i = 1, math.min(#route, MAX_PATH_POINTS) do
            local p = route[i]
            new_path[#new_path + 1] = { x = p.x, y = p.y, z = p.z, s = (i == 1 or i == #route) and 7.0 or 6.2 }
        end
    elseif segment_clear(START, GOAL) then
        new_path[#new_path + 1] = { x = START.x, y = START.y, z = START.z, s = 7.0 }
        new_path[#new_path + 1] = { x = GOAL.x, y = GOAL.y, z = GOAL.z, s = 7.0 }
    end

    -- Keep last valid path if this rebuild has no feasible route.
    if #new_path > 1 then
        path_count = 0
        for i = 1, #new_path do
            local p = new_path[i]
            set_draw_point(path_ptr, path_count, p.x, p.y, p.z, p.s, 3.8, 2.8, 0.35, 0.95)
            path_count = path_count + 1
        end
    end

    refresh_markers()
end

local function rebuild_graph_scene()
    build_voronoi_graph_and_path()
    M.last_rebuild = M.current_time
end

function M.init()
    print("Example 18: 3D Voronoi Partition Graph from SDF Sites")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct DrawPoint { float x, y, z, size; float r, g, b, a; } DrawPoint;
        typedef struct DrawPC { float mvp[16]; uint32_t mode; uint32_t count; uint32_t pad0; uint32_t pad1; } DrawPC;
    ]]

    push_size = ffi.sizeof("DrawPC")

    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    local host_heap = heap.new(
        physical_device,
        device,
        heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)),
        256 * 1024 * 1024
    )

    local voronoi_size = ffi.sizeof("DrawPoint") * MAX_VORONOI_POINTS
    local path_size = ffi.sizeof("DrawPoint") * MAX_PATH_POINTS
    local marker_size = ffi.sizeof("DrawPoint") * MAX_MARKERS

    voronoi_buf = make_buffer(voronoi_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    path_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    marker_buf = make_buffer(marker_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)

    local v_alloc = host_heap:malloc(voronoi_size)
    local p_alloc = host_heap:malloc(path_size)
    local m_alloc = host_heap:malloc(marker_size)

    vk.vkBindBufferMemory(device, voronoi_buf, v_alloc.memory, v_alloc.offset)
    vk.vkBindBufferMemory(device, path_buf, p_alloc.memory, p_alloc.offset)
    vk.vkBindBufferMemory(device, marker_buf, m_alloc.memory, m_alloc.offset)

    voronoi_ptr = ffi.cast("DrawPoint*", v_alloc.ptr)
    path_ptr = ffi.cast("DrawPoint*", p_alloc.ptr)
    marker_ptr = ffi.cast("DrawPoint*", m_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, voronoi_buf, 0, voronoi_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, path_buf, 0, path_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, marker_buf, 0, marker_size, 2)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = push_size }}))

    local draw_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local point_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local line_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, point_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, line_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem)
    image_available = pSem[0]

    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)

    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF)
    frame_fence = pF[0]

    init_sites()
    rebuild_graph_scene()
end

function M.update()
    local ok, err = pcall(function()
        local ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = ticks - M.last_frame_time
        if M.last_frame_time == 0 then
            elapsed = FRAME_TIME
        end
        if elapsed < FRAME_TIME then
            sdl.SDL_Delay(FRAME_TIME - elapsed)
            ticks = tonumber(sdl.SDL_GetTicks())
        end
        elapsed = ticks - M.last_frame_time
        if M.last_frame_time == 0 then
            elapsed = FRAME_TIME
        end
        M.last_frame_time = ticks
        local dt = elapsed / 1000.0
        if dt < 0.0 then dt = 0.0 end
        if dt > 0.1 then dt = 0.1 end

        local remain = dt
        local step = 1.0 / 120.0
        while remain > 0.0 do
            local sub = math.min(step, remain)
            M.current_time = M.current_time + sub
            update_sites(sub)
            remain = remain - sub
        end
        refresh_markers()

        if M.current_time - M.last_rebuild > REBUILD_INTERVAL then
            rebuild_graph_scene()
        end

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        local idx = sw:acquire_next_image(image_available)
        if idx == nil then return end

        local cb = cbs[idx + 1]
        vk.vkResetCommandBuffer(cb, 0)
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        local eye = { math.cos(M.angle) * 24.0, 12.0, math.sin(M.angle) * 24.0 }
        local view = math_utils.look_at(eye, {0, 0, 0}, {0, 1, 0})
        local proj = math_utils.perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 120.0)
        local mvp = math_utils.multiply(proj, view)
        M.angle = M.angle + 0.002

        local pc = ffi.new("DrawPC")
        for i = 1, 16 do pc.mvp[i - 1] = mvp[i] end

        local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = range, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[idx])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32 = { 0.008, 0.008, 0.015, 1.0 }

        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

        pc.mode = 0
        pc.count = voronoi_count
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_size, pc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, voronoi_count, 1, 0, 0)

        if path_count > 1 then
            pc.mode = 1
            pc.count = path_count
            vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_size, pc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
            vk.vkCmdDraw(cb, path_count, 1, 0, 0)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
            vk.vkCmdDraw(cb, path_count, 1, 0, 0)
        end

        pc.mode = 2
        pc.count = marker_count
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_size, pc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, marker_count, 1, 0, 0)

        vk.vkCmdEndRendering(cb)

        bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        bar[0].dstAccessMask = 0
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb)

        local submit = ffi.new("VkSubmitInfo", {
            sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            waitSemaphoreCount = 1,
            pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }),
            pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }),
            commandBufferCount = 1,
            pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }),
            signalSemaphoreCount = 1,
            pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }),
        })

        vk.vkQueueSubmit(queue, 1, submit, frame_fence)
        sw:present(queue, idx, sw.semaphores[idx])
    end)

    if not ok then
        print("M.update: ERROR:", err)
    end
end

return M
