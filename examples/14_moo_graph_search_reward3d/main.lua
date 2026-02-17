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
local resource = require("vulkan.resource")
local sdl = require("vulkan.sdl")
local math_utils = require("examples.14_moo_graph_search_reward3d.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    angle = 0,
    current_time = 0,
    last_reset = 0,
    front_vertex_count = 0,
}

local FPS_LIMIT = 60
local FRAME_TIME = 1000 / FPS_LIMIT
local NODE_COUNT = 5000
local EDGE_COUNT = 15000
local SOLUTIONS_PER_NODE = 8
local RESET_INTERVAL = 8
local FRONT_GRID_X = 40
local FRONT_GRID_Y = 40
local MAX_FRONT_VERTICES = (FRONT_GRID_X - 1) * (FRONT_GRID_Y - 1) * 6
local REWARD_RADIUS_SCALE = 1.9

local win_graph, win_pareto, win_pareto_id
local sw_graph, sw_pareto
local device, queue, graphics_family
local pipe_nodes, pipe_edges, pipe_pareto_points, pipe_pareto_mesh, pipe_search
local layout_graph
local node_buf, edge_buf, pareto_buf, interactive_buf, front_mesh_buf
local bindless_set
local image_available_graph, image_available_pareto
local cbs_graph, cbs_pareto
local frame_fence
local initial_solutions = nil
local pareto_sol_count = NODE_COUNT * SOLUTIONS_PER_NODE
local push_const_size = 0

local function read_text(path)
    local f = io.open(path, "r")
    if not f then
        error("Failed to read shader source: " .. tostring(path))
    end
    local src = f:read("*all")
    f:close()
    return src
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    end
    if x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    end
    if x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    end
    if x == 0 and y > 0 then
        return math.pi * 0.5
    end
    if x == 0 and y < 0 then
        return -math.pi * 0.5
    end
    return 0
end

local function write_front_vertex(ptr, idx, p)
    ptr[idx].x = p.x
    ptr[idx].y = p.y
    ptr[idx].z = p.z
    ptr[idx].pad = 0.0

    local t = clamp((p.z + 0.95) * 0.5, 0.0, 1.0)
    ptr[idx].r = 0.15 + 0.2 * (1.0 - t)
    ptr[idx].g = 0.45 + 0.55 * t
    ptr[idx].b = 0.2 + 0.2 * (1.0 - t)
    ptr[idx].a = 0.65
end

function M.build_front_mesh()
    if not M.sol_ptr or not M.front_ptr then
        return 0
    end

    local bins = {}
    local valid_count = 0
    for i = 0, pareto_sol_count - 1 do
        local s = M.sol_ptr[i]
        if s.dist < 1e8 then
            local x = clamp((s.dist / 40.0) - 0.95, -0.95, 0.95)
            local y = clamp(-((s.cost / 40.0) - 0.95), -0.95, 0.95)
            local z = clamp((s.reward / 20.0) - 0.95, -0.95, 0.95)

            local gx = math.floor(((x + 0.95) / 1.9) * (FRONT_GRID_X - 1) + 0.5)
            local gy = math.floor(((y + 0.95) / 1.9) * (FRONT_GRID_Y - 1) + 0.5)
            gx = clamp(gx, 0, FRONT_GRID_X - 1)
            gy = clamp(gy, 0, FRONT_GRID_Y - 1)
            local key = gy * FRONT_GRID_X + gx + 1

            local curr = bins[key]
            if (not curr) or z > curr.z then
                bins[key] = { x = x, y = y, z = z }
            end
            valid_count = valid_count + 1
        end
    end

    if valid_count < 3 then
        return 0
    end

    -- Fill sparse cells so the rendered surface stays connected like a blanket.
    local filled = {}
    local present = {}
    for gy = 0, FRONT_GRID_Y - 1 do
        for gx = 0, FRONT_GRID_X - 1 do
            local idx = gy * FRONT_GRID_X + gx + 1
            local p = bins[idx]
            if p then
                filled[idx] = { x = p.x, y = p.y, z = p.z }
                present[#present + 1] = filled[idx]
            else
                local x = -0.95 + (gx / (FRONT_GRID_X - 1)) * 1.9
                local y = -0.95 + (gy / (FRONT_GRID_Y - 1)) * 1.9
                local best = nil
                local best_d2 = 1e9
                for i = 1, #present do
                    local q = present[i]
                    local dx = q.x - x
                    local dy = q.y - y
                    local d2 = dx * dx + dy * dy
                    if d2 < best_d2 then
                        best_d2 = d2
                        best = q
                    end
                end
                if best then
                    filled[idx] = { x = x, y = y, z = best.z }
                else
                    filled[idx] = { x = x, y = y, z = -0.95 }
                end
            end
        end
    end

    -- Smooth z to avoid jagged patchwork while keeping the surface connected.
    for iter = 1, 2 do
        local tmp = {}
        for gy = 0, FRONT_GRID_Y - 1 do
            for gx = 0, FRONT_GRID_X - 1 do
                local idx = gy * FRONT_GRID_X + gx + 1
                local sum = 0.0
                local cnt = 0
                for oy = -1, 1 do
                    for ox = -1, 1 do
                        local nx = gx + ox
                        local ny = gy + oy
                        if nx >= 0 and nx < FRONT_GRID_X and ny >= 0 and ny < FRONT_GRID_Y then
                            local nidx = ny * FRONT_GRID_X + nx + 1
                            sum = sum + filled[nidx].z
                            cnt = cnt + 1
                        end
                    end
                end
                local cur = filled[idx]
                tmp[idx] = { x = cur.x, y = cur.y, z = (sum / cnt) }
            end
        end
        filled = tmp
    end

    local v = 0
    local function emit(p)
        if v < MAX_FRONT_VERTICES then
            write_front_vertex(M.front_ptr, v, p)
            v = v + 1
        end
    end

    for gy = 0, FRONT_GRID_Y - 2 do
        for gx = 0, FRONT_GRID_X - 2 do
            local i00 = gy * FRONT_GRID_X + gx + 1
            local i10 = gy * FRONT_GRID_X + (gx + 1) + 1
            local i01 = (gy + 1) * FRONT_GRID_X + gx + 1
            local i11 = (gy + 1) * FRONT_GRID_X + (gx + 1) + 1

            local p00 = filled[i00]
            local p10 = filled[i10]
            local p01 = filled[i01]
            local p11 = filled[i11]
            emit(p00); emit(p10); emit(p01)
            emit(p10); emit(p11); emit(p01)
        end
    end

    return v
end

function M.init()
    print("Example 14: MOO Graph Search + Moving Reward Regions + 3D Pareto Mesh")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct Node { float x, y, z, p1; float r, g, b, p2; } Node;
        typedef struct Edge { uint32_t a, b; float dist, cost; } Edge;
        typedef struct Solution { float dist, cost, reward; uint32_t parent_node, parent_sol_idx; } Solution;
        typedef struct InteractiveData { float mouse_x, mouse_y; uint32_t active_node, active_sol_idx; } InteractiveData;
        typedef struct GraphPC {
            float mvp[16];
            float obs_x, obs_y, obs_z, obs_r;
            float rew1_x, rew1_y, rew1_z, rew1_r;
            float rew2_x, rew2_y, rew2_z, rew2_r;
            float rew3_x, rew3_y, rew3_z, rew3_r;
            float rew4_x, rew4_y, rew4_z, rew4_r;
            uint32_t mode;
        } GraphPC;
        typedef struct SearchPC {
            uint32_t node_count, edge_count, iter, pad;
            float obs_x, obs_y, obs_z, obs_r;
            float rew1_x, rew1_y, rew1_z, rew1_r;
            float rew2_x, rew2_y, rew2_z, rew2_r;
            float rew3_x, rew3_y, rew3_z, rew3_r;
            float rew4_x, rew4_y, rew4_z, rew4_r;
        } SearchPC;
        typedef struct ParetoVertex { float x, y, z, pad; float r, g, b, a; } ParetoVertex;
    ]]

    push_const_size = ffi.sizeof("GraphPC")

    win_graph = _SDL_WINDOW
    sw_graph = swapchain.new(instance, physical_device, device, win_graph)
    win_pareto = sdl.SDL_CreateWindow("Pareto Front 3D", 700, 700, bit.bor(sdl.SDL_WINDOW_VULKAN, sdl.SDL_WINDOW_RESIZABLE))
    win_pareto_id = sdl.SDL_GetWindowID(win_pareto)
    sw_pareto = swapchain.new(instance, physical_device, device, win_pareto)

    local device_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 256 * 1024 * 1024)
    local host_heap = heap.new(physical_device, device, heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 128 * 1024 * 1024)

    local nodes = ffi.new("Node[?]", NODE_COUNT)
    for i = 0, NODE_COUNT - 1 do
        nodes[i].x, nodes[i].y, nodes[i].z = (math.random() - 0.5) * 12, (math.random() - 0.5) * 12, (math.random() - 0.5) * 12
        nodes[i].r, nodes[i].g, nodes[i].b = 0.1, 0.15, 0.2
    end
    nodes[0].r, nodes[0].g, nodes[0].b = 1.0, 1.0, 0.0

    local node_size = ffi.sizeof("Node") * NODE_COUNT
    local pNB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = node_size,
        usage = bit.bor(vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    }), nil, pNB)
    node_buf = pNB[0]
    local n_alloc = device_heap:malloc(node_size)
    vk.vkBindBufferMemory(device, node_buf, n_alloc.memory, n_alloc.offset)
    staging.new(physical_device, device, host_heap, node_size + 1024):upload_buffer(node_buf, nodes, 0, queue, graphics_family)

    local edges = ffi.new("Edge[?]", EDGE_COUNT)
    for i = 0, EDGE_COUNT - 1 do
        local a, b = math.random(0, NODE_COUNT - 1), math.random(0, NODE_COUNT - 1)
        edges[i].a, edges[i].b = a, b
        local dx, dy, dz = nodes[a].x - nodes[b].x, nodes[a].y - nodes[b].y, nodes[a].z - nodes[b].z
        edges[i].dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        edges[i].cost = math.random() * 10.0
    end

    local edge_size = ffi.sizeof("Edge") * EDGE_COUNT
    local pEB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = edge_size,
        usage = bit.bor(vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    }), nil, pEB)
    edge_buf = pEB[0]
    local e_alloc = device_heap:malloc(edge_size)
    vk.vkBindBufferMemory(device, edge_buf, e_alloc.memory, e_alloc.offset)
    staging.new(physical_device, device, host_heap, edge_size + 1024):upload_buffer(edge_buf, edges, 0, queue, graphics_family)

    initial_solutions = ffi.new("Solution[?]", pareto_sol_count)
    for i = 0, pareto_sol_count - 1 do
        initial_solutions[i].dist = 1e9
        initial_solutions[i].cost = 1e9
        initial_solutions[i].reward = -1e9
        initial_solutions[i].parent_node = 0xFFFFFFFF
        initial_solutions[i].parent_sol_idx = 0
    end
    for i = 0, 9 do
        local s = initial_solutions[i * SOLUTIONS_PER_NODE]
        s.dist = 0
        s.cost = 0
        s.reward = 0
        s.parent_node = 0
        s.parent_sol_idx = 0
    end

    local sol_size = ffi.sizeof("Solution") * pareto_sol_count
    local pSB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = sol_size,
        usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT)
    }), nil, pSB)
    pareto_buf = pSB[0]
    local s_alloc = host_heap:malloc(sol_size)
    vk.vkBindBufferMemory(device, pareto_buf, s_alloc.memory, s_alloc.offset)
    M.sol_ptr = ffi.cast("Solution*", s_alloc.ptr)
    staging.new(physical_device, device, host_heap, sol_size + 1024):upload_buffer(pareto_buf, initial_solutions, 0, queue, graphics_family)

    local pIB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = ffi.sizeof("InteractiveData"),
        usage = vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT
    }), nil, pIB)
    interactive_buf = pIB[0]
    local i_alloc = host_heap:malloc(ffi.sizeof("InteractiveData"))
    vk.vkBindBufferMemory(device, interactive_buf, i_alloc.memory, i_alloc.offset)
    M.interactive_ptr = ffi.cast("InteractiveData*", i_alloc.ptr)

    local front_size = ffi.sizeof("ParetoVertex") * MAX_FRONT_VERTICES
    local pFB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = front_size,
        usage = vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT
    }), nil, pFB)
    front_mesh_buf = pFB[0]
    local f_alloc = host_heap:malloc(front_size)
    vk.vkBindBufferMemory(device, front_mesh_buf, f_alloc.memory, f_alloc.offset)
    M.front_ptr = ffi.cast("ParetoVertex*", f_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, node_buf, 0, node_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, edge_buf, 0, edge_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pareto_buf, 0, sol_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, interactive_buf, 0, ffi.sizeof("InteractiveData"), 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, front_mesh_buf, 0, front_size, 4)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT),
        offset = 0,
        size = push_const_size
    }}))

    local search_mod = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/search.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT))
    local graph_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/graph.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local graph_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/graph.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local edge_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/edge.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local edge_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/edge.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local pareto_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/pareto.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local pareto_mesh_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/pareto_mesh.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local pareto_mesh_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/14_moo_graph_search_reward3d/pareto_mesh.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_search = pipeline.create_compute_pipeline(device, layout_graph, search_mod)
    pipe_nodes = pipeline.create_graphics_pipeline(device, layout_graph, graph_vert, graph_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_edges = pipeline.create_graphics_pipeline(device, layout_graph, edge_vert, edge_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, additive = true })
    pipe_pareto_points = pipeline.create_graphics_pipeline(device, layout_graph, pareto_vert, graph_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })
    pipe_pareto_mesh = pipeline.create_graphics_pipeline(device, layout_graph, pareto_mesh_vert, pareto_mesh_frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, additive = true })

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem)
    image_available_graph = pSem[0]
    vk.vkCreateSemaphore(device, sem_info, nil, pSem)
    image_available_pareto = pSem[0]

    local pool = command.create_pool(device, graphics_family)
    cbs_graph = command.allocate_buffers(device, pool, sw_graph.image_count)
    cbs_pareto = command.allocate_buffers(device, pool, sw_pareto.image_count)

    local pF = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF)
    frame_fence = pF[0]

    M.staging = staging.new(physical_device, device, host_heap, sol_size + 1024)
end

function M.update()
    local status, err = pcall(function()
        local current_ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = current_ticks - M.last_frame_time
        if elapsed < FRAME_TIME then
            sdl.SDL_Delay(FRAME_TIME - elapsed)
            current_ticks = tonumber(sdl.SDL_GetTicks())
        end
        M.last_frame_time = current_ticks
        M.current_time = M.current_time + 0.016

        if M.current_time - M.last_reset > RESET_INTERVAL then
            M.last_reset = M.current_time
            M.staging:upload_buffer(pareto_buf, initial_solutions, 0, queue, graphics_family)
        end

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        resource.tick()
        M.angle = M.angle + 0.005

        M.front_vertex_count = M.build_front_mesh()

        if _MOUSE_WINDOW == win_pareto_id then
            M.interactive_ptr.mouse_x = (_MOUSE_X / sw_pareto.extent.width) * 2 - 1
            M.interactive_ptr.mouse_y = (_MOUSE_Y / sw_pareto.extent.height) * 2 - 1
        else
            M.interactive_ptr.mouse_x = 2.0
        end

        local idx_graph = sw_graph:acquire_next_image(image_available_graph)
        local idx_pareto = sw_pareto:acquire_next_image(image_available_pareto)
        if idx_graph == nil or idx_pareto == nil then
            return
        end

        local view = math_utils.look_at({ math.cos(M.angle) * 18, 6, math.sin(M.angle) * 18 }, { 0, 0, 0 }, { 0, 1, 0 })
        local proj = math_utils.perspective(math.rad(45), sw_graph.extent.width / sw_graph.extent.height, 0.1, 100.0)
        local mvp = math_utils.multiply(proj, view)

        local pareto_view = math_utils.look_at({ math.cos(M.current_time * 0.35) * 2.2, 1.8, math.sin(M.current_time * 0.35) * 2.2 }, { 0, 0, 0 }, { 0, 1, 0 })
        local pareto_proj = math_utils.perspective(math.rad(50), sw_pareto.extent.width / sw_pareto.extent.height, 0.01, 20.0)
        local pareto_mvp = math_utils.multiply(pareto_proj, pareto_view)

        local ox = math.sin(M.current_time * 0.4) * 5
        local oy = 0
        local oz = math.cos(M.current_time * 0.4) * 5

        local r1x = math.sin(M.current_time * 0.7) * 4.0
        local r1y = math.sin(M.current_time * 0.3) * 1.3
        local r1z = math.cos(M.current_time * 0.7) * 4.0
        local r1r = 2.2 * REWARD_RADIUS_SCALE

        local r2x = math.sin(M.current_time * 0.55 + 2.0) * 4.5
        local r2y = math.cos(M.current_time * 0.45) * 1.0
        local r2z = math.cos(M.current_time * 0.55 + 2.0) * 4.5
        local r2r = 2.0 * REWARD_RADIUS_SCALE

        local r3x = math.sin(M.current_time * 0.9 + 1.2) * 3.7
        local r3y = math.cos(M.current_time * 0.62 + 0.5) * 1.1
        local r3z = math.cos(M.current_time * 0.9 + 1.2) * 3.7
        local r3r = 1.8 * REWARD_RADIUS_SCALE

        local r4x = math.sin(M.current_time * 0.48 + 4.1) * 5.1
        local r4y = math.sin(M.current_time * 0.38 + 0.9) * 0.9
        local r4z = math.cos(M.current_time * 0.48 + 4.1) * 5.1
        local r4r = 2.1 * REWARD_RADIUS_SCALE

        local search_pc = ffi.new("SearchPC", {
            node_count = NODE_COUNT,
            edge_count = EDGE_COUNT,
            iter = 0,
            obs_x = ox, obs_y = oy, obs_z = oz, obs_r = 3.0,
            rew1_x = r1x, rew1_y = r1y, rew1_z = r1z, rew1_r = r1r,
            rew2_x = r2x, rew2_y = r2y, rew2_z = r2z, rew2_r = r2r,
            rew3_x = r3x, rew3_y = r3y, rew3_z = r3z, rew3_r = r3r,
            rew4_x = r4x, rew4_y = r4y, rew4_z = r4z, rew4_r = r4r,
        })

        local pc_graph = ffi.new("GraphPC")
        for i = 1, 16 do
            pc_graph.mvp[i - 1] = mvp[i]
        end
        pc_graph.obs_x, pc_graph.obs_y, pc_graph.obs_z, pc_graph.obs_r = ox, oy, oz, 3.0
        pc_graph.rew1_x, pc_graph.rew1_y, pc_graph.rew1_z, pc_graph.rew1_r = r1x, r1y, r1z, r1r
        pc_graph.rew2_x, pc_graph.rew2_y, pc_graph.rew2_z, pc_graph.rew2_r = r2x, r2y, r2z, r2r
        pc_graph.rew3_x, pc_graph.rew3_y, pc_graph.rew3_z, pc_graph.rew3_r = r3x, r3y, r3z, r3r
        pc_graph.rew4_x, pc_graph.rew4_y, pc_graph.rew4_z, pc_graph.rew4_r = r4x, r4y, r4z, r4r
        pc_graph.mode = 0

        local pc_pareto = ffi.new("GraphPC")
        for i = 1, 16 do
            pc_pareto.mvp[i - 1] = pareto_mvp[i]
        end

        local cb_g = cbs_graph[idx_graph + 1]
        vk.vkResetCommandBuffer(cb_g, 0)
        vk.vkBeginCommandBuffer(cb_g, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_search)
        vk.vkCmdBindDescriptorSets(cb_g, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("SearchPC"), search_pc)
        vk.vkCmdDispatch(cb_g, math.ceil(EDGE_COUNT / 256), 1, 1)

        local mem_bar = ffi.new("VkMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
            srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
            dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT)
        }})
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT), 0, 1, mem_bar, 0, nil, 0, nil)

        local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            image = ffi.cast("VkImage", sw_graph.images[idx_graph]),
            subresourceRange = range,
            dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        }})
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw_graph.views[idx_graph])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32 = { 0.005, 0.005, 0.01, 1.0 }

        vk.vkCmdBeginRendering(cb_g, ffi.new("VkRenderingInfo", {
            sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
            renderArea = { extent = sw_graph.extent },
            layerCount = 1,
            colorAttachmentCount = 1,
            pColorAttachments = color_attach
        }))
        vk.vkCmdSetViewport(cb_g, 0, 1, ffi.new("VkViewport", { width = sw_graph.extent.width, height = sw_graph.extent.height, maxDepth = 1 }))
        vk.vkCmdSetScissor(cb_g, 0, 1, ffi.new("VkRect2D", { extent = sw_graph.extent }))
        vk.vkCmdBindDescriptorSets(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

        pc_graph.mode = 1
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, pc_graph)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes)
        vk.vkCmdDraw(cb_g, 1, 1, NODE_COUNT, 0)

        pc_graph.mode = 2
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, pc_graph)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes)
        vk.vkCmdDraw(cb_g, 4, 1, 0, 0)

        pc_graph.mode = 0
        vk.vkCmdPushConstants(cb_g, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, pc_graph)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_edges)
        vk.vkCmdDraw(cb_g, EDGE_COUNT * 2, 1, 0, 0)
        vk.vkCmdBindPipeline(cb_g, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_nodes)
        vk.vkCmdDraw(cb_g, NODE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(cb_g)

        bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        vk.vkCmdPipelineBarrier(cb_g, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb_g)

        local cb_p = cbs_pareto[idx_pareto + 1]
        vk.vkResetCommandBuffer(cb_p, 0)
        vk.vkBeginCommandBuffer(cb_p, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        bar[0].image = ffi.cast("VkImage", sw_pareto.images[idx_pareto])
        bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED
        bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        bar[0].srcAccessMask = 0
        bar[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        vk.vkCmdPipelineBarrier(cb_p, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

        color_attach[0].imageView = ffi.cast("VkImageView", sw_pareto.views[idx_pareto])
        color_attach[0].clearValue.color.float32 = { 0.01, 0.01, 0.01, 1.0 }
        vk.vkCmdBeginRendering(cb_p, ffi.new("VkRenderingInfo", {
            sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
            renderArea = { extent = sw_pareto.extent },
            layerCount = 1,
            colorAttachmentCount = 1,
            pColorAttachments = color_attach
        }))
        vk.vkCmdSetViewport(cb_p, 0, 1, ffi.new("VkViewport", { width = sw_pareto.extent.width, height = sw_pareto.extent.height, maxDepth = 1 }))
        vk.vkCmdSetScissor(cb_p, 0, 1, ffi.new("VkRect2D", { extent = sw_pareto.extent }))
        vk.vkCmdBindDescriptorSets(cb_p, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

        vk.vkCmdPushConstants(cb_p, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, push_const_size, pc_pareto)

        if M.front_vertex_count > 0 then
            vk.vkCmdBindPipeline(cb_p, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_pareto_mesh)
            vk.vkCmdDraw(cb_p, M.front_vertex_count, 1, 0, 0)
        end

        vk.vkCmdBindPipeline(cb_p, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_pareto_points)
        vk.vkCmdDraw(cb_p, pareto_sol_count, 1, 0, 0)
        vk.vkCmdEndRendering(cb_p)

        bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        bar[0].dstAccessMask = 0
        vk.vkCmdPipelineBarrier(cb_p, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(cb_p)

        local submit_info = ffi.new("VkSubmitInfo", {
            sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            waitSemaphoreCount = 2,
            pWaitSemaphores = ffi.new("VkSemaphore[2]", { image_available_graph, image_available_pareto }),
            pWaitDstStageMask = ffi.new("VkPipelineStageFlags[2]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }),
            commandBufferCount = 2,
            pCommandBuffers = ffi.new("VkCommandBuffer[2]", { cb_g, cb_p }),
            signalSemaphoreCount = 2,
            pSignalSemaphores = ffi.new("VkSemaphore[2]", { sw_graph.semaphores[idx_graph], sw_pareto.semaphores[idx_pareto] })
        })

        vk.vkQueueSubmit(queue, 1, submit_info, frame_fence)
        sw_graph:present(queue, idx_graph, sw_graph.semaphores[idx_graph])
        sw_pareto:present(queue, idx_pareto, sw_pareto.semaphores[idx_pareto])
    end)

    if not status then
        print("M.update: ERROR:", err)
    end
end

return M
