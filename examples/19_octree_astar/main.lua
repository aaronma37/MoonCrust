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
local math_utils = require("examples.19_octree_astar.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
    last_rebuild = 0,
}

local FPS_LIMIT = 60
local FRAME_TIME = 1000 / FPS_LIMIT
local REBUILD_INTERVAL = 1.20

local NX, NY, NZ = 32, 16, 32
local X_EXTENT, Y_EXTENT, Z_EXTENT = 20.0, 10.0, 20.0
local ROOT_SIZE = 8
local MIN_SIZE = 1

local SITE_COUNT = 170
local SITE_MARGIN = 0.25
local START_GOAL_CLEARANCE = 1.35
local SITE_SPEED_SCALE = 2.7
local SITE_SWAY_SCALE = 1.1

local MAX_NODE_POINTS = 12000
local MAX_PATH_POINTS = 8192
local MAX_MARKERS = 640
local MAX_GRAPH_NODES = 6500

local START = { x = -8.0, y = -2.0, z = -8.0 }
local GOAL  = { x =  8.0, y =  2.0, z =  8.0 }

local device, queue, graphics_family
local sw
local layout_graph
local bindless_set
local pipe_points, pipe_lines

local node_buf, path_buf, marker_buf
local node_ptr, path_ptr, marker_ptr
local node_count = 0
local path_count = 0
local marker_count = 0
local has_valid_path = false

local image_available
local cbs
local frame_fence
local push_size = 0

local sites = {}

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

local function world_xf(ix)
    return ((ix / (NX - 1)) - 0.5) * X_EXTENT
end

local function world_yf(iy)
    return ((iy / (NY - 1)) - 0.5) * Y_EXTENT
end

local function world_zf(iz)
    return ((iz / (NZ - 1)) - 0.5) * Z_EXTENT
end

local function grid_xf(x)
    return ((x / X_EXTENT) + 0.5) * (NX - 1)
end

local function grid_yf(y)
    return ((y / Y_EXTENT) + 0.5) * (NY - 1)
end

local function grid_zf(z)
    return ((z / Z_EXTENT) + 0.5) * (NZ - 1)
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
    for i = 1, #sites do
        local s = sites[i]
        local dx, dy, dz = px - s.x, py - s.y, pz - s.z
        local d = math.sqrt(dx * dx + dy * dy + dz * dz) - s.r
        if d < best then
            best = d
        end
    end
    return best
end

local function segment_clear(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    local n = math.max(2, math.floor(len / 0.22))
    for i = 0, n do
        local t = i / n
        local x = a.x + dx * t
        local y = a.y + dy * t
        local z = a.z + dz * t
        if sdf_to_sites(x, y, z) < 0.03 then
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
        local r = 0.45 + 0.18 * (i % 5)
        local vx = (0.20 + 0.025 * (i % 5)) * SITE_SPEED_SCALE
        local vy = (0.14 + 0.02 * (i % 4)) * SITE_SPEED_SCALE
        local vz = (0.22 + 0.02 * (i % 6)) * SITE_SPEED_SCALE
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
        set_draw_point(marker_ptr, marker_count, s.x, s.y, s.z, s.r * 28.0, 1.0, 0.16, 0.16, 0.88)
        marker_count = marker_count + 1
    end
end

local function cube_sdf_range(ox, oy, oz, size)
    local hi = size - 1
    local mx = ox + hi * 0.5
    local my = oy + hi * 0.5
    local mz = oz + hi * 0.5

    local pts = {
        {ox, oy, oz}, {ox + hi, oy, oz}, {ox, oy + hi, oz}, {ox, oy, oz + hi},
        {ox + hi, oy + hi, oz}, {ox + hi, oy, oz + hi}, {ox, oy + hi, oz + hi}, {ox + hi, oy + hi, oz + hi},
        {mx, my, mz},
        {mx, oy, mz}, {mx, oy + hi, mz}, {ox, my, mz}, {ox + hi, my, mz}, {mx, my, oz}, {mx, my, oz + hi},
    }

    local best_min = 1e9
    local best_max = -1e9
    for i = 1, #pts do
        local p = pts[i]
        local sdf = sdf_to_sites(world_xf(p[1]), world_yf(p[2]), world_zf(p[3]))
        if sdf < best_min then best_min = sdf end
        if sdf > best_max then best_max = sdf end
    end
    return best_min, best_max
end

local function build_octree_graph_and_path()
    local nodes = {}

    local sx, sy, sz = grid_xf(START.x), grid_yf(START.y), grid_zf(START.z)
    local gx, gy, gz = grid_xf(GOAL.x), grid_yf(GOAL.y), grid_zf(GOAL.z)

    local dxw = X_EXTENT / (NX - 1)
    local dyw = Y_EXTENT / (NY - 1)
    local dzw = Z_EXTENT / (NZ - 1)

    local function contains_endpoint(ox, oy, oz, size)
        local hi = size - 1
        local has_start = (sx >= ox and sx <= ox + hi and sy >= oy and sy <= oy + hi and sz >= oz and sz <= oz + hi)
        local has_goal = (gx >= ox and gx <= ox + hi and gy >= oy and gy <= oy + hi and gz >= oz and gz <= oz + hi)
        return has_start or has_goal
    end

    local function split_node(ox, oy, oz, size)
        local min_sdf, max_sdf = cube_sdf_range(ox, oy, oz, size)
        if max_sdf <= 0.03 then
            return
        end

        if size <= MIN_SIZE then
            local c = ox
            local d = oy
            local e = oz
            local csdf = sdf_to_sites(world_xf(c), world_yf(d), world_zf(e))
            if csdf > 0.03 then
                nodes[#nodes + 1] = {
                    ox = ox, oy = oy, oz = oz, size = size,
                    x = world_xf(c), y = world_yf(d), z = world_zf(e),
                    clear = csdf,
                }
            end
            return
        end

        local span = math.sqrt((size * dxw)^2 + (size * dyw)^2 + (size * dzw)^2)
        local near_obstacle = min_sdf < (0.30 * span)
        local can_stay_coarse = (not near_obstacle) and (min_sdf > (0.72 * span))

        if can_stay_coarse and not contains_endpoint(ox, oy, oz, size) then
            local c = ox + 0.5 * (size - 1)
            local d = oy + 0.5 * (size - 1)
            local e = oz + 0.5 * (size - 1)
            nodes[#nodes + 1] = {
                ox = ox, oy = oy, oz = oz, size = size,
                x = world_xf(c), y = world_yf(d), z = world_zf(e),
                clear = min_sdf,
            }
            if #nodes >= MAX_GRAPH_NODES then
                return
            end
            return
        end

        local half = math.floor(size / 2)
        if half < 1 then half = 1 end
        for dz = 0, 1 do
            for dy = 0, 1 do
                for dx = 0, 1 do
                    local cx = ox + dx * half
                    local cy = oy + dy * half
                    local cz = oz + dz * half
                    if cx < NX and cy < NY and cz < NZ then
                        local sx2 = math.min(half, NX - cx)
                        local sy2 = math.min(half, NY - cy)
                        local sz2 = math.min(half, NZ - cz)
                        local child = math.min(sx2, math.min(sy2, sz2))
                        if child > 0 then
                            split_node(cx, cy, cz, child)
                        end
                    end
                    if #nodes >= MAX_GRAPH_NODES then
                        return
                    end
                end
            end
        end
    end

    for oz = 0, NZ - 1, ROOT_SIZE do
        for oy = 0, NY - 1, ROOT_SIZE do
            for ox = 0, NX - 1, ROOT_SIZE do
                local sx2 = math.min(ROOT_SIZE, NX - ox)
                local sy2 = math.min(ROOT_SIZE, NY - oy)
                local sz2 = math.min(ROOT_SIZE, NZ - oz)
                local size = math.min(sx2, math.min(sy2, sz2))
                if size > 0 then
                    split_node(ox, oy, oz, size)
                end
            end
        end
    end

    if #nodes < 2 then
        return nodes, {}, {}
    end

    local owner = {}
    for i = 1, NX * NY * NZ do owner[i] = 0 end
    for i = 1, #nodes do
        local n = nodes[i]
        local hi = n.size - 1
        for z = n.oz, n.oz + hi do
            for y = n.oy, n.oy + hi do
                for x = n.ox, n.ox + hi do
                    owner[idx3(x, y, z) + 1] = i
                end
            end
        end
    end

    local adj = {}
    for i = 1, #nodes do adj[i] = {} end
    local edge_seen = {}

    local function add_edge(a, b)
        if a == b or a == 0 or b == 0 then return end
        local lo, hi = a, b
        if lo > hi then lo, hi = hi, lo end
        local key = lo * 65536 + hi
        if edge_seen[key] then return end

        edge_seen[key] = true
        adj[a][#adj[a] + 1] = b
        adj[b][#adj[b] + 1] = a
    end

    for z = 0, NZ - 1 do
        for y = 0, NY - 1 do
            for x = 0, NX - 1 do
                local a = owner[idx3(x, y, z) + 1]
                if a ~= 0 then
                    if x + 1 < NX then add_edge(a, owner[idx3(x + 1, y, z) + 1]) end
                    if y + 1 < NY then add_edge(a, owner[idx3(x, y + 1, z) + 1]) end
                    if z + 1 < NZ then add_edge(a, owner[idx3(x, y, z + 1) + 1]) end
                end
            end
        end
    end

    local function nearest_connect_ids(p, max_d, max_n)
        local cand = {}
        local max_d2 = max_d * max_d
        for i = 1, #nodes do
            local n = nodes[i]
            local dx, dy, dz = n.x - p.x, n.y - p.y, n.z - p.z
            local d2 = dx * dx + dy * dy + dz * dz
            if d2 <= max_d2 then
                if segment_clear(p, n) then
                    cand[#cand + 1] = { i = i, d2 = d2 }
                end
            end
        end
        table.sort(cand, function(a, b) return a.d2 < b.d2 end)
        local out = {}
        for i = 1, math.min(max_n, #cand) do
            out[#out + 1] = cand[i].i
        end
        return out
    end

    local path = {}
    if segment_clear(START, GOAL) then
        path[1] = { x = START.x, y = START.y, z = START.z }
        path[2] = { x = GOAL.x, y = GOAL.y, z = GOAL.z }
        return nodes, adj, path
    end

    local N = #nodes
    local VSTART = N + 1
    local VGOAL = N + 2
    local all_adj = {}
    for i = 1, N do all_adj[i] = adj[i] end
    all_adj[VSTART] = {}
    all_adj[VGOAL] = {}

    local s_ids = nearest_connect_ids(START, 9.5, 20)
    local g_ids = nearest_connect_ids(GOAL, 9.5, 20)
    for i = 1, #s_ids do
        local v = s_ids[i]
        all_adj[VSTART][#all_adj[VSTART] + 1] = v
        all_adj[v][#all_adj[v] + 1] = VSTART
    end
    for i = 1, #g_ids do
        local v = g_ids[i]
        all_adj[VGOAL][#all_adj[VGOAL] + 1] = v
        all_adj[v][#all_adj[v] + 1] = VGOAL
    end

    if #all_adj[VSTART] == 0 or #all_adj[VGOAL] == 0 then
        return nodes, adj, {}
    end

    local function point_of(i)
        if i == VSTART then return START end
        if i == VGOAL then return GOAL end
        return nodes[i]
    end

    local function heur(i)
        local p = point_of(i)
        local dx, dy, dz = p.x - GOAL.x, p.y - GOAL.y, p.z - GOAL.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end

    local gscore = {}
    local fscore = {}
    local parent = {}
    local closed = {}
    local open = { VSTART }
    gscore[VSTART] = 0.0
    fscore[VSTART] = heur(VSTART)
    parent[VSTART] = -1

    while #open > 0 do
        local best_k = 1
        local best_i = open[1]
        local best_f = fscore[best_i] or 1e30
        for k = 2, #open do
            local ii = open[k]
            local ff = fscore[ii] or 1e30
            if ff < best_f then
                best_f = ff
                best_i = ii
                best_k = k
            end
        end

        open[best_k] = open[#open]
        open[#open] = nil

        if best_i == VGOAL then
            local chain = {}
            local cur = VGOAL
            while cur ~= -1 do
                chain[#chain + 1] = cur
                cur = parent[cur] or -1
            end
            for i = #chain, 1, -1 do
                local p = point_of(chain[i])
                path[#path + 1] = { x = p.x, y = p.y, z = p.z }
            end
            return nodes, adj, path
        end

        closed[best_i] = true
        local nbrs = all_adj[best_i]
        for j = 1, #nbrs do
            local nb = nbrs[j]
            if not closed[nb] then
                local a = point_of(best_i)
                local b = point_of(nb)
                local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
                local cost = math.sqrt(dx * dx + dy * dy + dz * dz)
                local tentative = (gscore[best_i] or 1e30) + cost
                if tentative < (gscore[nb] or 1e30) then
                    parent[nb] = best_i
                    gscore[nb] = tentative
                    fscore[nb] = tentative + heur(nb)
                    local in_open = false
                    for k = 1, #open do
                        if open[k] == nb then in_open = true; break end
                    end
                    if not in_open then open[#open + 1] = nb end
                end
            end
        end
    end

    return nodes, adj, {}
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

local function rebuild_graph_scene()
    local nodes, _, route = build_octree_graph_and_path()

    node_count = 0
    local nmax = math.min(#nodes, MAX_NODE_POINTS)
    for i = 1, nmax do
        local n = nodes[i]
        local t = clamp((n.size - 1) / (ROOT_SIZE - 1), 0.0, 1.0)
        local r = 0.05 + 0.2 * t
        local g = 0.45 + 0.45 * t
        local b = 1.0
        local a = 0.22 + 0.20 * t
        local ps = 1.5 + 2.4 * t
        set_draw_point(node_ptr, node_count, n.x, n.y, n.z, ps, r, g, b, a)
        node_count = node_count + 1
    end

    local new_path = {}
    if #route > 1 then
        route = simplify_los(route)
        for i = 1, math.min(#route, MAX_PATH_POINTS) do
            local p = route[i]
            new_path[#new_path + 1] = { x = p.x, y = p.y, z = p.z, s = (i == 1 or i == #route) and 7.2 or 6.0 }
        end
    end

    if #new_path > 1 then
        path_count = 0
        for i = 1, #new_path do
            local p = new_path[i]
            set_draw_point(path_ptr, path_count, p.x, p.y, p.z, p.s, 3.9, 2.9, 0.3, 0.96)
            path_count = path_count + 1
        end
        has_valid_path = true
    elseif not has_valid_path then
        path_count = 0
    end

    M.last_rebuild = M.current_time
end

function M.init()
    print("Example 19: Octree-style A* (3D, dynamic obstacles)")

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

    local node_size = ffi.sizeof("DrawPoint") * MAX_NODE_POINTS
    local path_size = ffi.sizeof("DrawPoint") * MAX_PATH_POINTS
    local marker_size = ffi.sizeof("DrawPoint") * MAX_MARKERS

    node_buf = make_buffer(node_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    path_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    marker_buf = make_buffer(marker_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)

    local n_alloc = host_heap:malloc(node_size)
    local p_alloc = host_heap:malloc(path_size)
    local m_alloc = host_heap:malloc(marker_size)

    vk.vkBindBufferMemory(device, node_buf, n_alloc.memory, n_alloc.offset)
    vk.vkBindBufferMemory(device, path_buf, p_alloc.memory, p_alloc.offset)
    vk.vkBindBufferMemory(device, marker_buf, m_alloc.memory, m_alloc.offset)

    node_ptr = ffi.cast("DrawPoint*", n_alloc.ptr)
    path_ptr = ffi.cast("DrawPoint*", p_alloc.ptr)
    marker_ptr = ffi.cast("DrawPoint*", m_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, node_buf, 0, node_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, path_buf, 0, path_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, marker_buf, 0, marker_size, 2)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = push_size }}))

    local draw_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local point_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local line_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

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
    refresh_markers()
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
        pc.count = node_count
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_size, pc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, node_count, 1, 0, 0)

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
