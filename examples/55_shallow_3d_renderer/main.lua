local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")
local graph = require("vulkan.graph")
local input = require("mc.input")
local imgui = require("imgui")

local M = { 
    current_time = 0,
    grid_w = 512,
    grid_h = 128,
    grid_d = 512,
    macro_w = 64,
    macro_h = 16,
    macro_d = 64,
    shadow_w = 64,
    shadow_h = 16,
    shadow_d = 64,
    chunk_size = 16,
    player_pos = {256, 40, 256},
    prev_player_pos = {256, 40, 256},
    player_yaw = 0,
    cam_pos_smooth = {256, 40, 286},
    cam_target_smooth = {256, 40, 256},
    cam_yaw = 0,
    cam_pitch = -0.5,
    cam_dist = 30,
    fps = 0,
    active_chunks = 0,
    brush_type = 1,
    dig_radius = 0
}

local state = {
    frame_count = 0,
    last_fps_time = 0,
    last_frame_time = 0
}

ffi.cdef[[
    typedef struct PlayerState { 
        float pos[3], yaw; 
        float vel[3], p1; 
        uint32_t grounded, debug_dist, debug_found, p2; 
        uint32_t padding[4]; 
    } PlayerState;

    typedef struct PhysicsPC { 
        float ix, iy, iz, dt; 
        uint32_t img_idx, grid_w, grid_h, grid_d; 
        float hover_target, hover_strength; 
        uint32_t player_buf_idx, p0; 
    } PhysicsPC;

    typedef struct PlayerUpdatePC { 
        uint32_t img, grid_w, grid_h, grid_d, dirty_map_idx, player_buf_idx, spawn_type, dig_radius, stats_buf_idx, p1, p2, p3; 
    } PlayerUpdatePC;

    typedef struct GIPC { 
        uint32_t in_img, out_img, light_in_idx, light_out_idx, grid_w, grid_h, grid_d, macro_w, macro_h, macro_d; 
    } GIPC;

    typedef struct ShadowVolPC { 
        uint32_t in_img, out_img, grid_w, grid_h, grid_d, shadow_w, shadow_h, shadow_d; 
        float sun_dir[3], p0; 
    } ShadowVolPC;

    typedef struct MesherPC { 
        uint32_t in_img, dirty_map_idx, v_buf, indirect_buf, grid_w, grid_h, grid_d, active_map_idx; 
        int32_t px, py, pz, p0; 
    } MesherPC;

    typedef struct RenderPC { 
        float mvp[16]; 
        float light_mvp[16];
        uint32_t v_buf, light_img, grid_w, grid_h;
        uint32_t grid_d, macro_w, macro_h, macro_d;
        uint32_t shadow_idx, shadow_vol_idx, gi_vol_idx, p0;
        float cam_pos[3], p3;
    } RenderPC;

    typedef struct RobotRenderPC {
        float mvp[16];
        float pos[3], yaw;
    } RobotRenderPC;
]]

function M.init()
    print("Example 55: Voxel Builder - Restoring GI")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    state.device = vulkan.get_device()
    state.queue, state.graphics_family = vulkan.get_queue()
    
    state.sw = swapchain.new(instance, physical_device, state.device, _G._SDL_WINDOW)
    state.rg = graph.new(state.device)
    imgui.init(state.sw.format)

    state.vol = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.light_vol = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.macro_light = mc.gpu.image_3d(M.macro_w, M.macro_h, M.macro_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    
    state.depth_img = mc.gpu.image(state.sw.extent.width, state.sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    state.shadow_vol = mc.gpu.image_3d(M.shadow_w, M.shadow_h, M.shadow_d, vk.VK_FORMAT_R16_SFLOAT, "storage sampled")
    state.shadow_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR, vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE)
    state.gi_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR, vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE)
    
    local num_chunks = (M.grid_w/M.chunk_size) * (M.grid_h/M.chunk_size) * (M.grid_d/M.chunk_size)
    state.dirty_map = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    state.v_buf = mc.gpu.buffer(num_chunks * 16384 * 4, "storage", nil, false)
    state.indirect_buf = mc.gpu.buffer(num_chunks * 20, "indirect", nil, true)
    state.stats_buf = mc.gpu.buffer(64, "storage", nil, true)
    
    local init_player = ffi.new("PlayerState", { pos = {256, 40, 256}, yaw = 0, vel = {0, 0, 0} })
    state.player_state_buf = mc.gpu.buffer(ffi.sizeof("PlayerState"), "storage", init_player, true)

    local index_data = ffi.new("uint16_t[?]", 65536)
    for i=0, 10000 do
        local b, o = i*4, i*6
        index_data[o+0], index_data[o+1], index_data[o+2] = b+0, b+1, b+2
        index_data[o+3], index_data[o+4], index_data[o+5] = b+0, b+2, b+3
    end
    state.index_buf = mc.gpu.buffer(ffi.sizeof(index_data), "index", index_data, false)

    -- Robot Geometry
    local function pack_v(lp, norm, mat, ao)
        return bit.bor(bit.band(lp[1], 15), bit.lshift(bit.band(lp[2], 15), 4), bit.lshift(bit.band(lp[3], 15), 8),
               bit.lshift(bit.band(norm, 7), 12), bit.lshift(bit.band(mat, 255), 15), bit.lshift(bit.band(ao, 3), 23))
    end
    local r_verts = ffi.new("uint32_t[?]", 6 * 4 * 12) 
    local r_indices = ffi.new("uint16_t[?]", 6 * 6 * 12)
    local v_idx, i_idx = 0, 0
    local function add_robot_box(x, y, z, mat)
        for d=0,5 do
            local p = pack_v({x,y,z}, d, mat, 3)
            for j=0,3 do r_verts[v_idx] = p v_idx = v_idx + 1 end
            local b = v_idx - 4
            r_indices[i_idx+0], r_indices[i_idx+1], r_indices[i_idx+2] = b, b+1, b+2
            r_indices[i_idx+3], r_indices[i_idx+4], r_indices[i_idx+5] = b, b+2, b+3
            i_idx = i_idx + 6
        end
    end
    add_robot_box(0,0,0, 10) add_robot_box(1,0,0, 10)
    add_robot_box(0,1,0, 10) add_robot_box(1,1,0, 10)
    add_robot_box(0,2,0, 10) add_robot_box(1,2,0, 10)
    state.robot_v_buf = mc.gpu.buffer(v_idx * 4, "vertex", r_verts, false)
    state.robot_i_buf = mc.gpu.buffer(i_idx * 2, "index", r_indices, false)
    M.robot_index_count = i_idx

    state.res_vol = state.rg:register_resource("vol", graph.TYPE_IMAGE, state.vol.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_macro = state.rg:register_resource("macro", graph.TYPE_IMAGE, state.macro_light.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_dirty = state.rg:register_resource("dirty", graph.TYPE_BUFFER, state.dirty_map.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    state.res_v_buf = state.rg:register_resource("v_buf", graph.TYPE_BUFFER, state.v_buf.handle)
    state.res_indirect = state.rg:register_resource("indirect", graph.TYPE_BUFFER, state.indirect_buf.handle)
    state.res_depth = state.rg:register_resource("depth", graph.TYPE_IMAGE, state.depth_img.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED, access = 0, stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT })
    state.res_shadow_vol = state.rg:register_resource("shadow_vol", graph.TYPE_IMAGE, state.shadow_vol.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_player = state.rg:register_resource("player", graph.TYPE_BUFFER, state.player_state_buf.handle)
    state.res_stats = state.rg:register_resource("stats", graph.TYPE_BUFFER, state.stats_buf.handle)

    state.bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.vol.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.macro_light.view, vk.VK_IMAGE_LAYOUT_GENERAL, 4)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.shadow_vol.view, vk.VK_IMAGE_LAYOUT_GENERAL, 8)
    descriptors.update_image_set(state.device, state.bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, state.shadow_vol.view, state.shadow_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 11)
    
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.dirty_map.handle, 0, state.dirty_map.size, 0)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.v_buf.handle, 0, state.v_buf.size, 1)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.indirect_buf.handle, 0, state.indirect_buf.size, 2)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.player_state_buf.handle, 0, state.player_state_buf.size, 4)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.stats_buf.handle, 0, state.stats_buf.size, 7)

    state.pipe_gi = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gi.comp", ffi.sizeof("GIPC"))
    state.pipe_mesh = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/mesh.comp", ffi.sizeof("MesherPC"))
    state.pipe_gen = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gen.comp", 28)
    state.pipe_player = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/player.comp", ffi.sizeof("PlayerUpdatePC"))
    state.pipe_physics = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/physics.comp", ffi.sizeof("PhysicsPC"))
    state.pipe_shadow_vol = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/shadow_vol.comp", ffi.sizeof("ShadowVolPC"))
    
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RenderPC") }})
    state.render_layout = pipeline.create_layout(state.device, {bl_layout}, pc_ranges)
    local v_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    state.pipe_render = pipeline.create_graphics_pipeline(state.device, state.render_layout, v_mod, f_mod, { depth_test = true, depth_write = true, cull_mode = vk.VK_CULL_MODE_BACK_BIT, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = { state.sw.format } })

    local robot_pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RobotRenderPC") }})
    state.robot_layout = pipeline.create_layout(state.device, {bl_layout}, robot_pc_ranges)
    local rv_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/robot.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local rf_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/robot.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    state.pipe_robot = pipeline.create_graphics_pipeline(state.device, state.robot_layout, rv_mod, rf_mod, { depth_test = true, depth_write = true, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = { state.sw.format }, 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 4, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[1]", {{ location = 0, binding = 0, format = vk.VK_FORMAT_R32_UINT, offset = 0 }}),
        vertex_attribute_count = 1
    })

    local pool = command.create_pool(state.device, state.graphics_family)
    local gcb = command.allocate_buffers(state.device, pool, 1)[1]
    command.begin_one_time(gcb)
    
    local vol_bar = ffi.new("VkImageMemoryBarrier[3]")
    vol_bar[0] = ffi.new("VkImageMemoryBarrier", { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_GENERAL, image = state.vol.handle, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } })
    vol_bar[1] = ffi.new("VkImageMemoryBarrier", { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_GENERAL, image = state.shadow_vol.handle, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } })
    vol_bar[2] = ffi.new("VkImageMemoryBarrier", { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_GENERAL, image = state.macro_light.handle, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } })
    vk.vkCmdPipelineBarrier(gcb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 3, vol_bar)
    
    vk.vkCmdFillBuffer(gcb, state.dirty_map.handle, 0, state.dirty_map.size, 0)
    vk.vkCmdFillBuffer(gcb, state.stats_buf.handle, 0, state.stats_buf.size, 0)
    
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gen.handle)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gen.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
    vk.vkCmdPushConstants(gcb, state.pipe_gen.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 28, ffi.new("uint32_t[7]", {0, M.grid_w, M.grid_h, M.grid_d, 0, 0, 7}))
    vk.vkCmdDispatch(gcb, M.grid_w/16, M.grid_h/16, M.grid_d)
    
    vk.vkEndCommandBuffer(gcb)
    vk.vkQueueSubmit(state.queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {gcb}) }), nil)
    vk.vkQueueWaitIdle(state.queue)
    vk.vkDestroyCommandPool(state.device, pool, nil)

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(state.device, sem_info, nil, pSem); state.image_available_sem = pSem[0]
    local pool2 = command.create_pool(state.device, state.graphics_family)
    state.cbs = command.allocate_buffers(state.device, pool2, state.sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(state.device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); state.frame_fence = pF[0]
end

function M.update()
    if state.last_frame_time == 0 then state.last_frame_time = tonumber(ffi.C.SDL_GetTicks()) end
    local current_wall_time = tonumber(ffi.C.SDL_GetTicks())
    local dt = (current_wall_time - state.last_frame_time) / 1000.0
    state.last_frame_time = current_wall_time
    
    if dt > 0.1 then dt = 0.1 end

    vk.vkWaitForFences(state.device, 1, ffi.new("VkFence[1]", {state.frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(state.device, 1, ffi.new("VkFence[1]", {state.frame_fence}))
    local img_idx = state.sw:acquire_next_image(state.image_available_sem)
    if img_idx == nil then return end

    state.frame_count = state.frame_count + 1
    M.current_time = M.current_time + dt

    if M.current_time - state.last_fps_time > 1.0 then
        M.fps = state.frame_count
        state.frame_count = 0
        state.last_fps_time = M.current_time
    end

    local mx, my = input.mouse_delta()
    if input.mouse_down(3) then
        M.cam_yaw = M.cam_yaw - mx * 0.005
        M.cam_pitch = math.max(-1.5, math.min(1.5, M.cam_pitch - my * 0.005))
    end
    
    local move_input = {0, 0, 0}
    if input.key_down(input.SCANCODE_W) then move_input[1], move_input[3] = move_input[1] + math.sin(M.cam_yaw), move_input[3] + math.cos(M.cam_yaw) end
    if input.key_down(input.SCANCODE_S) then move_input[1], move_input[3] = move_input[1] - math.sin(M.cam_yaw), move_input[3] - math.cos(M.cam_yaw) end
    if input.key_down(input.SCANCODE_A) then move_input[1], move_input[3] = move_input[1] + math.cos(M.cam_yaw), move_input[3] - math.sin(M.cam_yaw) end
    if input.key_down(input.SCANCODE_D) then move_input[1], move_input[3] = move_input[1] - math.cos(M.cam_yaw), move_input[3] + math.sin(M.cam_yaw) end
    local len = math.sqrt(move_input[1]^2 + move_input[3]^2)
    if len > 0 then 
        move_input[1], move_input[3] = move_input[1]/len, move_input[3]/len 
        M.player_yaw = math.atan2(move_input[1], move_input[3])
    end
    if input.key_down(input.SCANCODE_SPACE) then move_input[2] = 1.0 end

    local p_ptr = ffi.cast("PlayerState*", state.player_state_buf.allocation.ptr)
    M.player_pos = {p_ptr.pos[0], p_ptr.pos[1], p_ptr.pos[2]}
    p_ptr.yaw = M.player_yaw

    if input.key_pressed(input.SCANCODE_1) then M.brush_type = 1 end
    if input.key_pressed(input.SCANCODE_2) then M.brush_type = 2 end
    if input.key_pressed(input.SCANCODE_3) then M.brush_type = 3 end
    if input.key_pressed(input.SCANCODE_4) then M.brush_type = 7 end

    local spawn_type = 0
    local dig_radius = 0
    if input.mouse_down(1) then spawn_type = M.brush_type end
    if input.key_down(input.SCANCODE_Z) then dig_radius = 4 end

    local aspect = state.sw.extent.width / state.sw.extent.height
    local proj = mc.mat4_perspective(mc.rad(60), aspect, 0.1, 1000.0)
    local target_eye = {
        M.player_pos[1] - math.sin(M.cam_yaw) * math.cos(M.cam_pitch) * M.cam_dist,
        M.player_pos[2] - math.sin(M.cam_pitch) * M.cam_dist + 4,
        M.player_pos[3] - math.cos(M.cam_yaw) * math.cos(M.cam_pitch) * M.cam_dist
    }
    local target_look = {M.player_pos[1], M.player_pos[2]+2, M.player_pos[3]}
    local cam_smooth = 0.1
    for i=1,3 do
        M.cam_pos_smooth[i] = M.cam_pos_smooth[i] + (target_eye[i] - M.cam_pos_smooth[i]) * cam_smooth
        M.cam_target_smooth[i] = M.cam_target_smooth[i] + (target_look[i] - M.cam_target_smooth[i]) * cam_smooth
    end
    local view = mc.mat4_look_at(M.cam_pos_smooth, M.cam_target_smooth, {0,1,0})
    local mvp = mc.mat4_multiply(proj, view)

    local sun_dir = normalize({0.5, 1.0, 0.3})
    local shadow_range = 300.0
    local shadow_proj = mc.mat4_ortho(-shadow_range, shadow_range, -shadow_range, shadow_range, 0.1, 500.0)
    local shadow_view = mc.mat4_look_at({M.player_pos[1] + sun_dir[1]*200, M.player_pos[2] + sun_dir[2]*200, M.player_pos[3] + sun_dir[3]*200}, {M.player_pos[1], M.player_pos[2], M.player_pos[3]}, {0,1,0})
    local light_mvp = mc.mat4_multiply(shadow_proj, shadow_view)

    imgui.new_frame()
    imgui.gui.igBegin("Voxel Builder", nil, 0)
    imgui.gui.igText("FPS: " .. M.fps)
    imgui.gui.igSeparator()
    imgui.gui.igText("Controls:")
    imgui.gui.igText("WASD: Move, Space: Jump")
    imgui.gui.igText("Mouse Right: Orbit Camera")
    imgui.gui.igText("Mouse Left: Build (Type " .. M.brush_type .. ")")
    imgui.gui.igText("Z Key: Dig (Radius 4)")
    imgui.gui.igText("1-4: Select Material")
    imgui.gui.igEnd()

    local cb = state.cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    state.rg:reset()
    
    state.rg:add_pass("Physics", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_physics.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_physics.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("PhysicsPC", { ix = move_input[1], iy = move_input[2], iz = move_input[3], dt = dt, img_idx = 0, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, hover_target = 4.0, hover_strength = 100.0, player_buf_idx = 4 })
        vk.vkCmdPushConstants(cb, state.pipe_physics.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PhysicsPC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(state.res_vol, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_player, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    state.rg:add_pass("Interaction", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_player.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_player.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("PlayerUpdatePC", { img = 0, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, dirty_map_idx = 0, player_buf_idx = 4, spawn_type = spawn_type, dig_radius = dig_radius, stats_buf_idx = 7 })
        vk.vkCmdPushConstants(cb, state.pipe_player.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PlayerUpdatePC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(state.res_vol, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_dirty, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_player, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- GI RESTORATION
    state.rg:add_pass("Macro_GI", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gi.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gi.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        -- in_img=0 (vol), out_img=4 (macro), light_in=4, light_out=4 (multi-pass in one dispatch? better to do 2)
        local pc = ffi.new("GIPC", { in_img = 0, out_img = 4, light_in_idx = 4, light_out_idx = 4, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, macro_w = M.macro_w, macro_h = M.macro_h, macro_d = M.macro_d })
        vk.vkCmdPushConstants(cb, state.pipe_gi.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("GIPC"), pc)
        vk.vkCmdDispatch(cb, M.macro_w/4, M.macro_h/4, M.macro_d/4)
    end):using(state.res_vol, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_macro, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    local cx, cy, cz = M.grid_w/M.chunk_size, M.grid_h/M.chunk_size, M.grid_d/M.chunk_size
    state.rg:add_pass("Mesher", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_mesh.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_mesh.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("MesherPC", { in_img = 0, dirty_map_idx = 0, v_buf = 1, indirect_buf = 2, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = 0, px = 0, py = 0, pz = 0 })
        vk.vkCmdPushConstants(cb, state.pipe_mesh.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("MesherPC"), pc)
        vk.vkCmdDispatch(cb, cx, cy, cz)
    end):using(state.res_vol, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_dirty, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_v_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_indirect, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    state.rg:add_pass("Clear_Dirty", function(cb)
        vk.vkCmdFillBuffer(cb, state.dirty_map.handle, 0, state.dirty_map.size, 0)
    end):using(state.res_dirty, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)

    state.rg:add_pass("Shadow_Vol", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_shadow_vol.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_shadow_vol.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("ShadowVolPC", { in_img = 0, out_img = 8, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, shadow_w = M.shadow_w, shadow_h = M.shadow_h, shadow_d = M.shadow_d, sun_dir = sun_dir })
        vk.vkCmdPushConstants(cb, state.pipe_shadow_vol.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("ShadowVolPC"), pc)
        vk.vkCmdDispatch(cb, M.shadow_w/4, M.shadow_h/4, M.shadow_d/4)
    end):using(state.res_vol, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_shadow_vol, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    state.rg:add_pass("Sync_Barrier", function(cb)
        local bar = ffi.new("VkMemoryBarrier2", {
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER_2,
            srcStageMask = vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
            srcAccessMask = vk.VK_ACCESS_2_SHADER_WRITE_BIT,
            dstStageMask = bit.bor(vk.VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT, vk.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT),
            dstAccessMask = bit.bor(vk.VK_ACCESS_2_SHADER_READ_BIT, vk.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT)
        })
        vk.vkCmdPipelineBarrier2(cb, ffi.new("VkDependencyInfo", { sType = vk.VK_STRUCTURE_TYPE_DEPENDENCY_INFO, memoryBarrierCount = 1, pMemoryBarriers = bar }))
    end)

    state.rg:add_pass("Render", function(cb)
        local color_attach, depth_attach = ffi.new("VkRenderingAttachmentInfo[1]"), ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", state.sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.5, 0.7, 0.9, 1.0}
        depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout, depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", state.depth_img.view), vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {depth=1, stencil=0}
        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=state.sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=state.sw.extent.width, height=state.sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=state.sw.extent }))

        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.pipe_render)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.render_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("RenderPC", { 
            mvp = mvp.m, 
            light_mvp = light_mvp.m,
            v_buf = 1, 
            light_img = 4, -- Point to macro_light (bindless 4)
            grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, 
            macro_w = M.macro_w, macro_h = M.macro_h, macro_d = M.macro_d, 
            shadow_idx = 10, shadow_vol_idx = 11, gi_vol_idx = 0,
            cam_pos = {M.cam_pos_smooth[1], M.cam_pos_smooth[2], M.cam_pos_smooth[3]} 
        })
        vk.vkCmdPushConstants(cb, state.render_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), pc)
        vk.vkCmdBindIndexBuffer(cb, state.index_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexedIndirect(cb, state.indirect_buf.handle, 0, cx*cy*cz, 20)
        
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.pipe_robot)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.robot_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local r_pc = ffi.new("RobotRenderPC", { mvp = mvp.m, pos = {M.player_pos[1], M.player_pos[2], M.player_pos[3]}, yaw = M.player_yaw })
        vk.vkCmdPushConstants(cb, state.robot_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RobotRenderPC"), r_pc)
        vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {state.robot_v_buf.handle}), ffi.new("VkDeviceSize[1]", {0}))
        vk.vkCmdBindIndexBuffer(cb, state.robot_i_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexed(cb, M.robot_index_count, 1, 0, 0, 0)
        
        imgui.render(cb, state.frame_count)
        vk.vkCmdEndRendering(cb)
    end):using(state.res_v_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(state.res_shadow_vol, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_macro, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)

    state.rg:execute(cb)
    vk.vkEndCommandBuffer(cb)
    local render_finished_sem = state.sw.semaphores[img_idx]
    vk.vkQueueSubmit(state.queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {state.image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), state.frame_fence)
    state.sw:present(state.queue, img_idx, render_finished_sem)
end

function normalize(v)
    local l = math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
    return {v[1]/l, v[2]/l, v[3]/l}
end

return M
