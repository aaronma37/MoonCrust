local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local image = require("vulkan.image")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local generator = require("examples.51_sdf_renderer.generator")

local M = {}

-- --- Constants & Configuration ---
local LOW_RES_W, LOW_RES_H = 480, 270 
local MAX_BONES = 64
local MAX_SDFS = 128
local MAX_PARTICLES = 2048
local MAX_CONSTRAINTS = 4096
local GRID_CELLS = 16 * 16 * 16
local MAX_FRAMES_IN_FLIGHT = 2

-- --- State ---
local device, queue, graphics_family, sw, bindless_set
local render_img
local bone_buffer, bone_data
local sdf_buffer, sdf_data, sdf_count = 0
local particle_buffer, particle_data, particle_count = 0
local constraint_buffer, constraint_data, constraint_count = 0
local grid_buffer
local render_pipe, physics_pipe, binning_pipe
local pipe_layout, phys_layout, bin_layout
local graph, g_renderImage, g_swImages, g_pBuffer, g_gridBuffer = {}, {}, {}, {}, {}
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local current_frame, current_time = 0, 0
local last_ticks = 0
local fps_frame_count, last_fps_time = 0, 0

local skeleton_tree, skeleton_order
local bone_map = {}

-- --- FFI Definitions ---
ffi.cdef[[
    typedef struct Bone {
        float world_matrix[16];
        float inv_world_matrix[16];
    } Bone;

    typedef struct SDFDescriptor {
        uint32_t bone_index;
        uint32_t primitive_type; 
        uint32_t id;
        uint32_t color_packed;
        float params[4]; 
    } SDFDescriptor;

    typedef struct Particle {
        float pos[4];
        float prev_pos[4];
        float vel[4];
        float inv_mass;
        int32_t bone_index;
        uint32_t id;
        float padding;
        float local_pos[4];
    } Particle;

    typedef struct Constraint {
        uint32_t a, b;
        float rest_length;
        float compliance;
    } Constraint;

    typedef struct PushConstants {
        float cam_pos[4];
        float cam_dir[4];
        float cam_up[4];
        float time;
        uint32_t bone_count;
        uint32_t sdf_count;
        uint32_t out_tex_id;
        uint32_t particle_count;
    } PushConstants;

    typedef struct PhysicsPushConstants {
        float dt;
        uint32_t particle_count;
        uint32_t constraint_count;
        uint32_t sdf_count;
        uint32_t sub_steps;
    } PhysicsPushConstants;

    typedef struct BinningPushConstants {
        uint32_t particle_count;
        float cell_size;
        float insert_radius;
        float padding;
    } BinningPushConstants;
]]

local primitive_map = { sphere = 0, capsule = 1, box = 2, ellipsoid = 3 }

function M.init()
    print("Example 51: Neurosymbolic SDF Renderer (Phase 3: Grid Binning)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    -- 1. Create Skeleton & Character
    skeleton_tree, skeleton_order = generator.create_skeleton()
    for i, name in ipairs(skeleton_order) do bone_map[name] = i - 1 end
    
    local equipped_sdfs = generator.equip_character(skeleton_tree, "base")
    sdf_count = #equipped_sdfs

    local cape_p, cape_c = generator.generate_cape(15, 15, bone_map)
    particle_count = #cape_p
    constraint_count = #cape_c

    -- 2. Create GPU Resources
    render_img = mc.gpu.image(LOW_RES_W, LOW_RES_H, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage_sampled")
    
    bone_buffer = mc.gpu.buffer(ffi.sizeof("Bone") * MAX_BONES, "storage", nil, true)
    bone_data = ffi.cast("Bone*", bone_buffer.allocation.ptr)
    generator.update_matrices(skeleton_tree, skeleton_order, bone_data, bone_map)

    sdf_buffer = mc.gpu.buffer(ffi.sizeof("SDFDescriptor") * MAX_SDFS, "storage", nil, true)
    sdf_data = ffi.cast("SDFDescriptor*", sdf_buffer.allocation.ptr)

    particle_buffer = mc.gpu.buffer(ffi.sizeof("Particle") * MAX_PARTICLES, "storage", nil, true)
    particle_data = ffi.cast("Particle*", particle_buffer.allocation.ptr)

    constraint_buffer = mc.gpu.buffer(ffi.sizeof("Constraint") * MAX_CONSTRAINTS, "storage", nil, true)
    constraint_data = ffi.cast("Constraint*", constraint_buffer.allocation.ptr)

    grid_buffer = mc.gpu.buffer(64 * GRID_CELLS, "storage", nil, false) -- 64 bytes per cell

    -- Fill Buffers
    for i, s in ipairs(equipped_sdfs) do
        local d = sdf_data[i-1]
        d.bone_index, d.primitive_type, d.id, d.color_packed = bone_map[s.bone], primitive_map[s.type] or 0, s.id, s.color
        for j=1,4 do d.params[j-1] = s.params[j] end
    end

    for i, p in ipairs(cape_p) do
        local d = particle_data[i-1]
        d.pos[0], d.pos[1], d.pos[2], d.pos[3] = p.pos[1], p.pos[2], p.pos[3], 1.0
        d.prev_pos[0], d.prev_pos[1], d.prev_pos[2], d.prev_pos[3] = p.pos[1], p.pos[2], p.pos[3], 1.0
        d.vel[0], d.vel[1], d.vel[2], d.vel[3] = 0, 0, 0, 0
        d.inv_mass, d.bone_index, d.id = p.inv_mass, p.bone_index, p.id
        if p.bone_index >= 0 then
            local inv_m = mc.mat4_identity()
            for j=0,15 do inv_m.m[j] = bone_data[p.bone_index].inv_world_matrix[j] end
            local lp = mc.mat4_vec4_multiply(inv_m, {p.pos[1], p.pos[2], p.pos[3], 1.0})
            d.local_pos[0], d.local_pos[1], d.local_pos[2], d.local_pos[3] = lp[1], lp[2], lp[3], 1.0
        end
    end

    for i, c in ipairs(cape_c) do
        local d = constraint_data[i-1]
        d.a, d.b, d.rest_length, d.compliance = c.a, c.b, c.length, c.compliance
    end

    -- 3. Bindless Setup 
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, bone_buffer.handle, 0, bone_buffer.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sdf_buffer.handle, 0, sdf_buffer.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer.handle, 0, particle_buffer.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, constraint_buffer.handle, 0, constraint_buffer.size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, grid_buffer.handle, 0, grid_buffer.size, 4)
    
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, render_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    -- 4. Pipeline Setup
    local stages = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT)
    local render_pc = ffi.new("VkPushConstantRange[1]", {{ stageFlags = stages, offset = 0, size = ffi.sizeof("PushConstants") }})
    local phys_pc = ffi.new("VkPushConstantRange[1]", {{ stageFlags = stages, offset = 0, size = ffi.sizeof("PhysicsPushConstants") }})
    local bin_pc = ffi.new("VkPushConstantRange[1]", {{ stageFlags = stages, offset = 0, size = ffi.sizeof("BinningPushConstants") }})
    
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, render_pc)
    phys_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, phys_pc)
    bin_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, bin_pc)
    
    local render_src = io.open("examples/51_sdf_renderer/render.comp"):read("*all")
    local physics_src = io.open("examples/51_sdf_renderer/physics.comp"):read("*all")
    local binning_src = io.open("examples/51_sdf_renderer/binning.comp"):read("*all")
    
    render_pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(render_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    physics_pipe = pipeline.create_compute_pipeline(device, phys_layout, shader.create_module(device, shader.compile_glsl(physics_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    binning_pipe = pipeline.create_compute_pipeline(device, bin_layout, shader.create_module(device, shader.compile_glsl(binning_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    -- 5. Render Graph Setup
    graph = render_graph.new(device)
    g_renderImage = graph:register_resource("RenderImage", render_graph.TYPE_IMAGE, render_img.handle)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer.handle)
    g_gridBuffer = graph:register_resource("GridBuffer", render_graph.TYPE_BUFFER, grid_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SwapchainImage_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    -- 6. Sync
    local pF = ffi.new("VkFence[1]"); local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})
    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, fence_info, nil, pF); frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); render_finished_sems[i] = pS[0]
    end
    M.cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
end

function M.update()
    local current_ticks = tonumber(sdl.SDL_GetTicks())
    local dt = (current_ticks - last_ticks) / 1000.0
    if last_ticks == 0 then dt = 0 end
    last_ticks = current_ticks
    current_time = current_time + dt

    fps_frame_count = fps_frame_count + 1
    if current_time - last_fps_time >= 1.0 then
        local fps = fps_frame_count / (current_time - last_fps_time)
        sdl.SDL_SetWindowTitle(_G._SDL_WINDOW, string.format("MoonCrust | Ex 51 | FPS: %.1f", fps))
        fps_frame_count = 0
        last_fps_time = current_time
    end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame])
    if img_idx == nil then return end 
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}))

    generator.apply_pose(skeleton_tree, current_time, "walk")
    generator.update_matrices(skeleton_tree, skeleton_order, bone_data, bone_map)

    local cb = M.cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc_phys = ffi.new("PhysicsPushConstants", { dt = dt, particle_count = particle_count, constraint_count = constraint_count, sdf_count = sdf_count, sub_steps = 16 })
    local pc_bin = ffi.new("BinningPushConstants", { particle_count = particle_count, cell_size = 0.25, insert_radius = 0.18, padding = 0 })
    local pc_render = ffi.new("PushConstants")
    pc_render.cam_pos, pc_render.cam_dir, pc_render.cam_up = {0, 0.5, -3, 1}, {0, 0, 1, 0}, {0, 1, 0, 0}
    pc_render.time, pc_render.bone_count, pc_render.sdf_count, pc_render.particle_count, pc_render.out_tex_id = current_time, #skeleton_order, sdf_count, particle_count, 0

    graph:reset()
    
    graph:add_pass("Physics", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, physics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, phys_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, phys_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PhysicsPushConstants"), pc_phys)
        vk.vkCmdDispatch(c, math.ceil(particle_count / 256), 1, 1)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("ClearGrid", function(c)
        vk.vkCmdFillBuffer(c, grid_buffer.handle, 0, grid_buffer.size, 0)
    end):using(g_gridBuffer, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)

    graph:add_pass("Binning", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, binning_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, bin_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, bin_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("BinningPushConstants"), pc_bin)
        vk.vkCmdDispatch(c, math.ceil(particle_count / 256), 1, 1)
    end):using(g_gridBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Raymarch", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, render_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("PushConstants"), pc_render)
        vk.vkCmdDispatch(c, math.ceil(LOW_RES_W / 16), math.ceil(LOW_RES_H / 16), 1)
    end):using(g_renderImage, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_gridBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("BlitToSwapchain", function(c)
        local blit = ffi.new("VkImageBlit[1]")
        blit[0].srcSubresource, blit[0].dstSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, layerCount = 1 }, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, layerCount = 1 }
        blit[0].srcOffsets[1], blit[0].dstOffsets[1] = { x = LOW_RES_W, y = LOW_RES_H, z = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }
        vk.vkCmdBlitImage(c, render_img.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, sw.images[img_idx], vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, blit, vk.VK_FILTER_LINEAR)
    end):using(g_renderImage, vk.VK_ACCESS_TRANSFER_READ_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
       :using(g_swImages[img_idx], vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sems[current_frame]}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sems[current_frame]}) }), frame_fences[current_frame])
    sw:present(queue, img_idx, render_finished_sems[current_frame])
    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
