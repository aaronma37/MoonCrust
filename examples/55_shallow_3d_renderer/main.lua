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
    macro_w = 64,
    macro_h = 16,
    macro_d = 64,
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
    fps = 0,
    current_vol_idx = 0,
    current_active_idx = 0,
    active_chunks = 0
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
        uint32_t in_img, out_img, light_in_img, light_out_img, grid_w, grid_h, grid_d, active_map_idx, dirty_map_idx, out_active_map_idx, stats_buf_idx, p1; 
    } SimTickPC;

    typedef struct DNAPC { 
        uint32_t img_idx, light_img, entity_buf_idx, grid_w, grid_h, grid_d, active_map_idx, dirty_map_idx, out_active_map_idx, p0, p1; 
        float dt; 
    } DNAPC;

    typedef struct GIPC { 
        uint32_t in_img, out_img, light_in_idx, light_out_idx, grid_w, grid_h, grid_d, macro_w, macro_h, macro_d; 
    } GIPC;

    typedef struct MesherPC { 
        uint32_t in_img, dirty_map_idx, v_buf, indirect_buf, grid_w, grid_h, grid_d, active_map_idx; 
        int32_t px, py, pz, p0; 
    } MesherPC;

    typedef struct RenderPC { 
        float mvp[16]; 
        float light_mvp[16];
        uint32_t v_buf, light_img, grid_w, grid_h;
        uint32_t grid_d, macro_w, macro_h, macro_d;
        uint32_t shadow_idx;
        float p0, p1, p2; 
        float cam_pos[3], p3;
    } RenderPC;

    typedef struct ShadowPC {
        float mvp[16];
        uint32_t v_buf, light_img, grid_w, grid_h;
        uint32_t grid_d, p0, p1, p2;
    } ShadowPC;

    typedef struct RobotRenderPC {
        float mvp[16];
        float pos[3], yaw;
    } RobotRenderPC;
]]

function M.init()
    print("Example 55: Voxel Automation Game - Hardened Stage 1")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    state.device = vulkan.get_device()
    state.queue, state.graphics_family = vulkan.get_queue()
    
    state.sw = swapchain.new(instance, physical_device, state.device, _G._SDL_WINDOW)
    state.rg = graph.new(state.device)
    imgui.init(state.sw.format)

    state.vol_a = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.vol_b = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.light_vol_a = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.light_vol_b = mc.gpu.image_3d(M.grid_w, M.grid_h, M.grid_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    
    state.macro_light_a = mc.gpu.image_3d(M.macro_w, M.macro_h, M.macro_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    state.macro_light_b = mc.gpu.image_3d(M.macro_w, M.macro_h, M.macro_d, vk.VK_FORMAT_R32_UINT, "storage sampled")
    
    state.depth_img = mc.gpu.image(state.sw.extent.width, state.sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    state.shadow_img = mc.gpu.image(4096, 4096, vk.VK_FORMAT_D32_SFLOAT, "depth sampled")
    state.shadow_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR, vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER)
    
    local num_chunks = (M.grid_w/M.chunk_size) * (M.grid_h/M.chunk_size) * (M.grid_d/M.chunk_size)
    state.dirty_map = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    state.active_map_a = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    state.active_map_b = mc.gpu.buffer(num_chunks * 4, "storage", nil, true)
    state.v_buf = mc.gpu.buffer(num_chunks * 16384 * 4, "storage", nil, false)
    state.indirect_buf = mc.gpu.buffer(num_chunks * 20, "indirect", nil, true)
    
    state.stats_buf = mc.gpu.buffer(64, "storage", nil, true)
    
    local init_player = ffi.new("PlayerState", { pos = {256, 40, 256}, yaw = 0, vel = {0, 0, 0} })
    state.player_state_buf = mc.gpu.buffer(ffi.sizeof("PlayerState"), "storage", init_player, true)
    state.entity_buf = mc.gpu.buffer(M.max_entities * ffi.sizeof("Entity"), "storage", nil, true)

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
    state.robot_v_buf = mc.gpu.buffer(v_idx * 4, "vertex", r_verts, false)
    state.robot_i_buf = mc.gpu.buffer(i_idx * 2, "index", r_indices, false)
    M.robot_index_count = i_idx

    local index_data = ffi.new("uint16_t[?]", 65536)
    for i=0, 10000 do
        local b, o = i*4, i*6
        index_data[o+0], index_data[o+1], index_data[o+2] = b+0, b+1, b+2
        index_data[o+3], index_data[o+4], index_data[o+5] = b+0, b+2, b+3
    end
    state.index_buf = mc.gpu.buffer(ffi.sizeof(index_data), "index", index_data, false)

    state.res_vol_a = state.rg:register_resource("vol_a", graph.TYPE_IMAGE, state.vol_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_vol_b = state.rg:register_resource("vol_b", graph.TYPE_IMAGE, state.vol_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_light_a = state.rg:register_resource("light_a", graph.TYPE_IMAGE, state.light_vol_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_light_b = state.rg:register_resource("light_b", graph.TYPE_IMAGE, state.light_vol_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    
    state.res_macro_a = state.rg:register_resource("macro_a", graph.TYPE_IMAGE, state.macro_light_a.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    state.res_macro_b = state.rg:register_resource("macro_b", graph.TYPE_IMAGE, state.macro_light_b.handle, { layout = vk.VK_IMAGE_LAYOUT_GENERAL, access = vk.VK_ACCESS_SHADER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT })
    
    state.res_dirty = state.rg:register_resource("dirty", graph.TYPE_BUFFER, state.dirty_map.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    state.res_active_a = state.rg:register_resource("active_a", graph.TYPE_BUFFER, state.active_map_a.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    state.res_active_b = state.rg:register_resource("active_b", graph.TYPE_BUFFER, state.active_map_b.handle, { access = vk.VK_ACCESS_TRANSFER_WRITE_BIT, stage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT })
    state.res_v_buf = state.rg:register_resource("v_buf", graph.TYPE_BUFFER, state.v_buf.handle)
    state.res_indirect = state.rg:register_resource("indirect", graph.TYPE_BUFFER, state.indirect_buf.handle)
    state.res_depth = state.rg:register_resource("depth", graph.TYPE_IMAGE, state.depth_img.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED, access = 0, stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT })
    state.res_shadow = state.rg:register_resource("shadow", graph.TYPE_IMAGE, state.shadow_img.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED, access = 0, stage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT })
    state.res_player = state.rg:register_resource("player", graph.TYPE_BUFFER, state.player_state_buf.handle)
    state.res_entities = state.rg:register_resource("entities", graph.TYPE_BUFFER, state.entity_buf.handle)
    state.res_stats = state.rg:register_resource("stats", graph.TYPE_BUFFER, state.stats_buf.handle)

    state.bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.vol_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.vol_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 1)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.light_vol_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 2)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.light_vol_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 3)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.macro_light_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 4)
    descriptors.update_storage_image_set(state.device, state.bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, state.macro_light_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 5)
    descriptors.update_image_set(state.device, state.bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, state.shadow_img.view, state.shadow_sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 10)
    
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.dirty_map.handle, 0, state.dirty_map.size, 0)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.v_buf.handle, 0, state.v_buf.size, 1)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.indirect_buf.handle, 0, state.indirect_buf.size, 2)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.active_map_a.handle, 0, state.active_map_a.size, 3)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.active_map_b.handle, 0, state.active_map_b.size, 6)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.player_state_buf.handle, 0, state.player_state_buf.size, 4)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.entity_buf.handle, 0, state.entity_buf.size, 5)
    descriptors.update_buffer_set(state.device, state.bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, state.stats_buf.handle, 0, state.stats_buf.size, 7)

    state.pipe_sim = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/sim.comp", ffi.sizeof("SimTickPC"))
    state.pipe_gi = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gi.comp", ffi.sizeof("GIPC"))
    state.pipe_mesh = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/mesh.comp", ffi.sizeof("MesherPC"))
    state.pipe_gen = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/gen.comp", 16)
    state.pipe_player = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/player.comp", ffi.sizeof("PlayerUpdatePC"))
    state.pipe_physics = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/physics.comp", ffi.sizeof("PhysicsPC"))
    state.pipe_dna = mc.gpu.compute_pipeline("examples/55_shallow_3d_renderer/dna.comp", ffi.sizeof("DNAPC"))
    
    local bl_layout = mc.gpu.get_bindless_layout()
    local pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RenderPC") }})
    state.render_layout = pipeline.create_layout(state.device, {bl_layout}, pc_ranges)
    local v_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    state.pipe_render = pipeline.create_graphics_pipeline(state.device, state.render_layout, v_mod, f_mod, { depth_test = true, depth_write = true, cull_mode = vk.VK_CULL_MODE_BACK_BIT, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = { state.sw.format } })

    local shadow_pc_ranges = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = ffi.sizeof("ShadowPC") }})
    state.shadow_layout = pipeline.create_layout(state.device, {bl_layout}, shadow_pc_ranges)
    local sv_mod = shader.create_module(state.device, shader.compile_glsl(io.open("examples/55_shallow_3d_renderer/shadow.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    state.pipe_shadow = pipeline.create_graphics_pipeline(state.device, state.shadow_layout, sv_mod, nil, { 
        depth_test = true, depth_write = true, depth_format = vk.VK_FORMAT_D32_SFLOAT, color_formats = {},
        depth_bias_enable = true, depth_bias_constant = 4.0, depth_bias_slope = 1.5
    })

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
    local vol_bar = ffi.new("VkImageMemoryBarrier[7]")
    for i=0,6 do
        vol_bar[i].sType, vol_bar[i].oldLayout, vol_bar[i].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL
        if i == 0 then vol_bar[i].image = state.vol_a.handle
        elseif i == 1 then vol_bar[i].image = state.vol_b.handle
        elseif i == 2 then vol_bar[i].image = state.light_vol_a.handle
        elseif i == 3 then vol_bar[i].image = state.light_vol_b.handle
        elseif i == 4 then vol_bar[i].image = state.macro_light_a.handle
        elseif i == 5 then vol_bar[i].image = state.macro_light_b.handle
        elseif i == 6 then 
            vol_bar[i].image = state.shadow_img.handle
            vol_bar[i].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
        end
        vol_bar[i].srcAccessMask, vol_bar[i].dstAccessMask = 0, vk.VK_ACCESS_SHADER_WRITE_BIT
        vol_bar[i].subresourceRange = { aspectMask = (i == 6) and vk.VK_IMAGE_ASPECT_DEPTH_BIT or vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    end
    vk.vkCmdPipelineBarrier(gcb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 7, vol_bar)
    vk.vkCmdFillBuffer(gcb, state.dirty_map.handle, 0, state.dirty_map.size, 1)
    vk.vkCmdFillBuffer(gcb, state.active_map_a.handle, 0, state.active_map_a.size, 1)
    vk.vkCmdFillBuffer(gcb, state.active_map_b.handle, 0, state.active_map_b.size, 1)
    vk.vkCmdFillBuffer(gcb, state.v_buf.handle, 0, state.v_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, state.indirect_buf.handle, 0, state.indirect_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, state.entity_buf.handle, 0, state.entity_buf.size, 0)
    vk.vkCmdFillBuffer(gcb, state.stats_buf.handle, 0, state.stats_buf.size, 0)
    
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gen.handle)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gen.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
    for i=0,1 do
        vk.vkCmdPushConstants(gcb, state.pipe_gen.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, ffi.new("uint32_t[4]", {i, M.grid_w, M.grid_h, M.grid_d}))
        vk.vkCmdDispatch(gcb, M.grid_w/16, M.grid_h/16, M.grid_d)
    end
    
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
    
    -- Cap maximum dt to prevent death-spirals on huge lags or breakpoint hits
    if dt > 0.1 then dt = 0.1 end

    vk.vkWaitForFences(state.device, 1, ffi.new("VkFence[1]", {state.frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(state.device, 1, ffi.new("VkFence[1]", {state.frame_fence}))
    local img_idx = state.sw:acquire_next_image(state.image_available_sem)
    if img_idx == nil then return end

    state.frame_count = state.frame_count + 1
    M.current_time = M.current_time + dt
    M.accumulated_time = M.accumulated_time + dt
    local tick_duration = 1.0 / M.tick_rate
    local num_ticks = math.floor(M.accumulated_time / tick_duration)
    M.accumulated_time = M.accumulated_time - (num_ticks * tick_duration)

    if M.current_time - state.last_fps_time > 1.0 then
        M.fps = state.frame_count
        state.frame_count = 0
        state.last_fps_time = M.current_time
        -- Sync stats back to Lua
        local s_ptr = ffi.cast("uint32_t*", state.stats_buf.allocation.ptr)
        M.active_chunks = s_ptr[0]
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
    M.prev_player_pos = {math.floor(M.player_pos[1]), math.floor(M.player_pos[2]), math.floor(M.player_pos[3])}
    M.player_pos = {p_ptr.pos[0], p_ptr.pos[1], p_ptr.pos[2]}
    p_ptr.yaw = M.player_yaw

    if input.key_pressed(19) then 
        local e_ptr = ffi.cast("Entity*", state.entity_buf.allocation.ptr)
        local idx = M.next_entity_idx % M.max_entities
        e_ptr[idx].pos = {math.floor(M.player_pos[1]), math.floor(M.player_pos[2]), math.floor(M.player_pos[3])}
        e_ptr[idx].type = 1 
        e_ptr[idx].energy = 1000
        e_ptr[idx].age = 0
        M.next_entity_idx = M.next_entity_idx + 1
    end

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

    -- Shadow Matrix Calculation
    local sun_dir = {0.5, 1.0, 0.3}
    local sun_len = math.sqrt(sun_dir[1]^2 + sun_dir[2]^2 + sun_dir[3]^2)
    sun_dir[1], sun_dir[2], sun_dir[3] = sun_dir[1]/sun_len, sun_dir[2]/sun_len, sun_dir[3]/sun_len
    
    local shadow_range = 300.0
    local shadow_proj = mc.mat4_ortho(-shadow_range, shadow_range, -shadow_range, shadow_range, 0.1, 500.0)
    local shadow_view = mc.mat4_look_at({M.player_pos[1] + sun_dir[1]*200, M.player_pos[2] + sun_dir[2]*200, M.player_pos[3] + sun_dir[3]*200}, {M.player_pos[1], M.player_pos[2], M.player_pos[3]}, {0,1,0})
    local light_mvp = mc.mat4_multiply(shadow_proj, shadow_view)

    imgui.new_frame()
    imgui.gui.igBegin("MoonCrust Debug", nil, 0)
    imgui.gui.igText("FPS: " .. M.fps)
    imgui.gui.igText("Active Chunks: " .. M.active_chunks)
    imgui.gui.igSeparator()
    imgui.gui.igText(string.format("Robot: %.1f, %.1f, %.1f", M.player_pos[1], M.player_pos[2], M.player_pos[3]))
    imgui.gui.igText("Entities: " .. M.next_entity_idx)
    imgui.gui.igSeparator()
    imgui.gui.igText("Macro-GI Rollout (64x16x64)")
    imgui.gui.igEnd()

    local cb = state.cbs[img_idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
    state.rg:reset()
    
    local vol_in_idx = M.current_vol_idx
    local vol_out_idx = (vol_in_idx == 0) and 1 or 0
    local vol_in_res = (vol_in_idx == 0) and state.res_vol_a or state.res_vol_b
    local vol_out_res = (vol_in_idx == 0) and state.res_vol_b or state.res_vol_a

    local light_in_idx = (vol_in_idx == 0) and 4 or 5
    local light_out_idx = (vol_in_idx == 0) and 5 or 4
    local light_in_res = (vol_in_idx == 0) and state.res_macro_a or state.res_macro_b
    local light_out_res = (vol_in_idx == 0) and state.res_macro_b or state.res_macro_a

    local act_in_idx = M.current_active_idx
    local act_out_idx = (act_in_idx == 0) and 1 or 0
    local act_in_res = (act_in_idx == 0) and state.res_active_a or state.res_active_b
    local act_out_res = (act_in_idx == 0) and state.res_active_b or state.res_active_a
    local act_in_bind = (act_in_idx == 0) and 3 or 6
    local act_out_bind = (act_in_idx == 0) and 6 or 3

    state.rg:add_pass("Clear_Active", function(cb)
        vk.vkCmdFillBuffer(cb, (act_out_idx == 0) and state.active_map_a.handle or state.active_map_b.handle, 0, state.active_map_a.size, 0)
        vk.vkCmdFillBuffer(cb, state.dirty_map.handle, 0, state.dirty_map.size, 0)
        vk.vkCmdFillBuffer(cb, state.stats_buf.handle, 0, 4, 0) -- Reset active chunk counter
    end):using(act_out_res, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)
       :using(state.res_dirty, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)
       :using(state.res_stats, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)

    state.rg:add_pass("Physics", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_physics.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_physics.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("PhysicsPC", { ix = move_input[1], iy = move_input[2], iz = move_input[3], dt = dt, img_idx = vol_in_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, hover_target = M.hover_target, hover_strength = M.hover_enabled and M.hover_strength or 0, player_buf_idx = 4 })
        vk.vkCmdPushConstants(cb, state.pipe_physics.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PhysicsPC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_player, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    state.rg:add_pass("Player_Interact", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_player.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_player.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("PlayerUpdatePC", { img_a = 0, img_b = 1, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = act_out_bind, dirty_map_idx = 0, player_buf_idx = 4, plant_seed = input.key_pressed(19) and 1 or 0, stats_buf_idx = 7 })
        vk.vkCmdPushConstants(cb, state.pipe_player.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PlayerUpdatePC"), pc)
        vk.vkCmdDispatch(cb, 1, 1, 1)
    end):using(state.res_vol_a, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_vol_b, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_dirty, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(act_out_res, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_player, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_stats, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    for i=1, num_ticks do
        state.rg:add_pass("DNA_Update_" .. i, function(cb)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_dna.handle)
            vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_dna.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
            local pc = ffi.new("DNAPC", { img_idx = vol_in_idx, light_img = light_in_idx, entity_buf_idx = 5, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = act_in_bind, dirty_map_idx = 0, out_active_map_idx = act_out_bind, stats_buf_idx = 7, dt = tick_duration })
            vk.vkCmdPushConstants(cb, state.pipe_dna.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("DNAPC"), pc)
            vk.vkCmdDispatch(cb, M.max_entities/32, 1, 1)
        end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_in_res, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(state.res_entities, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(act_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(act_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(state.res_stats, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

        state.rg:add_pass("Sim_Tick_" .. i, function(cb)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_sim.handle)
            vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_sim.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
            local pc = ffi.new("SimTickPC", { in_img = vol_in_idx, out_img = vol_out_idx, light_in_img = light_in_idx, light_out_img = light_out_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = act_in_bind, dirty_map_idx = 0, out_active_map_idx = act_out_bind, stats_buf_idx = 7 })
            vk.vkCmdPushConstants(cb, state.pipe_sim.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("SimTickPC"), pc)
            vk.vkCmdDispatch(cb, M.grid_w/16, M.grid_h/16, M.grid_d)
        end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(vol_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(act_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(act_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
           :using(state.res_stats, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

        state.rg:add_pass("Macro_GI_" .. i, function(cb)
            vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gi.handle)
            vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_gi.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
            local pc = ffi.new("GIPC", { in_img = vol_in_idx, out_img = vol_out_idx, light_in_idx = light_in_idx, light_out_idx = light_out_idx, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, macro_w = M.macro_w, macro_h = M.macro_h, macro_d = M.macro_d })
            vk.vkCmdPushConstants(cb, state.pipe_gi.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("GIPC"), pc)
            vk.vkCmdDispatch(cb, M.macro_w/4, M.macro_h/4, M.macro_d/4)
        end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(light_out_res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
        
        vol_in_res, vol_out_res = vol_out_res, vol_in_res
        vol_in_idx, vol_out_idx = vol_out_idx, vol_in_idx
        light_in_res, light_out_res = light_out_res, light_in_res
        light_in_idx, light_out_idx = light_out_idx, light_in_idx
    end
    M.current_vol_idx = vol_in_idx
    M.current_active_idx = act_out_idx

    local cx, cy, cz = M.grid_w/M.chunk_size, M.grid_h/M.chunk_size, M.grid_d/M.chunk_size
    state.rg:add_pass("Mesher", function(cb)
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_mesh.handle)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, state.pipe_mesh.layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local pc = ffi.new("MesherPC", { in_img = vol_in_idx, dirty_map_idx = 0, v_buf = 1, indirect_buf = 2, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, active_map_idx = act_in_bind, px = math.floor(M.player_pos[1]), py = math.floor(M.player_pos[2]), pz = math.floor(M.player_pos[3]) })
        vk.vkCmdPushConstants(cb, state.pipe_mesh.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("MesherPC"), pc)
        vk.vkCmdDispatch(cb, cx, cy, cz)
    end):using(vol_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(state.res_dirty, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(act_in_res, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_v_buf, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(state.res_indirect, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    state.rg:add_pass("Shadow", function(cb)
        local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout, depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", state.shadow_img.view), vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {depth=1, stencil=0}
        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent={width=4096, height=4096}}, layerCount=1, colorAttachmentCount=0, pDepthAttachment=depth_attach }))
        vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=4096, height=4096, maxDepth=1 }))
        vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent={width=4096, height=4096} }))
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.pipe_shadow)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, state.shadow_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {state.bindless_set}), 0, nil)
        local spc = ffi.new("ShadowPC", { mvp = light_mvp.m, v_buf = 1, light_img = 4, grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d })
        vk.vkCmdPushConstants(cb, state.shadow_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("ShadowPC"), spc)
        vk.vkCmdBindIndexBuffer(cb, state.index_buf.handle, 0, vk.VK_INDEX_TYPE_UINT16)
        vk.vkCmdDrawIndexedIndirect(cb, state.indirect_buf.handle, 0, cx*cy*cz, 20)
        vk.vkCmdEndRendering(cb)
    end):using(state.res_shadow, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
       :using(state.res_v_buf, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(state.res_indirect, vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT)

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
            light_img = light_in_idx, 
            grid_w = M.grid_w, grid_h = M.grid_h, grid_d = M.grid_d, 
            macro_w = M.macro_w, macro_h = M.macro_h, macro_d = M.macro_d, 
            shadow_idx = 10,
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
       :using(state.res_shadow, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
       :using(state.res_depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)

    state.rg:execute(cb)
    vk.vkEndCommandBuffer(cb)
    local render_finished_sem = state.sw.semaphores[img_idx]
    vk.vkQueueSubmit(state.queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {state.image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) }), state.frame_fence)
    state.sw:present(state.queue, img_idx, render_finished_sem)
end

return M
