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
local input = require("mc.input")

local generator = require("examples.52_csg_dual_contouring.generator")

local M = {}

-- --- Constants ---
local MAX_BONES = 64
local MAX_SDFS = 512
local GRID_SIZE = { 96, 192, 96 }
local MAX_VERTICES = 256 * 1024
local MAX_INDICES = 512 * 1024
local MAX_FRAMES_IN_FLIGHT = 2

-- --- State ---
local device, queue, graphics_family, sw, bindless_set
local depth_img
local bone_buffer, bone_data
local sdf_buffer, sdf_data, sdf_count = 0
local grid_buffer, vertex_buffer, index_buffer, counter_buffer, cell_buffer, floor_buffer
local field_pipe, vertex_pipe, index_pipe, graphics_pipe, reset_pipe, outline_pipe, floor_pipe
local field_layout, vertex_layout, index_layout, graphics_layout, floor_layout
local graph, g_swImages, g_gridBuffer, g_vertexBuffer, g_indexBuffer, g_counterBuffer, g_cellBuffer = {}, {}, {}, {}, {}, {}, {}
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local current_frame, current_time = 0, 0
local last_ticks = 0
local mesh_baked = false
local frame_count = 0
local fps_timer = 0

local animations = {"rest", "walk", "idle", "run", "wave"}
local current_anim_idx = 1
local debug_mode = 0
local debug_bone = 0

local char_pos = {0, 0, 0}
local char_yaw = 0

local cam_rot = {0, 0}
local cam_dist = 5.0
local cam_target = {0, 0.4, 0}

local skeleton_tree, skeleton_order, bone_map = {}, {}, {}

ffi.cdef[[
    typedef struct Bone {
        float world_matrix[16];
        float inv_world_matrix[16];
        float bind_matrix[16];
        float inv_bind_matrix[16];
        float bounding_radius;
        uint32_t sdf_offset;
        uint32_t sdf_count;
        uint32_t padding;
    } Bone;

    typedef struct SDFDescriptor {
        uint32_t bone_index;
        uint32_t primitive_type; 
        uint32_t id;
        uint32_t color_packed;
        float params[4]; 
        float local_offset[4];
    } SDFDescriptor;

    typedef struct FieldPC {
        float bounds_min[3]; uint32_t bone_count;
        float bounds_max[3]; uint32_t sdf_count;
        uint32_t grid_size[3]; uint32_t padding;
        // Bindless Indices
        uint32_t bones_idx;
        uint32_t sdfs_idx;
        uint32_t grid_idx;
        uint32_t vertices_idx;
        uint32_t indices_idx;
        uint32_t counter_idx;
        uint32_t cell_idx;
        uint32_t vertex_counter_idx;
    } FieldPC;

    typedef struct RenderPC {
        float projection[16];
        float view[16];
        float cam_pos[4]; // vec4 for alignment
        uint32_t bone_count;
        uint32_t bones_idx;
        float outline_thickness;
        uint32_t outline_mode;
        uint32_t debug_mode;
        uint32_t debug_bone;
        uint32_t padding[2];
    } RenderPC;

    typedef struct GPUVertex {
        float pos[4];
        float normal[4];
        float color[4];
        uint32_t bone_ids[4];
        float bone_weights[4];
    } GPUVertex;
]]

local primitive_map = { sphere = 0, capsule = 1, box = 2, ellipsoid = 3 }

function M.init()
    print("Example 52: Neurosymbolic CSG & GPU Dual Contouring")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    skeleton_tree, skeleton_order = generator.create_skeleton()
    for i, name in ipairs(skeleton_order) do bone_map[name] = i - 1 end
    local grouped_sdfs = generator.equip_character(skeleton_tree, {}, 0)

    -- 1. Create Buffers
    bone_buffer = mc.gpu.buffer(ffi.sizeof("Bone") * MAX_BONES, "storage", nil, true)
    bone_data = ffi.cast("Bone*", bone_buffer.allocation.ptr)
    
    sdf_buffer = mc.gpu.buffer(ffi.sizeof("SDFDescriptor") * MAX_SDFS, "storage", nil, true)
    sdf_data = ffi.cast("SDFDescriptor*", sdf_buffer.allocation.ptr)

    local total_nodes = GRID_SIZE[1] * GRID_SIZE[2] * GRID_SIZE[3]
    grid_buffer = mc.gpu.buffer(total_nodes * 48, "storage", nil, false) -- 48 bytes per GridNode
    cell_buffer = mc.gpu.buffer(total_nodes * 4, "storage", nil, false) -- Vertex index per cell
    vertex_buffer = mc.gpu.buffer(ffi.sizeof("GPUVertex") * MAX_VERTICES, "storage_vertex", nil, false)
    index_buffer = mc.gpu.buffer(4 * MAX_INDICES, "storage_index", nil, false)
    counter_buffer = mc.gpu.buffer(64, "storage_transfer_indirect", nil, true) -- 20 bytes cmd + extra room

    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")

    -- Floor Buffer (Simple Quad)
    local floor_verts = ffi.new("float[12]", {
        -1, 0, -1,
         1, 0, -1,
         1, 0,  1,
        -1, 0,  1
    })
    local floor_indices = ffi.new("uint32_t[6]", { 0, 1, 2, 0, 2, 3 })
    floor_buffer = mc.gpu.buffer(48 + 24, "vertex_index", nil, true)
    ffi.copy(floor_buffer.allocation.ptr, floor_verts, 48)
    ffi.copy(ffi.cast("char*", floor_buffer.allocation.ptr) + 48, floor_indices, 24)

    -- Fill SDFs and initial Bones
    generator.update_matrices(skeleton_tree, skeleton_order, bone_data, bone_map)
    local current_sdf_idx = 0
    for i, name in ipairs(skeleton_order) do
        local b_idx = i - 1
        local group = grouped_sdfs[name]
        if group then
            bone_data[b_idx].bounding_radius = group.radius
            bone_data[b_idx].sdf_offset = current_sdf_idx
            bone_data[b_idx].sdf_count = #group.sdfs
            for _, s in ipairs(group.sdfs) do
                local d = sdf_data[current_sdf_idx]
                d.bone_index = b_idx
                d.primitive_type = primitive_map[s.type] or 0
                d.id = s.id
                d.color_packed = s.color
                for j=1,4 do d.params[j-1] = s.params[j] end
                for j=1,4 do d.local_offset[j-1] = s.offset and s.offset[j] or 0 end
                current_sdf_idx = current_sdf_idx + 1
            end
        end
    end
    sdf_count = current_sdf_idx

    -- 2. Bindless Updates
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, bone_buffer.handle, 0, bone_buffer.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sdf_buffer.handle, 0, sdf_buffer.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, grid_buffer.handle, 0, grid_buffer.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, vertex_buffer.handle, 0, vertex_buffer.size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, index_buffer.handle, 0, index_buffer.size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, counter_buffer.handle, 0, counter_buffer.size, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, cell_buffer.handle, 0, cell_buffer.size, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, counter_buffer.handle, 24, 4, 7) -- vertexCount internal tracker

    -- 3. Pipelines
    local pc_field_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = ffi.sizeof("FieldPC") }})
    field_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_field_range)
    
    local function create_compute(src_file, layout)
        local src = io.open("examples/52_csg_dual_contouring/"..src_file):read("*all")
        return pipeline.create_compute_pipeline(device, layout, shader.create_module(device, shader.compile_glsl(src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    end
    field_pipe = create_compute("field.comp", field_layout)
    vertex_pipe = create_compute("vertex.comp", field_layout)
    index_pipe = create_compute("index.comp", field_layout)
    reset_pipe = create_compute("reset.comp", field_layout)

    -- Graphics Pipe
    local pc_gfx_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("RenderPC") }})
    graphics_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_gfx_range)
    
    local vert_src = io.open("examples/52_csg_dual_contouring/skinning.vert"):read("*all")
    local frag_src = io.open("examples/52_csg_dual_contouring/pbr.frag"):read("*all")
    
    local vi = ffi.new("VkPipelineVertexInputStateCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO })
    local bindings = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = ffi.sizeof("GPUVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }})
    local attrs = ffi.new("VkVertexInputAttributeDescription[5]", {
        { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 0 },
        { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 16 },
        { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 32 },
        { location = 3, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_UINT, offset = 48 },
        { location = 4, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 64 },
    })
    vi.vertexBindingDescriptionCount, vi.pVertexBindingDescriptions = 1, bindings
    vi.vertexAttributeDescriptionCount, vi.pVertexAttributeDescriptions = 5, attrs

    local vert_mod = shader.create_module(device, shader.compile_glsl(vert_src, vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag_mod = shader.create_module(device, shader.compile_glsl(frag_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    
    local outline_frag_src = io.open("examples/52_csg_dual_contouring/outline.frag"):read("*all")
    local outline_frag_mod = shader.create_module(device, shader.compile_glsl(outline_frag_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    graphics_pipe = pipeline.create_graphics_pipeline(device, graphics_layout, vert_mod, frag_mod, {
        vertex_binding = bindings,
        vertex_attributes = attrs,
        vertex_attribute_count = 5,
        depth_test = true,
        depth_write = true,
        depth_format = vk.VK_FORMAT_D32_SFLOAT,
        color_formats = {sw.format},
        cull_mode = vk.VK_CULL_MODE_BACK_BIT -- Standard backface culling
    })

    outline_pipe = pipeline.create_graphics_pipeline(device, graphics_layout, vert_mod, outline_frag_mod, {
        vertex_binding = bindings,
        vertex_attributes = attrs,
        vertex_attribute_count = 5,
        depth_test = true,
        depth_write = true,
        depth_compare_op = vk.VK_COMPARE_OP_LESS_OR_EQUAL,
        depth_format = vk.VK_FORMAT_D32_SFLOAT,
        color_formats = {sw.format},
        cull_mode = vk.VK_CULL_MODE_FRONT_BIT -- CULL FRONT for inverted hull
    })

    -- Floor Pipe
    local floor_pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 140 }})
    floor_layout = pipeline.create_layout(device, {}, floor_pc_range)
    local floor_vert_src = io.open("examples/52_csg_dual_contouring/floor.vert"):read("*all")
    local floor_frag_src = io.open("examples/52_csg_dual_contouring/floor.frag"):read("*all")
    local floor_vert_mod = shader.create_module(device, shader.compile_glsl(floor_vert_src, vk.VK_SHADER_STAGE_VERTEX_BIT))
    local floor_frag_mod = shader.create_module(device, shader.compile_glsl(floor_frag_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local floor_vi_bindings = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 12, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }})
    local floor_vi_attrs = ffi.new("VkVertexInputAttributeDescription[1]", {{ location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 }})
    
    floor_pipe = pipeline.create_graphics_pipeline(device, floor_layout, floor_vert_mod, floor_frag_mod, {
        vertex_binding = floor_vi_bindings,
        vertex_attributes = floor_vi_attrs,
        vertex_attribute_count = 1,
        depth_test = true,
        depth_write = false,
        depth_format = vk.VK_FORMAT_D32_SFLOAT,
        color_formats = {sw.format},
        blend = true
    })

    -- 4. Graph & Cbs
    graph = render_graph.new(device)
    g_gridBuffer = graph:register_resource("GridBuffer", render_graph.TYPE_BUFFER, grid_buffer.handle)
    g_vertexBuffer = graph:register_resource("VertexBuffer", render_graph.TYPE_BUFFER, vertex_buffer.handle)
    g_indexBuffer = graph:register_resource("IndexBuffer", render_graph.TYPE_BUFFER, index_buffer.handle)
    g_counterBuffer = graph:register_resource("CounterBuffer", render_graph.TYPE_BUFFER, counter_buffer.handle)
    g_cellBuffer = graph:register_resource("CellBuffer", render_graph.TYPE_BUFFER, cell_buffer.handle)
    g_depthImage = graph:register_resource("DepthImage", render_graph.TYPE_IMAGE, depth_img.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SwapchainImage_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    local pF = ffi.new("VkFence[1]"); local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})
    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, fence_info, nil, pF); frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); render_finished_sems[i] = pS[0]
    end
    M.cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
    M.bake_cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
end

local function bake_mesh()
    print("Baking Mesh (One-time)...")
    local cb = M.bake_cb
    vk.vkResetCommandBuffer(cb, 0)
    local begin_info = ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT })
    vk.vkBeginCommandBuffer(cb, begin_info)

    local pc_field = ffi.new("FieldPC", { 
        bounds_min = {-1.0, -0.6, -1.0}, bone_count = #skeleton_order,
        bounds_max = {1.0, 1.4, 1.0}, sdf_count = sdf_count,
        grid_size = {GRID_SIZE[1], GRID_SIZE[2], GRID_SIZE[3]},
        bones_idx = 0, sdfs_idx = 1, grid_idx = 2, vertices_idx = 3, indices_idx = 4, counter_idx = 5, cell_idx = 6, vertex_counter_idx = 7
    })

    -- Reset Counter
    vk.vkCmdFillBuffer(cb, counter_buffer.handle, 0, counter_buffer.size, 0)
    
    local barrier = ffi.new("VkMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
        srcAccessMask = bit.bor(vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT),
        dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT)
    }})
    vk.vkCmdPipelineBarrier(cb, bit.bor(vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- Pass 0: Reset (Initialization)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, reset_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, field_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, field_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("FieldPC"), pc_field)
    vk.vkCmdDispatch(cb, 1, 1, 1)

    barrier[0].srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT
    barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- Field
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, field_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, field_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, field_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("FieldPC"), pc_field)
    vk.vkCmdDispatch(cb, GRID_SIZE[1]/8, GRID_SIZE[2]/8, GRID_SIZE[3]/8)

    barrier[0].srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT
    barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- VertexGen
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, vertex_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, field_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, field_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("FieldPC"), pc_field)
    vk.vkCmdDispatch(cb, GRID_SIZE[1]/8, GRID_SIZE[2]/8, GRID_SIZE[3]/8)

    barrier[0].srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT
    barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- IndexGen
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, index_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, field_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, field_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("FieldPC"), pc_field)
    vk.vkCmdDispatch(cb, GRID_SIZE[1]/8, GRID_SIZE[2]/8, GRID_SIZE[3]/8)

    vk.vkEndCommandBuffer(cb)
    local submit_info = ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}) })
    vk.vkQueueSubmit(queue, 1, submit_info, nil)
    vk.vkQueueWaitIdle(queue)
    print("Bake Complete.")
end

function M.update()
    local current_ticks = tonumber(sdl.SDL_GetTicks())
    local dt = (current_ticks - last_ticks) / 1000.0
    if last_ticks == 0 then dt = 0 end
    last_ticks = current_ticks
    current_time = current_time + dt

    -- FPS Counter
    frame_count = frame_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        local fps = frame_count / fps_timer
        sdl.SDL_SetWindowTitle(_G._SDL_WINDOW, string.format("Example 52: Neurosymbolic CSG | FPS: %.1f | Anim: %s", fps, animations[current_anim_idx]))
        frame_count = 0
        fps_timer = 0
    end

    if input.key_pressed(input.SCANCODE_N) then
        current_anim_idx = (current_anim_idx % #animations) + 1
        print("Switching to Animation: " .. animations[current_anim_idx])
    end

    if input.key_pressed(input.SCANCODE_K) then
        debug_mode = (debug_mode + 1) % 3
        local modes = {"OFF", "SINGLE_BONE_HEATMAP", "ALL_BONES_MIX"}
        print("Weight Debug Mode: " .. modes[debug_mode + 1])
    end

    if input.key_pressed(input.SCANCODE_L) then
        debug_bone = (debug_bone + 1) % #skeleton_order
        print(string.format("Visualizing Bone [%d]: %s", debug_bone, skeleton_order[debug_bone+1]))
    end

    -- Character Movement
    local move_speed = 2.0 * dt
    local forward = {math.sin(cam_rot[1]), 0, math.cos(cam_rot[1])}
    local right = {math.cos(cam_rot[1]), 0, -math.sin(cam_rot[1])}
    local move_dir = {0, 0, 0}
    local moved = false
    if input.key_down(input.SCANCODE_W) then 
        move_dir[1] = move_dir[1] - forward[1]; move_dir[3] = move_dir[3] - forward[3]
        moved = true
    end
    if input.key_down(input.SCANCODE_S) then 
        move_dir[1] = move_dir[1] + forward[1]; move_dir[3] = move_dir[3] + forward[3]
        moved = true
    end
    if input.key_down(input.SCANCODE_A) then 
        move_dir[1] = move_dir[1] - right[1]; move_dir[3] = move_dir[3] - right[3]
        moved = true
    end
    if input.key_down(input.SCANCODE_D) then 
        move_dir[1] = move_dir[1] + right[1]; move_dir[3] = move_dir[3] + right[3]
        moved = true
    end
    
    if moved then
        local mag = math.sqrt(move_dir[1]^2 + move_dir[3]^2)
        if mag > 0 then
            move_dir[1], move_dir[3] = move_dir[1]/mag, move_dir[3]/mag
            char_pos[1] = char_pos[1] + move_dir[1] * move_speed
            char_pos[3] = char_pos[3] + move_dir[3] * move_speed
            char_yaw = math.atan2(move_dir[1], move_dir[3])
            
            if animations[current_anim_idx] == "idle" or animations[current_anim_idx] == "rest" then
                current_anim_idx = 2 -- walk
            end
        end
    elseif animations[current_anim_idx] == "walk" or animations[current_anim_idx] == "run" then
        current_anim_idx = 3 -- idle
    end
    cam_target[1], cam_target[3] = char_pos[1], char_pos[3]

    -- Orbit Controls
	local dx, dy = input.mouse_delta()
	if input.mouse_down(1) then -- Left Click Drag
	    cam_rot[1] = cam_rot[1] - dx * 0.01
	    cam_rot[2] = math.max(-1.5, math.min(1.5, cam_rot[2] + dy * 0.01))
	end
    local wheel = _G._MOUSE_WHEEL or 0
    if wheel ~= 0 then 
        cam_dist = math.max(1.0, cam_dist - wheel * cam_dist * 0.1)
        _G._MOUSE_WHEEL = 0 
    end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame])
    if img_idx == nil then return end 
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}))

    -- INITIAL BAKE
    if not mesh_baked or input.key_pressed(input.SCANCODE_SPACE) then
        generator.apply_pose(skeleton_tree, 0, "rest")
        generator.update_matrices(skeleton_tree, skeleton_order, bone_data, bone_map)
        for i=0, #skeleton_order-1 do
            for j=0,15 do
                bone_data[i].bind_matrix[j] = bone_data[i].world_matrix[j]
                bone_data[i].inv_bind_matrix[j] = bone_data[i].inv_world_matrix[j]
            end
        end
        bake_mesh()
        mesh_baked = true
    end

    -- UPDATE BONES FOR RENDERING (Live Animation)
    generator.apply_pose(skeleton_tree, current_time, animations[current_anim_idx])
    
    -- Apply World Position and Rotation to Root
    skeleton_tree.root.offset[1] = skeleton_tree.root.base_offset[1] + char_pos[1]
    skeleton_tree.root.offset[3] = skeleton_tree.root.base_offset[3] + char_pos[3]
    skeleton_tree.root.rot[2] = char_yaw

    generator.update_matrices(skeleton_tree, skeleton_order, bone_data, bone_map)

    local cb = M.cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local cx = cam_target[1] + cam_dist * math.sin(cam_rot[1]) * math.cos(cam_rot[2])
    local cy = cam_target[2] + cam_dist * math.sin(cam_rot[2])
    local cz = cam_target[3] + cam_dist * math.cos(cam_rot[1]) * math.cos(cam_rot[2])
    local view = mc.mat4_look_at({cx, cy, cz}, cam_target, {0, 1, 0})
    local proj = mc.mat4_perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 100.0)
    
    local pc_render = ffi.new("RenderPC")
    for i=0,15 do pc_render.projection[i], pc_render.view[i] = proj.m[i], view.m[i] end
    pc_render.cam_pos[0], pc_render.cam_pos[1], pc_render.cam_pos[2] = cx, cy, cz
    pc_render.bone_count = #skeleton_order
    pc_render.bones_idx = 0
    pc_render.outline_thickness = 0.008
    pc_render.outline_mode = 1 -- Pass 1: Outline
    pc_render.debug_mode = debug_mode
    pc_render.debug_bone = debug_bone

    local cb = M.cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    -- TRANSITION TO COLOR ATTACHMENT
    local image_barrier = ffi.new("VkImageMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        image = ffi.cast("VkImage", sw.images[img_idx]),
        subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, image_barrier)

    -- TRANSITION DEPTH
    local depth_barrier = ffi.new("VkImageMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        dstAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        image = depth_img.handle,
        subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, 0, 0, nil, 0, nil, 1, depth_barrier)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
    color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color = {float32 = {0.05, 0.05, 0.07, 1.0}}

    local depth_attach = ffi.new("VkRenderingAttachmentInfo")
    depth_attach.sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    depth_attach.imageView = depth_img.view
    depth_attach.imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach.loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    depth_attach.storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    depth_attach.clearValue.depthStencil = {depth = 1.0}

    local rendering_info = ffi.new("VkRenderingInfo", {
        sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
        renderArea = { extent = sw.extent },
        layerCount = 1,
        colorAttachmentCount = 1,
        pColorAttachments = color_attach,
        pDepthAttachment = depth_attach
    })

    vk.vkCmdBeginRendering(cb, rendering_info)
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset={x=0,y=0}, extent=sw.extent }))
    
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {vertex_buffer.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, index_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT32)

    -- PASS 1: Character
    pc_render.outline_mode = 0
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
    vk.vkCmdPushConstants(cb, graphics_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), pc_render)
    vk.vkCmdDrawIndexedIndirect(cb, counter_buffer.handle, 0, 1, 20)

    -- PASS 2: Outline
    pc_render.outline_mode = 1
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, outline_pipe)
    vk.vkCmdPushConstants(cb, graphics_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), pc_render)
    vk.vkCmdDrawIndexedIndirect(cb, counter_buffer.handle, 0, 1, 20)

    -- PASS 3: Floor
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, floor_pipe)
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {floor_buffer.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, floor_buffer.handle, 48, vk.VK_INDEX_TYPE_UINT32)
    -- Just reuse the first part of pc_render (proj, view, cam_pos)
    vk.vkCmdPushConstants(cb, floor_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 4*16 + 4*16 + 4*3, pc_render)
    vk.vkCmdDrawIndexed(cb, 6, 1, 0, 0, 0)

    vk.vkCmdEndRendering(cb)

    -- TRANSITION TO PRESENT
    image_barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    image_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    image_barrier[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    image_barrier[0].dstAccessMask = 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, image_barrier)

    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sems[current_frame]}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sems[current_frame]}) }), frame_fences[current_frame])
    sw:present(queue, img_idx, render_finished_sems[current_frame])

    if current_frame == 0 then
        local ptr = ffi.cast("uint32_t*", counter_buffer.allocation.ptr)
        print(string.format("Mesh Stats | Indices: %d | Vertices: %d | Cmd[1]: %d | Cmd[2]: %d", ptr[0], ptr[6], ptr[1], ptr[2]))
    end

    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
