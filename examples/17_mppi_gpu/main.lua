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
local math_utils = require("examples.17_mppi_gpu.math")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
}

local FPS_LIMIT = 120
local FRAME_TIME = 1000 / FPS_LIMIT

local SAMPLES = 1024
local HORIZON = 48
local DT = 0.08
local SPEED = 4.0
local NOISE_YAW = 0.9
local NOISE_PITCH = 0.45
local GOAL_REACHED_RADIUS = 0.45
local GOAL_SLOW_RADIUS = 1.4
local GOAL_HOLD_FRAMES = 0

local MARKER_CAP = 12

local device, queue, graphics_family
local sw
local layout_graph
local bindless_set
local pipe_mppi, pipe_points, pipe_lines

local controls_buf, rollouts_buf, costs_buf, best_buf, agent_buf
local marker_buf, best_path_buf, agent_trail_buf, first_controls_buf
local controls_ptr, rollouts_ptr, costs_ptr, best_ptr, agent_ptr
local marker_ptr, best_path_ptr, agent_trail_ptr, first_controls_ptr

local image_available
local draw_cbs, planning_cb
local frame_fence

local push_draw_size = 0
local iter = 0
local best_path_count = 0
local trail_count = 0
local goal_hold_frames_left = 0

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local s = f:read("*all")
    f:close()
    return s
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

local function reset_agent()
    agent_ptr[0].x = -8.5
    agent_ptr[0].y = -1.2
    agent_ptr[0].z = -8.5
    agent_ptr[0].yaw = 0.85
    agent_ptr[0].pitch = 0.02
    agent_ptr[0].speed = SPEED
    agent_ptr[0].pad0 = 0.0
    agent_ptr[0].pad1 = 0.0

    for t = 0, HORIZON - 1 do
        controls_ptr[t].uyaw = 0.0
        controls_ptr[t].upitch = 0.0
    end

    trail_count = 0
    best_path_count = 0
end

local function update_markers(t)
    local sx, sy, sz = agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z
    local gx = math.sin(t * 0.95) * 8.6
    local gy = 1.1 + math.sin(t * 1.35 + 0.7) * 1.7
    local gz = math.cos(t * 0.82 + 0.4) * 8.2

    set_draw_point(marker_ptr, 0, sx, sy, sz, 11.0, 0.2, 1.0, 0.3, 1.0)
    set_draw_point(marker_ptr, 1, gx, gy, gz, 12.0, 1.0, 1.0, 0.2, 1.0)

    local obs = {
        { math.sin(t * 0.47) * 3.5, math.cos(t * 0.31) * 1.4, math.cos(t * 0.47) * 3.5, 1.15 },
        { math.sin(t * 0.33 + 2.0) * 5.2, math.sin(t * 0.27) * 1.0, math.cos(t * 0.33 + 2.0) * 5.2, 1.0 },
        { math.sin(t * 0.58 + 1.2) * 4.4, math.cos(t * 0.41 + 0.5) * 1.3, math.cos(t * 0.58 + 1.2) * 4.4, 1.05 },
        { math.sin(t * 0.39 + 3.7) * 6.0, math.cos(t * 0.36) * 1.1, math.cos(t * 0.39 + 3.7) * 6.0, 0.95 },
        { math.sin(t * 0.67 + 1.8) * 7.0, math.cos(t * 0.44 + 0.2) * 1.8, math.cos(t * 0.67 + 1.8) * 6.8, 0.92 },
        { math.sin(t * 0.52 + 4.4) * 6.6, math.sin(t * 0.63 + 0.8) * 1.9, math.cos(t * 0.52 + 4.4) * 6.5, 0.88 },
        { math.sin(t * 0.73 + 2.7) * 7.4, math.cos(t * 0.28 + 1.5) * 2.0, math.cos(t * 0.73 + 2.7) * 7.2, 0.90 },
        { math.sin(t * 0.61 + 5.5) * 5.8, math.sin(t * 0.49 + 2.1) * 1.7, math.cos(t * 0.61 + 5.5) * 6.1, 0.96 },
    }

    for i = 1, #obs do
        local o = obs[i]
        set_draw_point(marker_ptr, 1 + i, o[1], o[2], o[3], o[4] * 30.0, 1.0, 0.18, 0.18, 0.92)
    end

    return gx, gy, gz, obs
end

local function update_best_path_from_rollout(best_idx)
    best_path_count = 0
    if best_idx < 0 or best_idx >= SAMPLES then return end
    for t = 0, HORIZON - 1 do
        local b = (best_idx * HORIZON + t) * 4
        local x = rollouts_ptr[b + 0]
        local y = rollouts_ptr[b + 1]
        local z = rollouts_ptr[b + 2]
        set_draw_point(best_path_ptr, t, x, y, z, 6.2, 3.8, 2.8, 0.35, 0.95)
        best_path_count = best_path_count + 1
    end
end

local function apply_control_and_shift(best_idx, gx, gy, gz)
    if best_idx < 0 or best_idx >= SAMPLES then return end

    local fbase = best_idx * 2
    local uyaw = first_controls_ptr[fbase + 0]
    local upitch = first_controls_ptr[fbase + 1]

    local dxg = gx - agent_ptr[0].x
    local dyg = gy - agent_ptr[0].y
    local dzg = gz - agent_ptr[0].z
    local dg = math.sqrt(dxg * dxg + dyg * dyg + dzg * dzg)

    local yaw = agent_ptr[0].yaw + uyaw * DT
    local pitch = clamp(agent_ptr[0].pitch + upitch * DT, -0.95, 0.95)
    local cp = math.cos(pitch)
    local speed_scale = clamp((dg - GOAL_REACHED_RADIUS) / (GOAL_SLOW_RADIUS - GOAL_REACHED_RADIUS), 0.65, 1.0)
    local step_speed = SPEED * speed_scale

    agent_ptr[0].x = agent_ptr[0].x + cp * math.cos(yaw) * step_speed * DT
    agent_ptr[0].y = agent_ptr[0].y + math.sin(pitch) * step_speed * DT
    agent_ptr[0].z = agent_ptr[0].z + cp * math.sin(yaw) * step_speed * DT
    agent_ptr[0].yaw = yaw
    agent_ptr[0].pitch = pitch

    for t = 0, HORIZON - 2 do
        controls_ptr[t].uyaw = controls_ptr[t + 1].uyaw
        controls_ptr[t].upitch = controls_ptr[t + 1].upitch
    end
    controls_ptr[HORIZON - 1].uyaw = 0.0
    controls_ptr[HORIZON - 1].upitch = 0.0

    if trail_count < HORIZON then
        set_draw_point(agent_trail_ptr, trail_count, agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, 5.4, 0.2, 1.0, 0.35, 0.9)
        trail_count = trail_count + 1
    else
        for i = 0, HORIZON - 2 do
            agent_trail_ptr[i] = agent_trail_ptr[i + 1]
        end
        set_draw_point(agent_trail_ptr, HORIZON - 1, agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, 5.4, 0.2, 1.0, 0.35, 0.9)
        trail_count = HORIZON
    end

    local dxf = agent_ptr[0].x - gx
    local dyf = agent_ptr[0].y - gy
    local dzf = agent_ptr[0].z - gz
    local d2 = dxf * dxf + dyf * dyf + dzf * dzf
    if GOAL_HOLD_FRAMES > 0 and d2 < GOAL_REACHED_RADIUS * GOAL_REACHED_RADIUS then
        agent_ptr[0].x = gx
        agent_ptr[0].y = gy
        agent_ptr[0].z = gz
        goal_hold_frames_left = GOAL_HOLD_FRAMES
    end
end

function M.init()
    print("Example 17: MPPI (GPU rollouts, 3D Dubins-like control)")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    resource.init(device)

    ffi.cdef[[
        typedef struct Control { float uyaw, upitch; } Control;
        typedef struct AgentState { float x, y, z, yaw; float pitch, speed, pad0, pad1; } AgentState;
        typedef struct DrawPoint { float x, y, z, size; float r, g, b, a; } DrawPoint;

        typedef struct DrawPC {
            float mvp[16];
            uint32_t mode;
            uint32_t count;
            uint32_t pad0;
            uint32_t pad1;
        } DrawPC;

        typedef struct MppiPC {
            uint32_t samples;
            uint32_t horizon;
            uint32_t iter;
            uint32_t pad0;
            float dt;
            float noise_yaw;
            float noise_pitch;
            float speed;
            float goal_x, goal_y, goal_z, goal_r;
            float obs1_x, obs1_y, obs1_z, obs1_r;
            float obs2_x, obs2_y, obs2_z, obs2_r;
            float obs3_x, obs3_y, obs3_z, obs3_r;
            float obs4_x, obs4_y, obs4_z, obs4_r;
            float obs5_x, obs5_y, obs5_z, obs5_r;
            float obs6_x, obs6_y, obs6_z, obs6_r;
            float obs7_x, obs7_y, obs7_z, obs7_r;
            float obs8_x, obs8_y, obs8_z, obs8_r;
        } MppiPC;
    ]]

    push_draw_size = ffi.sizeof("DrawPC")

    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    local host_heap = heap.new(
        physical_device,
        device,
        heap.find_memory_type(physical_device, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)),
        512 * 1024 * 1024
    )

    local controls_size = ffi.sizeof("Control") * HORIZON
    local rollouts_size = ffi.sizeof("float") * (SAMPLES * HORIZON * 4)
    local costs_size = ffi.sizeof("float") * SAMPLES
    local best_size = ffi.sizeof("uint32_t") * 4
    local agent_size = ffi.sizeof("AgentState")
    local marker_size = ffi.sizeof("DrawPoint") * MARKER_CAP
    local path_size = ffi.sizeof("DrawPoint") * HORIZON
    local trail_size = ffi.sizeof("DrawPoint") * HORIZON
    local first_controls_size = ffi.sizeof("float") * SAMPLES * 2

    controls_buf = make_buffer(controls_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    rollouts_buf = make_buffer(rollouts_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    costs_buf = make_buffer(costs_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    best_buf = make_buffer(best_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    agent_buf = make_buffer(agent_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    marker_buf = make_buffer(marker_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    best_path_buf = make_buffer(path_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    agent_trail_buf = make_buffer(trail_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
    first_controls_buf = make_buffer(first_controls_size, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)

    local controls_alloc = host_heap:malloc(controls_size)
    local rollouts_alloc = host_heap:malloc(rollouts_size)
    local costs_alloc = host_heap:malloc(costs_size)
    local best_alloc = host_heap:malloc(best_size)
    local agent_alloc = host_heap:malloc(agent_size)
    local marker_alloc = host_heap:malloc(marker_size)
    local best_path_alloc = host_heap:malloc(path_size)
    local trail_alloc = host_heap:malloc(trail_size)
    local first_controls_alloc = host_heap:malloc(first_controls_size)

    vk.vkBindBufferMemory(device, controls_buf, controls_alloc.memory, controls_alloc.offset)
    vk.vkBindBufferMemory(device, rollouts_buf, rollouts_alloc.memory, rollouts_alloc.offset)
    vk.vkBindBufferMemory(device, costs_buf, costs_alloc.memory, costs_alloc.offset)
    vk.vkBindBufferMemory(device, best_buf, best_alloc.memory, best_alloc.offset)
    vk.vkBindBufferMemory(device, agent_buf, agent_alloc.memory, agent_alloc.offset)
    vk.vkBindBufferMemory(device, marker_buf, marker_alloc.memory, marker_alloc.offset)
    vk.vkBindBufferMemory(device, best_path_buf, best_path_alloc.memory, best_path_alloc.offset)
    vk.vkBindBufferMemory(device, agent_trail_buf, trail_alloc.memory, trail_alloc.offset)
    vk.vkBindBufferMemory(device, first_controls_buf, first_controls_alloc.memory, first_controls_alloc.offset)

    controls_ptr = ffi.cast("Control*", controls_alloc.ptr)
    rollouts_ptr = ffi.cast("float*", rollouts_alloc.ptr)
    costs_ptr = ffi.cast("float*", costs_alloc.ptr)
    best_ptr = ffi.cast("uint32_t*", best_alloc.ptr)
    agent_ptr = ffi.cast("AgentState*", agent_alloc.ptr)
    marker_ptr = ffi.cast("DrawPoint*", marker_alloc.ptr)
    best_path_ptr = ffi.cast("DrawPoint*", best_path_alloc.ptr)
    agent_trail_ptr = ffi.cast("DrawPoint*", trail_alloc.ptr)
    first_controls_ptr = ffi.cast("float*", first_controls_alloc.ptr)

    local bl_layout = descriptors.create_bindless_layout(device)
    local bl_pool = descriptors.create_bindless_pool(device)
    bindless_set = descriptors.allocate_sets(device, bl_pool, { bl_layout })[1]
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, controls_buf, 0, controls_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, rollouts_buf, 0, rollouts_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, costs_buf, 0, costs_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, best_buf, 0, best_size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, agent_buf, 0, agent_size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, marker_buf, 0, marker_size, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, best_path_buf, 0, path_size, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, agent_trail_buf, 0, trail_size, 7)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, first_controls_buf, 0, first_controls_size, 8)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[2]", {
        { stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("MppiPC") },
        { stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = push_draw_size },
    }))

    local mppi_mod = shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/mppi.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT))
    local draw_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local point_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local line_frag = shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    pipe_mppi = pipeline.create_compute_pipeline(device, layout_graph, mppi_mod)
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

    reset_agent()
end

function M.update()
    local ok, err = pcall(function()
        local ticks = tonumber(sdl.SDL_GetTicks())
        local elapsed = ticks - M.last_frame_time
        if elapsed < FRAME_TIME then
            sdl.SDL_Delay(FRAME_TIME - elapsed)
            ticks = tonumber(sdl.SDL_GetTicks())
        end
        M.last_frame_time = ticks
        M.current_time = M.current_time + 0.016

        local gx, gy, gz, obs = update_markers(M.current_time)

        if goal_hold_frames_left > 0 then
            goal_hold_frames_left = goal_hold_frames_left - 1
            if goal_hold_frames_left == 0 then
                reset_agent()
            end
        end

        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        best_ptr[0] = 0x7F7FFFFF
        best_ptr[1] = 0

        local ppc = ffi.new("MppiPC", {
            samples = SAMPLES,
            horizon = HORIZON,
            iter = iter,
            dt = DT,
            noise_yaw = NOISE_YAW,
            noise_pitch = NOISE_PITCH,
            speed = SPEED,
            goal_x = gx, goal_y = gy, goal_z = gz, goal_r = 1.0,
            obs1_x = obs[1][1], obs1_y = obs[1][2], obs1_z = obs[1][3], obs1_r = obs[1][4],
            obs2_x = obs[2][1], obs2_y = obs[2][2], obs2_z = obs[2][3], obs2_r = obs[2][4],
            obs3_x = obs[3][1], obs3_y = obs[3][2], obs3_z = obs[3][3], obs3_r = obs[3][4],
            obs4_x = obs[4][1], obs4_y = obs[4][2], obs4_z = obs[4][3], obs4_r = obs[4][4],
            obs5_x = obs[5][1], obs5_y = obs[5][2], obs5_z = obs[5][3], obs5_r = obs[5][4],
            obs6_x = obs[6][1], obs6_y = obs[6][2], obs6_z = obs[6][3], obs6_r = obs[6][4],
            obs7_x = obs[7][1], obs7_y = obs[7][2], obs7_z = obs[7][3], obs7_r = obs[7][4],
            obs8_x = obs[8][1], obs8_y = obs[8][2], obs8_z = obs[8][3], obs8_r = obs[8][4],
        })

        vk.vkResetCommandBuffer(planning_cb, 0)
        vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mppi)
        vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        vk.vkCmdPushConstants(planning_cb, layout_graph, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("MppiPC"), ppc)
        vk.vkCmdDispatch(planning_cb, math.ceil(SAMPLES / 256), 1, 1)
        vk.vkEndCommandBuffer(planning_cb)

        local submit_plan = ffi.new("VkSubmitInfo", {
            sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            commandBufferCount = 1,
            pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }),
        })
        vk.vkQueueSubmit(queue, 1, submit_plan, frame_fence)
        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

        local best_idx = tonumber(best_ptr[1])
        update_best_path_from_rollout(best_idx)
        if goal_hold_frames_left == 0 then
            apply_control_and_shift(best_idx, gx, gy, gz)
        end
        iter = iter + 1

        local dx = agent_ptr[0].x - gx
        local dy = agent_ptr[0].y - gy
        local dz = agent_ptr[0].z - gz

        if math.abs(agent_ptr[0].x) > 12.0 or math.abs(agent_ptr[0].y) > 6.0 or math.abs(agent_ptr[0].z) > 12.0 then
            reset_agent()
        end

        local idx = sw:acquire_next_image(image_available)
        if idx == nil then return end

        local cb = draw_cbs[idx + 1]
        vk.vkResetCommandBuffer(cb, 0)
        vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

        local view = math_utils.look_at({ math.cos(M.angle) * 22.0, 10.0, math.sin(M.angle) * 22.0 }, { 0, 0, 0 }, { 0, 1, 0 })
        local proj = math_utils.perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 120.0)
        local mvp = math_utils.multiply(proj, view)
        M.angle = M.angle + 0.003

        local dpc = ffi.new("DrawPC")
        for i = 1, 16 do dpc.mvp[i - 1] = mvp[i] end

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

        dpc.mode = 0
        dpc.count = MARKER_CAP
        vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_draw_size, dpc)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
        vk.vkCmdDraw(cb, MARKER_CAP, 1, 0, 0)

        if best_path_count > 1 then
            dpc.mode = 1
            dpc.count = best_path_count
            vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_draw_size, dpc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
            vk.vkCmdDraw(cb, best_path_count, 1, 0, 0)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
            vk.vkCmdDraw(cb, best_path_count, 1, 0, 0)
        end

        if trail_count > 1 then
            dpc.mode = 2
            dpc.count = trail_count
            vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, push_draw_size, dpc)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
            vk.vkCmdDraw(cb, trail_count, 1, 0, 0)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
            vk.vkCmdDraw(cb, trail_count, 1, 0, 0)
        end

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
