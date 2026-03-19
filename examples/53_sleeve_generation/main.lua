local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local command = require("vulkan.command")
local input = require("mc.input")
local bit = require("bit")
local sdl = require("vulkan.sdl")
local descriptors = require("vulkan.descriptors")

local skeleton = require("examples.53_sleeve_generation.skeleton")
local mesher = require("examples.53_sleeve_generation.mesher")
local dae = require("examples.53_sleeve_generation.dae_loader")

local M = { 
    orbit_radius = 25,
    orbit_yaw = 0,
    orbit_pitch = 0.3,
    target_pos = {0, 8, 0},
    time = 0,
    anim_state = "rest",
    gravity_mode = 1,
    last_frame_time = 0
}

local device, queue, sw, graphics_pipe, pipe_layout
local compute_pipe, compute_layout
local depth_img, vbuf, ibuf, idx_count, pick_buf
local bone_buf, param_buf, ds_pool
local cbs, image_available_sem, frame_fence

local bones, segments
local RINGS_PER_BONE = 16
local VERTS_PER_RING = 32

local animations = {}

function M.init()
    print("Example 53: Neurosymbolic Mesh Rings (Dynamic Meshing)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    local q, family = vulkan.get_queue()
    queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")

    bones = skeleton.get_bone_list()
    segments = mesher.calculate_bone_segments(bones)
    idx_count = #mesher.generate_indices(#segments, RINGS_PER_BONE, VERTS_PER_RING)

    animations.walking = dae.load_animations("examples/53_sleeve_generation/Walking.dae")

    local v_size = #segments * RINGS_PER_BONE * VERTS_PER_RING * ffi.sizeof("MeshVertex")
    local i_size = idx_count * 4
    vbuf = mc.gpu.buffer(v_size, "vertex_storage", nil, true)
    ibuf = mc.gpu.buffer(i_size, "index", ffi.new("uint32_t[?]", idx_count, mesher.generate_indices(#segments, RINGS_PER_BONE, VERTS_PER_RING)), true)
    bone_buf = mc.gpu.buffer(#segments * ffi.sizeof("MeshBone"), "storage", nil, true)
    param_buf = mc.gpu.buffer(#segments * RINGS_PER_BONE * ffi.sizeof("MeshRingParams"), "storage", mesher.create_params(#segments, RINGS_PER_BONE, segments), true)
    
    -- SOFT BODY SETUP
    M.soft_bodies = {
        -- Breasts (Attached to Spine2)
        { name = "breast_L", bone = "mixamorig_Spine2", local_anchor = { 0.65, 0.5, 1.0 }, radius = 0.45, k = 1.5, vel = {0,0,0}, pos = {0,0,0}, side = 1 },
        { name = "breast_R", bone = "mixamorig_Spine2", local_anchor = { -0.65, 0.5, 1.0 }, radius = 0.45, k = 1.5, vel = {0,0,0}, pos = {0,0,0}, side = -1 },
        -- Glutes (Attached to Hips)
        { name = "butt_L", bone = "mixamorig_Hips", local_anchor = { 1.0, -1.0, -1.2 }, radius = 1.0, k = 1.0, vel = {0,0,0}, pos = {0,0,0}, side = 1 },
        { name = "butt_R", bone = "mixamorig_Hips", local_anchor = { -1.0, -1.0, -1.2 }, radius = 1.0, k = 1.0, vel = {0,0,0}, pos = {0,0,0}, side = -1 },
    }
    M.soft_body_buf = mc.gpu.buffer(#M.soft_bodies * ffi.sizeof("SoftBody"), "storage", nil, true)

    -- GPU PICKING BUFFER (Host visible for easy reading)
    pick_buf = mc.gpu.buffer(4, "storage", nil, true)
    local clear_id = ffi.new("uint32_t[1]", {0xFFFFFFFF})
    pick_buf:upload(clear_id)

    local get_dir = function() return "examples/53_sleeve_generation/" end
    ds_pool = descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }})

    local c_bindings = {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }
    }
    local c_ds_layout = descriptors.create_layout(device, c_bindings)
    compute_layout = pipeline.create_layout(device, {c_ds_layout}, { { stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 20 } })
    local c_src = io.open(get_dir().."mesher.comp"):read("*all")
    compute_pipe = pipeline.create_compute_pipeline(device, compute_layout, shader.create_module(device, shader.compile_glsl(c_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    local g_bindings = {
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT }
    }
    local g_ds_layout = descriptors.create_layout(device, g_bindings)
    pipe_layout = pipeline.create_layout(device, {g_ds_layout}, { { stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 144 } })

    ffi.cdef[[ typedef struct PC { float mvp[16]; float model[16]; float mouse_pos[2]; } PC; ]]
    local v_src = io.open(get_dir().."render.vert"):read("*all")
    local f_src = io.open(get_dir().."render.frag"):read("*all")
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = ffi.sizeof("MeshVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[5]", {
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 16 },
            { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 32 },
            { location = 3, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 48 },
            { location = 4, binding = 0, format = vk.VK_FORMAT_R32G32B32_UINT, offset = 64 }
        }),
        vertex_attribute_count = 5, depth_test = true, depth_write = true, depth_format = depth_format, cull_mode = vk.VK_CULL_MODE_NONE
    })

    M.c_ds = descriptors.allocate_sets(device, ds_pool, {c_ds_layout})[1]
    M.g_ds = descriptors.allocate_sets(device, ds_pool, {g_ds_layout})[1]
    descriptors.update_buffer_set(device, M.c_ds, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, vbuf.handle, 0, v_size)
    descriptors.update_buffer_set(device, M.c_ds, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, bone_buf.handle, 0, #segments * ffi.sizeof("MeshBone"))
    descriptors.update_buffer_set(device, M.c_ds, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, param_buf.handle, 0, #segments * RINGS_PER_BONE * ffi.sizeof("MeshRingParams"))
    descriptors.update_buffer_set(device, M.c_ds, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.soft_body_buf.handle, 0, #M.soft_bodies * ffi.sizeof("SoftBody"))
    descriptors.update_buffer_set(device, M.g_ds, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pick_buf.handle, 0, 4)

    cbs = command.allocate_buffers(device, command.create_pool(device, family), sw.image_count)
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available_sem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sem); image_available_sem = image_available_sem[0]
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
    
    local inv_bind_mats = {}
    for _, b in ipairs(bones) do
        local cm_mat = mc.mat4_identity()
        for row=0,3 do for col=0,3 do cm_mat.m[col*4 + row] = b.global_mat[row*4 + col + 1] end end
        cm_mat.m[12], cm_mat.m[13], cm_mat.m[14] = cm_mat.m[12]*0.1, cm_mat.m[13]*0.1, cm_mat.m[14]*0.1
        inv_bind_mats[b.id] = mc.mat4_inverse(cm_mat)
    end
    M.inv_bind_mats = inv_bind_mats
end

local function lerp_mat(a, b, t)
    local out = {}
    for i=1,16 do out[i] = (a[i] or 0) + ((b[i] or 0) - (a[i] or 0)) * t end
    return out
end

local function get_animated_matrix(bone_name, anim, time)
    if not anim or not anim.channels[bone_name] then return nil end
    local chan = anim.channels[bone_name]
    local t = time % anim.duration
    local idx1, idx2 = 1, 1
    for i=1, #chan.times do if chan.times[i] > t then idx2 = i; idx1 = math.max(1, i-1); break end end
    local t1, t2 = chan.times[idx1], chan.times[idx2]
    local f = 0; if t2 > t1 then f = (t - t1) / (t2 - t1) end
    return lerp_mat(chan.matrices[idx1], chan.matrices[idx2], f)
end

function M.update()
    local dt = (tonumber(sdl.SDL_GetTicks()) - M.last_frame_time) / 1000.0
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
    M.time = M.time + dt
    
    if input.key_pressed(input.SCANCODE_1) then M.anim_state = "rest" end
    if input.key_pressed(input.SCANCODE_2) then M.anim_state = "walking" end
    if input.key_pressed(input.SCANCODE_3) then M.diagnostic = not M.diagnostic end

    if input.key_pressed(input.SCANCODE_G) then
        M.gravity_mode = (M.gravity_mode % 3) + 1
        local modes = {"NORMAL (-30)", "HEAVY (-150)", "INVERTED (+50)"}
        print("GRAVITY MODE: " .. modes[M.gravity_mode])
    end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available_sem)
    if idx == nil then return end

    if _G._MOUSE_L then
        local dx, dy = input.mouse_delta()
        M.orbit_yaw, M.orbit_pitch = M.orbit_yaw - dx * 0.01, math.max(-math.pi/2+0.1, math.min(math.pi/2-0.1, M.orbit_pitch + dy * 0.01))
    end
    local cam_x = M.target_pos[1] + math.sin(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local cam_y = M.target_pos[2] + math.sin(M.orbit_pitch) * M.orbit_radius
    local cam_z = M.target_pos[3] + math.cos(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local view = mc.mat4_look_at({cam_x, cam_y, cam_z}, M.target_pos, {0, 1, 0})
    local proj = mc.mat4_perspective(mc.rad(60), sw.extent.width/sw.extent.height, 0.1, 1000.0)
    local vp = mc.mat4_multiply(proj, view)

    local bone_globals = {}
    local function calc_globals(bone, parent_global)
        local local_m = mc.mat4_identity()
        local vals = (M.anim_state == "walking" and get_animated_matrix(bone.name, animations.walking, M.time)) or bone.local_matrix
        if vals then for row=0,3 do for col=0,3 do local_m.m[col*4 + row] = vals[row*4 + col + 1] end end end
        local_m.m[12], local_m.m[13], local_m.m[14] = local_m.m[12]*0.1, local_m.m[13]*0.1, local_m.m[14]*0.1
        local global_m = mc.mat4_multiply(parent_global, local_m)
        bone_globals[bone.id] = global_m
        for _, b in ipairs(bones) do if b.parent_id == bone.id then calc_globals(b, global_m) end end
    end
    local root = nil; for _, b in ipairs(bones) do if b.parent_id == 0 then root = b; break end end
    if root then calc_globals(root, mc.mat4_identity()) end

    -- 0. JIGGLE PHYSICS
    local soft_body_data = ffi.new("SoftBody[?]", #M.soft_bodies)
    for i, sb in ipairs(M.soft_bodies) do
        -- FAILSAFE MATCHING: Use string.find to handle prefixed bone names
        local bone_id = nil; for _, b in ipairs(bones) do if b.name:find(sb.bone) then bone_id = b.id; break end end
        
        if bone_id and bone_globals[bone_id] then
            local m = bone_globals[bone_id]
            -- Calculate world anchor from local anchor
            local ax = sb.local_anchor[1] * m.m[0] + sb.local_anchor[2] * m.m[4] + sb.local_anchor[3] * m.m[8] + m.m[12]
            local ay = sb.local_anchor[1] * m.m[1] + sb.local_anchor[2] * m.m[5] + sb.local_anchor[3] * m.m[9] + m.m[13]
            local az = sb.local_anchor[1] * m.m[2] + sb.local_anchor[2] * m.m[6] + sb.local_anchor[3] * m.m[10] + m.m[14]

            -- Initialize pos if needed
            if sb.pos[1] == 0 and sb.pos[2] == 0 then sb.pos = {ax, ay, az} end

            -- Spring physics (Mass-Spring-Damper)
            local k_spring = 400.0 -- Stable stiffness
            local d_damp = 30.0    -- Stable damping
            local grav_vals = {-30.0, -150.0, 50.0}
            local gravity = grav_vals[M.gravity_mode]
            
            local dx, dy, dz = sb.pos[1] - (ax + m.m[8]*0.5), sb.pos[2] - (ay + m.m[9]*0.5), sb.pos[3] - (az + m.m[10]*0.5)
            local fx = -k_spring * dx - d_damp * sb.vel[1]
            local fy = -k_spring * dy - d_damp * sb.vel[2] + gravity
            local fz = -k_spring * dz - d_damp * sb.vel[3]

            sb.vel[1] = sb.vel[1] + fx * dt
            sb.vel[2] = sb.vel[2] + fy * dt
            sb.vel[3] = sb.vel[3] + fz * dt
            sb.pos[1] = sb.pos[1] + sb.vel[1] * dt
            sb.pos[2] = sb.pos[2] + sb.vel[2] * dt
            sb.pos[3] = sb.pos[3] + sb.vel[3] * dt

            local target_bone_idx = 0
            for j, s in ipairs(segments) do if s.parent_name:find(sb.bone) then target_bone_idx = j - 1; break end end

            -- DYNAMIC BASIS: Pure Geometric Look-At (World Reference)
            local fwd_x, fwd_y, fwd_z = sb.pos[1] - ax, sb.pos[2] - ay, sb.pos[3] - az
            
            -- FORCED TILT MODE (Mode 2: HEAVY)
            if M.gravity_mode == 2 then
                -- Force pointing almost straight down in world space (80 degrees)
                fwd_x, fwd_y, fwd_z = 0, -0.98, 0.17 
            end

            local fwd_l = math.sqrt(fwd_x^2 + fwd_y^2 + fwd_z^2)
            if fwd_l > 0.001 then fwd_x, fwd_y, fwd_z = fwd_x/fwd_l, fwd_y/fwd_l, fwd_z/fwd_l else fwd_z = 1.0 end
            
            -- PURE WORLD REFERENCE: Use hardcoded World-Up (0,1,0)
            local up_ref_x, up_ref_y, up_ref_z = 0, 1, 0
            if math.abs(fwd_y) > 0.9 then up_ref_z = 1.0; up_ref_y = 0.0 end -- Handle parallel case
            
            -- Right = Cross(Up-Ref, Forward)
            local rx, ry, rz = up_ref_y * fwd_z - up_ref_z * fwd_y, up_ref_z * fwd_x - up_ref_x * fwd_z, up_ref_x * fwd_y - up_ref_y * fwd_x
            local rl = math.sqrt(rx^2 + ry^2 + rz^2); if rl > 0 then rx, ry, rz = rx/rl, ry/rl, rz/rl else rx = 1.0 end
            
            -- Up = Cross(Forward, Right)
            local ux, uy, uz = fwd_y * rz - fwd_z * ry, fwd_z * rx - fwd_x * rz, fwd_x * ry - fwd_y * rx

            -- CENTER OFFSET: Near-Side shell logic
            local cx, cy, cz = sb.pos[1], sb.pos[2], sb.pos[3]

            -- ANATOMICAL SKEW: Calculate grav_bias from pitch
            local pitch = math.asin(-fwd_y)
            local grav_bias = math.sin(pitch) * 1.5 -- Sensitivity multiplier

            -- DEBUG: Print Absolute World Pitch
            if M.diagnostic and i == 1 then
                print(string.format("BREAST %s WORLD PITCH: %.2f (deg), BIAS: %.2f", sb.name, math.deg(pitch), grav_bias))
            end

            soft_body_data[i-1].pos = {cx, cy, cz, sb.radius}
            soft_body_data[i-1].params = {sb.k, bone_id-1, (sb.name:find("breast") and 0 or 1), grav_bias}
            soft_body_data[i-1].basis_x = {rx, ry, rz, 0}
            soft_body_data[i-1].basis_y = {ux, uy, uz, 0}
            soft_body_data[i-1].basis_z = {fwd_x, fwd_y, fwd_z, 0}
        end
    end
    M.soft_body_buf:upload(soft_body_data)

    -- 1. Pre-calculate directions for all segments
    local segment_dirs = {}
    for i, s in ipairs(segments) do
        local m_start = bone_globals[s.start_pos[4] + 1]
        local m_end = bone_globals[s.end_pos[4] + 1]
        local dx, dy, dz = m_end.m[12]-m_start.m[12], m_end.m[13]-m_start.m[13], m_end.m[14]-m_start.m[14]
        local l = math.sqrt(dx*dx+dy*dy+dz*dz)
        if l > 0 then dx,dy,dz = dx/l, dy/l, dz/l end
        segment_dirs[i] = {dx, dy, dz}
    end

    -- 2. Calculate Mitered Planes (Bisectors)
    local bone_data = ffi.new("MeshBone[?]", #segments)
    for i, s in ipairs(segments) do
        local m_start, m_end = bone_globals[s.start_pos[4] + 1], bone_globals[s.end_pos[4] + 1]
        local dir = segment_dirs[i]
        
        -- Find shared joint planes
        local incoming = dir
        for j, ps in ipairs(segments) do
            if ps.end_pos[4] == s.start_pos[4] then incoming = segment_dirs[j]; break end
        end

        local outgoing = dir
        for j, cs in ipairs(segments) do
            if cs.start_pos[4] == s.end_pos[4] then outgoing = segment_dirs[j]; break end
        end

        -- SHARED MITER MATH: Child Start Normal MUST EQUAL Parent End Normal
        local ps = {incoming[1] + dir[1], incoming[2] + dir[2], incoming[3] + dir[3]}
        local psl = math.sqrt(ps[1]^2 + ps[2]^2 + ps[3]^2); if psl > 0 then ps = {ps[1]/psl, ps[2]/psl, ps[3]/psl} else ps = dir end
        
        -- HIPS BRANCH FUSION: Force all segments starting at Hips to use a stable vertical miter
        if s.parent_name:find("Hips") then
            ps = {0, 1, 0} -- Force horizontal ring at the root
        end

        local pe = {dir[1] + outgoing[1], dir[2] + outgoing[2], dir[3] + outgoing[3]}
        local pel = math.sqrt(pe[1]^2 + pe[2]^2 + pe[3]^2); if pel > 0 then pe = {pe[1]/pel, pe[2]/pel, pe[3]/pel} else pe = dir end

        -- Flex logic
        local dot = dir[1]*incoming[1] + dir[2]*incoming[2] + dir[3]*incoming[3]
        local flex = math.max(0, 1.0 - dot) * 0.5
        local side = (s.name:find("Right") and -1 or 1)

        bone_data[i-1].start_pos = {m_start.m[12], m_start.m[13], m_start.m[14], s.start_pos[4]}
        bone_data[i-1].end_pos = {m_end.m[12], m_end.m[13], m_end.m[14], s.end_pos[4]}
        bone_data[i-1].plane_start = {ps[1], ps[2], ps[3], flex}
        bone_data[i-1].plane_end = {pe[1], pe[2], pe[3], side}
    end
    bone_buf:upload(bone_data)

    local cb = cbs[idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {M.c_ds}), 0, nil)
    vk.vkCmdPushConstants(cb, compute_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 20, ffi.new("uint32_t[5]", { #segments, RINGS_PER_BONE, VERTS_PER_RING, M.diagnostic and 1 or 0, #M.soft_bodies }))
    vk.vkCmdDispatch(cb, VERTS_PER_RING/16, RINGS_PER_BONE/8, #segments)
    local v_barrier = ffi.new("VkBufferMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT, buffer = vbuf.handle, offset = 0, size = vbuf.size }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, 0, 0, nil, 1, v_barrier, 0, nil)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05, 0.05, 0.05, 1.0}
    local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, depth_img.view, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil.depth = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
    
    local barriers = ffi.new("VkImageMemoryBarrier[2]")
    barriers[0].sType, barriers[0].oldLayout, barriers[0].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    barriers[0].image, barriers[0].subresourceRange = ffi.cast("VkImage", sw.images[idx]), { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    barriers[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    barriers[1].sType, barriers[1].oldLayout, barriers[1].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    barriers[1].image, barriers[1].subresourceRange = depth_img.handle, { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }
    barriers[1].dstAccessMask = bit.bor(vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 2, barriers)

    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {M.g_ds}), 0, nil)

    local pc = ffi.new("PC")
    local model = mc.mat4_identity()
    local mvp = mc.mat4_multiply(vp, model)
    for i=0,15 do pc.mvp[i], pc.model[i] = mvp.m[i], model.m[i] end
    local mx, my = input.mouse_pos(); pc.mouse_pos[0], pc.mouse_pos[1] = mx, my
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 144, pc)
    
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    vk.vkCmdDrawIndexed(cb, idx_count, 1, 0, 0, 0)
    vk.vkCmdEndRendering(cb)

    -- READBACK PICKING
    local clear_id = ffi.new("uint32_t[1]", {0xFFFFFFFF})
    local pick_id = ffi.new("uint32_t[1]")
    ffi.copy(pick_id, pick_buf.allocation.ptr, 4)
    if pick_id[0] ~= 0xFFFFFFFF then
        local s = segments[pick_id[0]+1]
        if s then print("Mouse over: " .. s.name) end
    end
    pick_buf:upload(clear_id)

    local present_bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={ aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1 }, srcAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, present_bar)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
