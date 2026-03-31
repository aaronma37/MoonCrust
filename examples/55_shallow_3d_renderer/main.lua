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
    current_vol_idx = 0,
    grid_w = 512,
    grid_h = 128,
    grid_d = 512,
    chunk_size = 16,
    player_pos = {256, 40, 256},
    prev_player_pos = {256, 40, 256},
    player_yaw = 0,
    cam_pos_smooth = {256, 40, 286},
    cam_target_smooth = {256, 40, 256},
    cam_yaw = 0,
    cam_pitch = -0.5,
    cam_dist = 30,
    tick_rate = 60,
    accumulated_time = 0,
    hover_enabled = true,
    hover_target = 4.0,
    hover_strength = 100.0,
    max_entities = 1024,
    next_entity_idx = 0,
    fps = 0
}

local device, queue, graphics_family, sw, rg
local vol_a, vol_b, light_vol_a, light_vol_b, dirty_map, active_map, v_buf, indirect_buf, index_buf, depth_img, player_state_buf, entity_buf
local robot_v_buf, robot_i_buf
local pipe_sim, pipe_mesh, pipe_render, pipe_gen, pipe_player, pipe_physics, pipe_dna, pipe_robot, render_layout, robot_layout
local bindless_set, image_available_sem, frame_fence, cbs
local res_vol_a, res_vol_b, res_light_a, res_light_b, res_dirty, res_active, res_v_buf, res_indirect, res_depth, res_player, res_entities

ffi.cdef[[
    typedef struct PlayerState { 
        float pos[3], yaw; 
        float vel[3], p1; 
        uint32_t grounded, debug_dist, debug_found, p2; 
        uint32_t padding[4]; 
    } PlayerState;

    typedef struct Entity { 
        float pos[3], age; 
        uint32_t type, parent_id, child_count, energy; 
        uint32_t padding[8]; 
    } Entity;

    typedef struct PhysicsPC { 
        float ix, iy, iz, dt; 
        uint32_t img_idx, grid_w, grid_h, grid_d; 
        float hover_target, hover_strength; 
        uint32_t player_buf_idx, p0; 
    } PhysicsPC;

    typedef struct PlayerUpdatePC { 
        uint32_t img_a, img_b, grid_w, grid_h, grid_d, active_map_idx, dirty_map_idx, player_buf_idx, plant_seed, p0, p1, p2; 
    } PlayerUpdatePC;

    typedef struct SimTickPC { 
        uint32_t in_img, out_img, light_in_img, light_out_img, grid_w, grid_h, grid_d, active_map_idx, dirty_map_idx; 
    } SimTickPC;

    typedef struct DNAPC { 
        uint32_t img_idx, light_img, entity_buf_idx, grid_w, grid_h, grid_d, active_map_idx, dirty_map_idx; 
        float dt; uint32_t p0, p1, p2; 
    } DNAPC;

    typedef struct MesherPC { 
        uint32_t in_img, dirty_map_idx, v_buf, indirect_buf, grid_w, grid_h, grid_d, active_map_idx; 
        int32_t px, py, pz, p0; 
    } MesherPC;

    typedef struct RenderPC { 
        float mvp[16]; 
        uint32_t v_buf, light_img, grid_w, grid_h, grid_d, p0, p1, p2;
        float cam_pos[3], p3; // vec3 at end for easiest alignment
    } RenderPC;

    typedef struct RobotRenderPC {
        float mvp[16];
        float pos[3], yaw;
    } RobotRenderPC;
]]

function M.init()
    print("Example 55: Voxel Automation Game - Hardened Stage 1")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    rg = graph.new(device)
    imgui.init(sw.format)

    vol_a = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    vol_b = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    light_vol_a = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    light_vol_b = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    
    local num_chunks = (M.grid_w/M.chunk_size) * (M.grid_h/M.chunk_size) * (M.grid_d/M.chunk_size)
    dirty_map = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    active_map = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    v_buf = mc.gpu.buffer(num_chunks * 16384 * 4, "storage", nil, false)
    indirect_buf = mc.gpu.buffer(num_chunks * 20, "indirect", nil, true)
    
    local init_player = ffi.new("PlayerState", { pos = {256, 40, 256}, yaw = 0, vel = {0, 0, 0} })
    player_state_buf = mc.gpu.buffer(ffi.sizeof("PlayerState"), "storage", init_player, true)
    entity_buf = mc.gpu.buffer(M.max_entities * ffi.sizeof("Entity"), "storage", nil, true)

    local function pack_v(lp, norm, mat, ao)
        return bit.bor(bit.band(lp[1], 15), bit.lshift(bit.band(lp[2], 15), 4), bit.lshift(bit.band(lp[3], 15), 8),
               bit.lshift(bit.band(norm, 7), 12), bit.lshift(bit.band(mat, 255), 15), bit.lshift(bit.band(ao, 3), 23))
    end
    local r_verts = ffi.new("uint32_t[?]", 6 * 4 * 12) 
    local r_indices = ffi.new("uint16_t[?]", 6 * 6 * 12)
    local v_idx, i_idx = 0, 0
    local function add_robot_box(x, y, z, mat)
        local dirs = {{1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1}}
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
    robot_v_buf = mc.gpu.buffer(v_idx * 4, "vertex", r_verts, false)
    robot_i_buf = mc.gpu.buffer(i_idx * 2, "index", r_indices, false)
    M.robot_index_count = i_idx

    local index_data = ffi.new("uint16_t[?]", 65536)
    for i=0, 10000 do
        local b, o = i*4, i*6
        index_data[o+0], index_data[o+1], index_data[o+2] = b+0, b+1, b+2
        index_data[o+3], index_data[o+4], index_data[o+5] = b+0, b+2, b+3
    end
    index_buf = mc.gpu.buffer(ffi.sizeof(index_data), "index", index_data, false)

    res_vol_a = rg:register_resource("vol_a", graph.TYPE_IMAGE, vol_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_vol_b = rg:register_resource("vol_b", graph.TYPE_IMAGE, vol_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_light_a = rg:register_resource("light_a", graph.TYPE_IMAGE, light_vol_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_light_b = rg:register_resource("light_b", graph.TYPE_IMAGE, light_vol_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    res_dirty = rg:register_resource("dirty", graph.TYPE_BUFFER, dirty_map.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    res_active = rg:register_resource("active", graph.TYPE_BUFFER, active_map.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    res_v_buf = rg:register_resource("v_buf", graph.TYPE_BUFFER, v_buf.handle)
    res_indirect = rg:register_resource("indirect", graph.TYPE_BUFFER, indirect_buf.handle)
    res_depth = rg:register_resource("depth", graph.TYPE_IMAGE, depth_img.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED, access = 0, stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT })
    res_player = rg:register_resource("player", graph.TYPE_BUFFER, player_state_buf.handle)
    res_entities = rg:register_resource("entities", graph.TYPE_BUFFER, entity_buf.handle)

    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, vol_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, vol_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 1)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, light_vol_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 2)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, light_vol_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 3)
    
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, dirty_map.handle, 0, dirty_map.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, v_buf.handle, 0, v_buf.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, indirect_buf.handle, 0, indirect_buf.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, active_map.handle, 0, active_map.size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, player_state_buf.handle, 0, player_state_buf.size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, entity_buf.handle, 0, entity_buf.size, 5)

    pipe_sim = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/sim.comp", ffi.sizeof("SimTickPC"))
    pipe_mesh = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/mesh.comp", ffi.sizeof("MesherPC"))
    pipe_gen = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gen.comp", 16)
    pipe_player = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/player.comp", ffi.sizeof("PlayerUpdatePC"))
    pipe_physics = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/physics.comp", ffi.sizeof("PhysicsPC"))
    pipe_dna = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/dna.comp", ffi.sizeof("DNAPC"))
    
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RenderPC") }})
    render_layout = pipeline.create_layout(device, {bl_layout}, pc_ranges)
    local v_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_render = pipeline.create_graphics_pipeline(device, render_layout, v_mod, f_mod, { depth_test = true, depth_write = true, cull_mode = vk.VK_CULL_MODE_BACK_BIT, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = { sw.format } })

    local robot_pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RobotRenderPC") }})
    robot_layout = pipeline.create_layout(device, {bl_layout}, robot_pc_ranges)
    local rv_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/robot.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local rf_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/robot.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_robot = pipeline.create_graphics_pipeline(device, robot_layout, rv_mod, rf_mod, { depth_test = true, depth_write = true, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = { sw.format }, 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 4, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[1]", {{ location = 0, binding = 0, format = vk.VK_FORMAT_R32_UINT, offset = 0 }}),
        vertex_attribute_count = 1
    })

    local pool = command.create_pool(device, graphics_family)
    local gcb = command.allocate_buffers(device, pool, 1)[1]
    command.begin_one_time(gcb)
    local vol_bar = ffi.new("VkImageMemoryBarrier[4]")
    for i=0,3 do
        vol_bar[i].sType, vol_bar[i].oldLayout, vol_bar[i].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL
        vol_bar[i].image = (i == 0) and vol_a.handle or ((i == 1) and vol_b.handle or ((i == 2) and light_vol_a.handle or light_vol_b.handle))
        vol_bar[i].srcAccessMask, vol_bar[i].dstAccessMask = 0, vk.VK_ACCESS_SHADER_WRITE_BIT
        vol_bar[i].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    end
    vk.vkCmdPipelineBarrier(gcb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 4, vol_bar)
    vk.vkCmdFillBuffer(gcb, dirty_map.handle, 0, dirty_map.size, 1)
    vk.vkCmdFillBuffer(gcb, active_map.handle, 0, active_map.size, 1)
    vk.vkCmdFillBuffer(gcb, v_buf.handle, 0, v_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, indirect_buf.handle, 0, indirect_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, entity_buf.handle, 0, entity_buf.size, 0)
    
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen.handle)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    for i=0,1 do
        vk.vkCmdPushConstants(gcb, pipe_gen.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, ffi.new("uint32_t[4]", {i, M.grid_w, M.grid_h, M.grid_d}))
        vk.vkCmdDispatch(gcb, M.grid_w/16, M.grid_h/16, M.grid_d)
    end
    
    vk.vkEndCommandBuffer(gcb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {gcb}) }), nil)
    vk.vkQueueWaitIdle(queue)
    vk.vkDestroyCommandPool(device, pool, nil)

    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool2 = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool2, sw.image_count)
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
end

local frame_count = 0
local last_fps_time = 0
function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    frame_count = frame_count + 1
    local dt = 0.016
    M.current_time = M.current_time + dt
    M.accumulated_time = M.accumulated_time + dt
    local tick_duration = 1.0 / M.tick_rate
    local num_ticks = math.floor(M.accumulated_time / tick_duration)
    M.accumulated_time = M.accumulated_time - (num_ticks * tick_duration)

    if M.current_time - last_fps_time > 1.0 then
        M.fps = frame_count
        frame_count = 0
        last_fps_time = M.current_time
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

    local p_ptr = ffi.cast("PlayerState*", player_state_buf.allocation.ptr)
    M.prev_player_pos = {math.floor(M.player_pos[1]), math.floor(M.player_pos[2]), math.floor(M.player_pos[3])}
    M.player_pos = {p_ptr.pos[0], p_ptr.pos[1], p_ptr.pos[2]}
    p_ptr.yaw = M.player_yaw

    if input.key_pressed(19) then 
        local e_ptr = ffi.cast("Entity*", entity_buf.allocation.ptr)
        local idx = M.next_entity_idx % M.max_entities
        e_ptr[idx].pos = {math.floor(M.player_pos[1]), math.floor(M.player_pos[2]), math.floor(M.player_pos[3])}
        e_ptr[idx].type = 1 
        e_ptr[idx].energy = 1000
        e_ptr[idx].age = 0
        M.next_entity_idx = M.next_entity_idx + 1
    end

    local aspect = sw.extent.width / sw.extent.height
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

    imgui.new_frame()
    imgui.gui.igBegin("MoonCrust Debug", nil, 0)
    imgui.gui.igText("FPS: " .. M.fps)
    imgui.gui.igSeparator()
    imgui.gui.igText(string.format("Robot: %.1f, %.1f, %.1f", M.player_pos[1], M.player_pos[2], M.player_pos[3]))
    imgui.gui.igText("Entities: " .. M.next_entity_idx)
    imgui.gui.igSeparator()
    imgui.gui.igText("Stage 1 Baseline (Stride Fixed)")
    imgui.gui.igEnd()

    local cb = cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    rg:reset()
    
    local vol_in_idx = M.current_vol_idx
    local vol_out_idx = (vol_in_idx == 0) and 1 or 0
    local vol_in_res = (vol_in_idx == 0) and res_vol_a or res_vol_b
    local vol_out_res = (vol_in_idx == 0) and res_vol_b or res_vol_a

    -- Let's just use the same indices for light ping-ponging
    local light_in_idx = (vol_in_idx == 0) and 2 or 3
    local light_out_idx = (vol_in_idx == 0) and 3 or 2
    local light_in_res = (vol_in_idx == 0) and res_light_a or res_light_b
    local light_out_res = (vol_in_idx == 0) and res_light_b or res_light_a

    rg:add_pass("Physics", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_physics.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_physics.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local pc = ffi.new("PhysicsPC", { ix = move_input[1], iy = move_input[2], iz = move_input[3], dt = dt, img_idx = vol_in_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, hover_target = M.hover_target, hover_strength = M.hover_enabled and M.hover_strength or 0, player_buf_idx = 4 })
        vk.vkCmdPushConstants(cb, pipe_physics.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PhysicsPC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(res_player, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    rg:add_pass("Player_Interact", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_player.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_player.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local pc = ffi.new("PlayerUpdatePC", { img_a = 0, img_b = 1, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = 3, dirty_map_idx = 0, player_buf_idx = 4, plant_seed = input.key_pressed(19) and 1 or 0 })
        vk.vkCmdPushConstants(cb, pipe_player.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PlayerUpdatePC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(res_vol_a, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(res_vol_b, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(res_dirty, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_active, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_player, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    for i=1, num_ticks do
        rg:add_pass("DNA_Update_" .. i, function(cb)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_dna.handle)
            vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_dna.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
            local pc = ffi.new("DNAPC", { img_idx = vol_in_idx, light_img = light_in_idx, entity_buf_idx = 5, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = 3, dirty_map_idx = 0, dt = tick_duration })
            vk.vkCmdPushConstants(cb, pipe_dna.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("DNAPC"), pc)
            vk.vkCmdDispatch(cb, M.max_entities/32, 1, 1)
        end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_in_res, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(res_entities, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

        rg:add_pass("Sim_Tick_" .. i, function(cb)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sim.handle)
            vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sim.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
            local pc = ffi.new("SimTickPC", { in_img = vol_in_idx, out_img = vol_out_idx, light_in_img = light_in_idx, light_out_img = light_out_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = 3, dirty_map_idx = 0 })
            vk.vkCmdPushConstants(cb, pipe_sim.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("SimTickPC"), pc)
            vk.vkCmdDispatch(cb, M.grid_w/16, M.grid_h/16, M.grid_d)
        end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(vol_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_in_res, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(res_active, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
        vol_in_res, vol_out_res = vol_out_res, vol_in_res
        vol_in_idx, vol_out_idx = vol_out_idx, vol_in_idx
        light_in_res, light_out_res = light_out_res, light_in_res
        light_in_idx, light_out_idx = light_out_idx, light_in_idx
    end
    M.current_vol_idx = vol_in_idx

    local cx, cy, cz = M.grid_w/M.chunk_size, M.grid_h/M.chunk_size, M.grid_d/M.chunk_size
    rg:add_pass("Mesher", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mesh.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_mesh.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local pc = ffi.new("MesherPC", { in_img = vol_in_idx, dirty_map_idx = 0, v_buf = 1, indirect_buf = 2, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = 3, px = math.floor(M.player_pos[1]), py = math.floor(M.player_pos[2]), pz = math.floor(M.player_pos[3]) })
        vk.vkCmdPushConstants(cb, pipe_mesh.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("MesherPC"), pc)
        vk.vkCmdDispatch(cb, cx, cy, cz)
    end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(res_dirty, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_active, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_v_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res_indirect, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    rg:add_pass("Sync_Barrier", function(cb)
        local bar = ffi.new("VkMemoryBarrier2", {
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER_2,
            srcStageMask = vk.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT,
            srcAccessMask = vk.VK_ACCESS_2_SHADER_WRITE_BIT,
            dstStageMask = bit.bor(vk.VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT, vk.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT),
            dstAccessMask = bit.bor(vk.VK_ACCESS_2_SHADER_READ_BIT, vk.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT)
        })
        vk.vkCmdPipelineBarrier2(cb, ffi.new("VkDependencyInfo", { sType = vk.VK_STRUCTURE_TYPE_DEPENDENCY_INFO, memoryBarrierCount = 1, pMemoryBarriers = bar }))
    end)

    rg:add_pass("Render", function(cb)
        local color_attach, depth_attach = ffi.new("VkRenderingAttachmentInfo[1]"), ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.5, 0.7, 0.9, 1.0}
        depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout, depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", depth_img.view), vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {depth=1, stencil=0}
        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))

        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, render_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local pc = ffi.new("RenderPC", { mvp = mvp.m, v_buf = 1, light_img = light_in_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, cam_pos = {M.cam_pos_smooth[1], M.cam_pos_smooth[2], M.cam_pos_smooth[3]} })        vk.vkCmdPushConstants(cb, render_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), pc)
        vk.vkCmdBindIndexBuffer(cb, index_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexedIndirect(cb, indirect_buf.handle, 0, cx*cy*cz, 20)
        
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_robot)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, robot_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        local r_pc = ffi.new("RobotRenderPC", { mvp = mvp.m, pos = {M.player_pos[1], M.player_pos[2], M.player_pos[3]}, yaw = M.player_yaw })
        vk.vkCmdPushConstants(cb, robot_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RobotRenderPC"), r_pc)
        vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {robot_v_buf.handle}), ffi.new("VkDeviceSize[1]", {0}))
        vk.vkCmdBindIndexBuffer(cb, robot_i_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexed(cb, M.robot_index_count, 1, 0, 0, 0)
        
        imgui.render(cb, frame_count)
        vk.vkCmdEndRendering(cb)
    end):using(res_v_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(res_depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)

    rg:execute(cb)
    vk.vkEndCommandBuffer(cb)
    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), frame_fence)
    sw:present(queue, img_idx, render_finished_sem)
end

return M
