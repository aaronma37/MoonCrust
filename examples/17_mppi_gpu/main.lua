local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
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
local SPEED = 3.6
local TURN_GAIN = 1.6
local NOISE_YAW = 0.9
local NOISE_PITCH = 0.45
local GOAL_REACHED_RADIUS = 0.45
local GOAL_SLOW_RADIUS = 1.4
local GOAL_HOLD_FRAMES = 0
local MARKER_CAP = 800
local ENABLE_DEPTH = (os.getenv("MC_ENABLE_DEPTH") == "1")

local device, queue, graphics_family, sw
local layout_graph, bindless_set
local pipe_mppi, pipe_points, pipe_lines, pipe_plane
local controls_ptr, rollouts_ptr, costs_ptr, best_ptr, agent_ptr
local marker_ptr, best_path_ptr, agent_trail_ptr, first_controls_ptr
local image_available, cb, planning_cb, frame_fence
local depth_img, depth_format
local render_pass, framebuffers
local iter = 0
local best_path_count = 0
local trail_count = 0
local goal_hold_frames_left = 0
local active_hoop_idx = 1
local active_hoop_started_t = 0.0
local sw_image_initialized = {}
local frame_no = 0
local device_lost = false

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local s = f:read("*all"); f:close()
    return s
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].size = x, y, z, size
    ptr[i].r, ptr[i].g, ptr[i].b, ptr[i].a = r, g, b, a
end

local function reset_agent()
    agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, agent_ptr[0].yaw, agent_ptr[0].pitch, agent_ptr[0].speed = -8.5, -1.2, -8.5, 0.85, 0.02, SPEED
    for t = 0, HORIZON - 1 do controls_ptr[t].uyaw, controls_ptr[t].upitch = 0.0, 0.0 end
    trail_count, best_path_count = 0, 0
    active_hoop_idx = 1
    active_hoop_started_t = M.current_time
end

local function hoop_axes(mode)
    if mode == 1 then return {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}, {1.0, 0.0, 0.0} end
    if mode == 2 then return {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0} end
    if mode == 3 then local k = 0.70710678; return {k, 0.0, -k}, {0.0, 1.0, 0.0}, {k, 0.0, k} end
    local k = 0.70710678; return {k, 0.0, k}, {0.0, 1.0, 0.0}, {k, 0.0, -k}
end

local function hoop_passed(h)
    local _, _, n = hoop_axes(h[5])
    local dx, dy, dz = agent_ptr[0].x - h[1], agent_ptr[0].y - h[2], agent_ptr[0].z - h[3]
    local plane = dx * n[1] + dy * n[2] + dz * n[3]
    local rx = dx - plane * n[1]
    local ry = dy - plane * n[2]
    local rz = dz - plane * n[3]
    local radial = math.sqrt(rx * rx + ry * ry + rz * rz)
    return math.abs(plane) < 0.38 and radial < (h[4] - 0.42)
end

local function build_hoops(t)
    return {
        { math.sin(t * 0.47) * 4.6, 0.6 + math.cos(t * 0.31) * 1.0, math.cos(t * 0.47) * 4.6, 1.55, 1 },
        { math.sin(t * 0.33 + 2.0) * 6.1, math.sin(t * 0.27) * 1.4, math.cos(t * 0.33 + 2.0) * 6.0, 1.45, 2 },
        { math.sin(t * 0.58 + 1.2) * 5.1, math.cos(t * 0.41 + 0.5) * 1.2, math.cos(t * 0.58 + 1.2) * 5.3, 1.50, 3 },
        { math.sin(t * 0.39 + 3.7) * 7.1, math.cos(t * 0.36) * 1.3, math.cos(t * 0.39 + 3.7) * 6.9, 1.60, 4 },
    }
end

local function active_hoop_goal(h)
    local _, _, n = hoop_axes(h[5])
    local dx, dy, dz = agent_ptr[0].x - h[1], agent_ptr[0].y - h[2], agent_ptr[0].z - h[3]
    local plane = dx * n[1] + dy * n[2] + dz * n[3]
    local rx = dx - plane * n[1]
    local ry = dy - plane * n[2]
    local rz = dz - plane * n[3]
    local radial = math.sqrt(rx * rx + ry * ry + rz * rz)

    local hole_r = h[4] - 0.42
    local staged = (math.abs(plane) > 0.35) or (radial > hole_r * 0.9)
    if staged then
        local sgn = (plane >= 0.0) and 1.0 or -1.0
        local off = 0.95
        return h[1] + n[1] * sgn * off, h[2] + n[2] * sgn * off, h[3] + n[3] * sgn * off
    end
    return h[1], h[2], h[3]
end

local function update_markers(t, active_idx, gx, gy, gz, hoops)
    local sx, sy, sz = agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z
    set_draw_point(marker_ptr, 0, sx, sy, sz, 11.0, 0.2, 1.0, 0.3, 1.0)
    local aidx = ((active_idx - 1) % #hoops) + 1
    set_draw_point(marker_ptr, 1, gx, gy, gz, 13.0, 1.0, 1.0, 0.2, 1.0)
    local plane = {
        2.6 + math.sin(t * 0.19 + 1.0) * 1.0,
        -0.35 + math.cos(t * 0.17) * 0.45,
        2.4 + math.sin(t * 0.14 + 0.6) * 0.7,
        0.36
    }
    local plane2 = {
        -3.0 + math.sin(t * 0.33 + 0.7) * 1.0,
        0.55 + math.sin(t * 0.28 + 2.1) * 0.7,
        -2.8 + math.cos(t * 0.22 - 0.4) * 0.9,
        0.34
    }
    local idx, segs = 2, 44
    for i = 1, #hoops do
        local h = hoops[i]
        local u, v = hoop_axes(h[5])
        local rr, gg, bb = 1.0, 0.24, 0.18
        if i == aidx then rr, gg, bb = 0.2, 1.0, 0.9 end
        for s = 0, segs - 1 do
            if idx >= MARKER_CAP then break end
            local a = (s / segs) * (2.0 * math.pi)
            local ca, sa = math.cos(a), math.sin(a)
            local x = h[1] + (u[1] * ca + v[1] * sa) * h[4]
            local y = h[2] + (u[2] * ca + v[2] * sa) * h[4]
            local z = h[3] + (u[3] * ca + v[3] * sa) * h[4]
            set_draw_point(marker_ptr, idx, x, y, z, 4.8, rr, gg, bb, 0.96)
            idx = idx + 1
        end
    end
    local hy, hz = 1.2, 2.0
    for layer = -1, 1 do
        local px = plane[1] + layer * 0.11
        for yi = 0, 18 do
            local py = plane[2] - hy + (yi / 18.0) * (2.0 * hy)
            for zi = 0, 32 do
            if idx >= MARKER_CAP then break end
                local pz = plane[3] - hz + (zi / 32.0) * (2.0 * hz)
                set_draw_point(marker_ptr, idx, px, py, pz, 5.2, 0.96, 0.10, 0.10, 0.95)
                idx = idx + 1
            end
            if idx >= MARKER_CAP then break end
        end
        if idx >= MARKER_CAP then break end
    end
    for i = idx, MARKER_CAP - 1 do set_draw_point(marker_ptr, i, 0.0, -1000.0, 0.0, 0.1, 0.0, 0.0, 0.0, 0.0) end
    return gx, gy, gz, hoops, plane, plane2
end

local function update_best_path_from_rollout(best_idx)
    best_path_count = 0; if best_idx < 0 or best_idx >= SAMPLES then return end
    for t = 0, HORIZON - 1 do
        local b = (best_idx * HORIZON + t) * 4
        set_draw_point(best_path_ptr, t, rollouts_ptr[b + 0], rollouts_ptr[b + 1], rollouts_ptr[b + 2], 6.2, 3.8, 2.8, 0.35, 0.95)
        best_path_count = best_path_count + 1
    end
end

local function apply_control_and_shift(best_idx, gx, gy, gz)
    if best_idx < 0 or best_idx >= SAMPLES then return end
    local fbase = best_idx * 2
    local uyaw, upitch = first_controls_ptr[fbase + 0], first_controls_ptr[fbase + 1]
    local dxg, dyg, dzg = gx - agent_ptr[0].x, gy - agent_ptr[0].y, gz - agent_ptr[0].z
    local dg = math.sqrt(dxg * dxg + dyg * dyg + dzg * dzg)
    local yaw, pitch = agent_ptr[0].yaw + uyaw * DT * TURN_GAIN, clamp(agent_ptr[0].pitch + upitch * DT * TURN_GAIN, -0.95, 0.95)
    local cp, step_speed = math.cos(pitch), SPEED * clamp((dg - GOAL_REACHED_RADIUS) / (GOAL_SLOW_RADIUS - GOAL_REACHED_RADIUS), 0.65, 1.0)
    agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, agent_ptr[0].yaw, agent_ptr[0].pitch = agent_ptr[0].x + cp * math.cos(yaw) * step_speed * DT, agent_ptr[0].y + math.sin(pitch) * step_speed * DT, agent_ptr[0].z + cp * math.sin(yaw) * step_speed * DT, yaw, pitch
    for t = 0, HORIZON - 2 do controls_ptr[t].uyaw, controls_ptr[t].upitch = controls_ptr[t + 1].uyaw, controls_ptr[t + 1].upitch end
    controls_ptr[HORIZON - 1].uyaw, controls_ptr[HORIZON - 1].upitch = 0.0, 0.0
    if trail_count < HORIZON then set_draw_point(agent_trail_ptr, trail_count, agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, 5.4, 0.2, 1.0, 0.35, 0.9); trail_count = trail_count + 1 else for i = 0, HORIZON - 2 do agent_trail_ptr[i] = agent_trail_ptr[i + 1] end; set_draw_point(agent_trail_ptr, HORIZON - 1, agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, 5.4, 0.2, 1.0, 0.35, 0.9); trail_count = HORIZON end
    if GOAL_HOLD_FRAMES > 0 and (agent_ptr[0].x - gx)^2 + (agent_ptr[0].y - gy)^2 + (agent_ptr[0].z - gz)^2 < GOAL_REACHED_RADIUS^2 then agent_ptr[0].x, agent_ptr[0].y, agent_ptr[0].z, goal_hold_frames_left = gx, gy, gz, GOAL_HOLD_FRAMES end
end

function M.init()
    print("Example 17: MPPI Controller (using mc.gpu StdLib)")
    print("Depth enabled:", ENABLE_DEPTH)
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    if ENABLE_DEPTH then
        depth_format = image.find_depth_format(physical_device)
        depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")
    else
        depth_format = vk.VK_FORMAT_UNDEFINED
        depth_img = nil
    end
    ffi.cdef[[
        typedef struct Control { float uyaw, upitch; } Control;
        typedef struct AgentState { float x, y, z, yaw, pitch, speed, pad0, pad1; } AgentState;
        typedef struct DrawPoint { float x, y, z, size, r, g, b, a; } DrawPoint;
        typedef struct DrawPC {
            float mvp[16];
            uint32_t mode, count, pad0, pad1;
            float plane_x, plane_y, plane_z, plane_hy, plane_hz, plane_pad0, plane_pad1, plane_pad2;
            float cam_x, cam_y, cam_z, occ_pad0;
            float occ1_x, occ1_y, occ1_z, occ1_hy, occ1_hz, occ1_pad0, occ1_pad1, occ1_pad2;
            float occ2_x, occ2_y, occ2_z, occ2_hy, occ2_hz, occ2_pad0, occ2_pad1, occ2_pad2;
        } DrawPC;
        typedef struct MppiPC { uint32_t samples, horizon, iter, pad0; float dt, noise_yaw, noise_pitch, speed, goal_x, goal_y, goal_z, goal_r, obs1_x, obs1_y, obs1_z, obs1_r, obs2_x, obs2_y, obs2_z, obs2_r, obs3_x, obs3_y, obs3_z, obs3_r, obs4_x, obs4_y, obs4_z, obs4_r, obs5_x, obs5_y, obs5_z, obs5_r, obs6_x, obs6_y, obs6_z, obs6_r, obs7_x, obs7_y, obs7_z, obs7_r, obs8_x, obs8_y, obs8_z, obs8_r; } MppiPC;
    ]]

    -- 1. Use mc.buffer factories
    local c_sz, r_sz, k_sz, b_sz, a_sz, m_sz, p_sz, t_sz, f_sz = ffi.sizeof("Control") * HORIZON, ffi.sizeof("float") * (SAMPLES * HORIZON * 4), ffi.sizeof("float") * SAMPLES, ffi.sizeof("uint32_t") * 4, ffi.sizeof("AgentState"), ffi.sizeof("DrawPoint") * MARKER_CAP, ffi.sizeof("DrawPoint") * HORIZON, ffi.sizeof("DrawPoint") * HORIZON, ffi.sizeof("float") * SAMPLES * 2
    local b_c, b_r, b_k, b_b, b_a, b_m, b_p, b_t, b_f = mc.buffer(c_sz, "storage", nil, true), mc.buffer(r_sz, "storage", nil, true), mc.buffer(k_sz, "storage", nil, true), mc.buffer(b_sz, "storage", nil, true), mc.buffer(a_sz, "storage", nil, true), mc.buffer(m_sz, "storage", nil, true), mc.buffer(p_sz, "storage", nil, true), mc.buffer(t_sz, "storage", nil, true), mc.buffer(f_sz, "storage", nil, true)

    controls_ptr, rollouts_ptr, costs_ptr, best_ptr, agent_ptr, marker_ptr, best_path_ptr, agent_trail_ptr, first_controls_ptr = ffi.cast("Control*", b_c.allocation.ptr), ffi.cast("float*", b_r.allocation.ptr), ffi.cast("float*", b_k.allocation.ptr), ffi.cast("uint32_t*", b_b.allocation.ptr), ffi.cast("AgentState*", b_a.allocation.ptr), ffi.cast("DrawPoint*", b_m.allocation.ptr), ffi.cast("DrawPoint*", b_p.allocation.ptr), ffi.cast("DrawPoint*", b_t.allocation.ptr), ffi.cast("float*", b_f.allocation.ptr)

    -- 2. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_c.handle, 0, c_sz, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_r.handle, 0, r_sz, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_k.handle, 0, k_sz, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_b.handle, 0, b_sz, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_a.handle, 0, a_sz, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_m.handle, 0, m_sz, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_p.handle, 0, p_sz, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_t.handle, 0, t_sz, 7)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_f.handle, 0, f_sz, 8)

    -- 3. Pipelines
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[2]", {{
        stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT,
        offset = 0,
        size = ffi.sizeof("MppiPC")
    }, {
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT),
        offset = 0,
        size = ffi.sizeof("DrawPC")
    }}))
    pipe_mppi = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/mppi.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local d_v = shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local att_count = ENABLE_DEPTH and 2 or 1
    local attachments = ffi.new("VkAttachmentDescription[2]")
    attachments[0].format = vk.VK_FORMAT_B8G8R8A8_SRGB
    attachments[0].samples = vk.VK_SAMPLE_COUNT_1_BIT
    attachments[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    attachments[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    attachments[0].stencilLoadOp = vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE
    attachments[0].stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE
    attachments[0].initialLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    attachments[0].finalLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    if ENABLE_DEPTH then
        attachments[1].format = depth_format
        attachments[1].samples = vk.VK_SAMPLE_COUNT_1_BIT
        attachments[1].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        attachments[1].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        attachments[1].stencilLoadOp = vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE
        attachments[1].stencilStoreOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE
        attachments[1].initialLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
        attachments[1].finalLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    end
    local color_ref = ffi.new("VkAttachmentReference", { attachment = 0, layout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL })
    local depth_ref = ffi.new("VkAttachmentReference", { attachment = 1, layout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL })
    local subpass = ffi.new("VkSubpassDescription[1]")
    subpass[0].pipelineBindPoint = vk.VK_PIPELINE_BIND_POINT_GRAPHICS
    subpass[0].colorAttachmentCount = 1
    subpass[0].pColorAttachments = color_ref
    subpass[0].pDepthStencilAttachment = ENABLE_DEPTH and depth_ref or nil
    local rp_info = ffi.new("VkRenderPassCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        attachmentCount = att_count,
        pAttachments = attachments,
        subpassCount = 1,
        pSubpasses = subpass,
    })
    local pRP = ffi.new("VkRenderPass[1]")
    local rp_res = vk.vkCreateRenderPass(device, rp_info, nil, pRP)
    if rp_res ~= vk.VK_SUCCESS then error("vkCreateRenderPass failed: " .. tostring(rp_res)) end
    render_pass = pRP[0]
    framebuffers = {}
    for i = 0, sw.image_count - 1 do
        local fb_atts = ffi.new("VkImageView[2]", { ffi.cast("VkImageView", sw.views[i]), ENABLE_DEPTH and depth_img.view or nil })
        local fb_info = ffi.new("VkFramebufferCreateInfo", {
            sType = vk.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            renderPass = render_pass,
            attachmentCount = att_count,
            pAttachments = fb_atts,
            width = sw.extent.width,
            height = sw.extent.height,
            layers = 1,
        })
        local pFB = ffi.new("VkFramebuffer[1]")
        local fb_res = vk.vkCreateFramebuffer(device, fb_info, nil, pFB)
        if fb_res ~= vk.VK_SUCCESS then error("vkCreateFramebuffer failed: " .. tostring(fb_res)) end
        framebuffers[i + 1] = pFB[0]
    end
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true, render_pass = render_pass, depth_test = ENABLE_DEPTH, depth_write = false, depth_format = depth_format })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true, render_pass = render_pass, depth_test = ENABLE_DEPTH, depth_write = false, depth_format = depth_format })
    pipe_plane = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/plane.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(read_text("examples/17_mppi_gpu/plane.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, cull_mode = vk.VK_CULL_MODE_NONE, render_pass = render_pass, depth_test = ENABLE_DEPTH, depth_write = ENABLE_DEPTH, depth_format = depth_format })

    -- 4. Sync
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cb, planning_cb = command.allocate_buffers(device, pool, 1)[1], command.allocate_buffers(device, pool, 1)[1]
    if ENABLE_DEPTH then
        local init_cb = command.allocate_buffers(device, pool, 1)[1]
        vk.vkBeginCommandBuffer(init_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        local dbar = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            image = depth_img.handle,
            subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 },
            srcAccessMask = 0,
            dstAccessMask = bit.bor(vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT),
        }})
        vk.vkCmdPipelineBarrier(init_cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, 0, 0, nil, 0, nil, 1, dbar)
        vk.vkEndCommandBuffer(init_cb)
        vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { init_cb }) }), nil)
        vk.vkQueueWaitIdle(queue)
    end
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    reset_agent()
end

function M.update()
 if device_lost then return end
 frame_no = frame_no + 1
 M.current_time = M.current_time + 0.016
    local hoops = build_hoops(M.current_time)
    local ai = ((active_hoop_idx - 1) % #hoops) + 1
    local gx, gy, gz = active_hoop_goal(hoops[ai])
    local _, _, _, _, plane, plane2 = update_markers(M.current_time, active_hoop_idx, gx, gy, gz, hoops)
    if goal_hold_frames_left > 0 then goal_hold_frames_left = goal_hold_frames_left - 1; if goal_hold_frames_left == 0 then reset_agent() end end
    local wait0 = vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); if wait0 ~= vk.VK_SUCCESS then print("M17 wait0:", tonumber(wait0)); if wait0 == vk.VK_ERROR_DEVICE_LOST then device_lost = true end; return end; vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    best_ptr[0], best_ptr[1] = 0x7F7FFFFF, 0
    ai = ((active_hoop_idx - 1) % #hoops) + 1
    local bi = (ai % #hoops) + 1
    local ci = (bi % #hoops) + 1
    local di = (ci % #hoops) + 1
    local ppc = ffi.new("MppiPC", { samples = SAMPLES, horizon = HORIZON, iter = iter, dt = DT, noise_yaw = NOISE_YAW, noise_pitch = NOISE_PITCH, speed = SPEED, goal_x = gx, goal_y = gy, goal_z = gz, goal_r = 1.0, obs1_x = hoops[ai][1], obs1_y = hoops[ai][2], obs1_z = hoops[ai][3], obs1_r = hoops[ai][4], obs2_x = hoops[bi][1], obs2_y = hoops[bi][2], obs2_z = hoops[bi][3], obs2_r = hoops[bi][4], obs3_x = hoops[ci][1], obs3_y = hoops[ci][2], obs3_z = hoops[ci][3], obs3_r = hoops[ci][4], obs4_x = hoops[di][1], obs4_y = hoops[di][2], obs4_z = hoops[di][3], obs4_r = hoops[di][4], obs5_x = 0.0, obs5_y = 0.0, obs5_z = 0.0, obs5_r = 0.0, obs6_x = 0.0, obs6_y = 0.0, obs6_z = 0.0, obs6_r = 0.0, obs7_x = plane2[1], obs7_y = plane2[2], obs7_z = plane2[3], obs7_r = plane2[4], obs8_x = plane[1], obs8_y = plane[2], obs8_z = plane[3], obs8_r = plane[4] })
    vk.vkResetCommandBuffer(planning_cb, 0); vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO })); vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mppi); vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil); vk.vkCmdPushConstants(planning_cb, layout_graph, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("MppiPC"), ppc); vk.vkCmdDispatch(planning_cb, math.ceil(SAMPLES / 256), 1, 1); vk.vkEndCommandBuffer(planning_cb); local sub0 = vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }) }), frame_fence); if sub0 ~= vk.VK_SUCCESS then print("M17 sub0:", tonumber(sub0)); if sub0 == vk.VK_ERROR_DEVICE_LOST then device_lost = true end; return end; local wait1 = vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); if wait1 ~= vk.VK_SUCCESS then print("M17 wait1:", tonumber(wait1)); if wait1 == vk.VK_ERROR_DEVICE_LOST then device_lost = true end; return end; vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local best_idx = tonumber(best_ptr[1]); update_best_path_from_rollout(best_idx); if goal_hold_frames_left == 0 then apply_control_and_shift(best_idx, gx, gy, gz) end; if hoop_passed(hoops[ai]) or (M.current_time - active_hoop_started_t > 4.2) then active_hoop_idx = (active_hoop_idx % #hoops) + 1; active_hoop_started_t = M.current_time end; iter = iter + 1
    if math.abs(agent_ptr[0].x) > 12.0 or math.abs(agent_ptr[0].y) > 6.0 or math.abs(agent_ptr[0].z) > 12.0 then reset_agent() end
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local cam_x, cam_y, cam_z = math.cos(M.angle) * 22.0, 10.0, math.sin(M.angle) * 22.0
    local view = mc.mat4_look_at({ cam_x, cam_y, cam_z }, { 0, 0, 0 }, { 0, 1, 0 }); local proj = mc.mat4_perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 120.0); local mvp = mc.mat4_multiply(proj, view); M.angle = M.angle + 0.003
    local dpc = ffi.new("DrawPC"); for i = 1, 16 do dpc.mvp[i - 1] = mvp.m[i - 1] end
    dpc.cam_x, dpc.cam_y, dpc.cam_z = cam_x, cam_y, cam_z
    dpc.occ1_x, dpc.occ1_y, dpc.occ1_z, dpc.occ1_hy, dpc.occ1_hz = plane[1], plane[2], plane[3], 1.2, 2.0
    dpc.occ2_x, dpc.occ2_y, dpc.occ2_z, dpc.occ2_hy, dpc.occ2_hz = plane2[1], plane2[2], plane2[3], 1.0, 1.7
    local old_color = sw_image_initialized[idx] and vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR or vk.VK_IMAGE_LAYOUT_UNDEFINED
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = old_color, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local clear_values = ffi.new("VkClearValue[2]")
    clear_values[0].color.float32 = { 0.008, 0.008, 0.015, 1.0 }
    clear_values[1].depthStencil.depth = 1.0
    clear_values[1].depthStencil.stencil = 0
    vk.vkCmdBeginRenderPass(cb, ffi.new("VkRenderPassBeginInfo", {
        sType = vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        renderPass = render_pass,
        framebuffer = framebuffers[idx + 1],
        renderArea = { extent = sw.extent },
        clearValueCount = ENABLE_DEPTH and 2 or 1,
        pClearValues = clear_values,
    }), vk.VK_SUBPASS_CONTENTS_INLINE); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent })); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    local d1 = (cam_x - plane[1]) * (cam_x - plane[1]) + (cam_y - plane[2]) * (cam_y - plane[2]) + (cam_z - plane[3]) * (cam_z - plane[3])
    local d2 = (cam_x - plane2[1]) * (cam_x - plane2[1]) + (cam_y - plane2[2]) * (cam_y - plane2[2]) + (cam_z - plane2[3]) * (cam_z - plane2[3])
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_plane)
    if d1 > d2 then
        dpc.mode, dpc.count, dpc.plane_x, dpc.plane_y, dpc.plane_z, dpc.plane_hy, dpc.plane_hz = 3, 6, plane[1], plane[2], plane[3], 1.2, 2.0; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdDraw(cb, 6, 1, 0, 0)
        dpc.mode, dpc.count, dpc.plane_x, dpc.plane_y, dpc.plane_z, dpc.plane_hy, dpc.plane_hz = 3, 6, plane2[1], plane2[2], plane2[3], 1.0, 1.7; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdDraw(cb, 6, 1, 0, 0)
    else
        dpc.mode, dpc.count, dpc.plane_x, dpc.plane_y, dpc.plane_z, dpc.plane_hy, dpc.plane_hz = 3, 6, plane2[1], plane2[2], plane2[3], 1.0, 1.7; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdDraw(cb, 6, 1, 0, 0)
        dpc.mode, dpc.count, dpc.plane_x, dpc.plane_y, dpc.plane_z, dpc.plane_hy, dpc.plane_hz = 3, 6, plane[1], plane[2], plane[3], 1.2, 2.0; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdDraw(cb, 6, 1, 0, 0)
    end
    dpc.mode, dpc.count = 0, MARKER_CAP; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, MARKER_CAP, 1, 0, 0)
    if best_path_count > 1 then dpc.mode, dpc.count = 1, best_path_count; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines); vk.vkCmdDraw(cb, best_path_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, best_path_count, 1, 0, 0) end
    if trail_count > 1 then dpc.mode, dpc.count = 2, trail_count; vk.vkCmdPushConstants(cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("DrawPC"), dpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines); vk.vkCmdDraw(cb, trail_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, trail_count, 1, 0, 0) end
    vk.vkCmdEndRenderPass(cb); bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb); sw_image_initialized[idx] = true
    local sub1 = vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); if sub1 ~= vk.VK_SUCCESS then print("M17 sub1:", tonumber(sub1)); if sub1 == vk.VK_ERROR_DEVICE_LOST then device_lost = true end; return end; if frame_no == 1 then print("M17 frame1 submit/present") end; sw:present(queue, idx, sw.semaphores[idx])
end

return M
