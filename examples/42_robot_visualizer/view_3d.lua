local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local render_graph = require("vulkan.graph")
local mc = require("mc")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")
local primitives = require("examples.42_robot_visualizer.primitives")
local robot = require("mc.robot")
local imgui = require("imgui")
local ui_context = require("examples.42_robot_visualizer.ui.context")

local CLUSTER_X, CLUSTER_Y, CLUSTER_Z = 16, 9, 24
local MAX_LIGHTS = 1024
local MAX_LIGHT_INDICES = 100 * CLUSTER_X * CLUSTER_Y * CLUSTER_Z

local M = {
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = ffi.new("float[3]", {0, 0, 5}), ortho = false, follow = true },
    points_count = 10000000,
    w = 1920, h = 1080,
    final_color_idx = 103,
    is_hovered = false,
    is_dragging = false,
    poses = {},
    p_point_size = ffi.new("float[1]", 3.0),
    p_lidar_transform = ffi.new("bool[1]", true),
    axis_map = {1, 2, 3, 0}, -- Default mapping (X, Y, Z, Padding)
    view_lights = ffi.new("Light[1024]"),
    
    graph = nil,
    res = {},
    pipes = {},
    gpu_objs = {},
    
    static = {
        pc_r = ffi.new("RenderPC"),
        pc_build = ffi.new("struct { float inv_proj[16]; float screen_size[2]; float z_near, z_far; uint32_t cluster_x, cluster_y, cluster_z; }"),
        pc_cull = ffi.new("struct { float view[16]; uint32_t total_lights; }"),
        pc_plot = ffi.new("PlotPC"),
        viewport = ffi.new("VkViewport", {0, 0, 1920, 1080, 0, 1}),
        scissor = ffi.new("VkRect2D", {offset={0,0}, extent={1920,1080}}),
        cam_pos = ffi.new("mc_vec3"),
        cam_target = ffi.new("mc_vec3"),
        m_proj = ffi.new("mc_mat4"),
        m_view = ffi.new("mc_mat4"),
        m_mvp = ffi.new("mc_mat4"),
        m_inv_proj = ffi.new("mc_mat4"),
    }
}

function M.init(device, bindless_set, sw)
    local static = M.static
    M.graph = render_graph.new(device)
    local bl_layout = mc.gpu.get_bindless_layout()
    
    -- GPU Resources for Forward+
    M.gpu_objs.cluster_aabb = mc.buffer(ffi.sizeof("ClusterAABB") * CLUSTER_X * CLUSTER_Y * CLUSTER_Z, "storage")
    M.gpu_objs.lights = mc.buffer(ffi.sizeof("Light") * MAX_LIGHTS, "storage", nil, true)
    M.gpu_objs.cluster_items = mc.buffer(ffi.sizeof("ClusterItem") * CLUSTER_X * CLUSTER_Y * CLUSTER_Z, "storage")
    M.gpu_objs.light_indices = mc.buffer(4 * MAX_LIGHT_INDICES, "storage")
    M.gpu_objs.global_counter = mc.buffer(4, "storage")
    
    M.final_color = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled")
    M.depth_image = mc.image(M.w, M.h, vk.VK_FORMAT_D32_SFLOAT, "depth")
    
    local sampler = mc.gpu.sampler()
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.final_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, M.final_color_idx)

    -- Descriptor Sets for Culling and Forward shading
    local cull_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
    })
    M.pipes.cull_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }}), {cull_layout})[1]
    descriptors.update_buffer_set(device, M.pipes.cull_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.cluster_aabb.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.cull_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.lights.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.cull_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.cluster_items.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.cull_set, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.light_indices.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.cull_set, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.global_counter.handle, 0, vk.VK_WHOLE_SIZE, 0)

    local forward_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
    })
    M.pipes.forward_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }}), {forward_layout})[1]
    descriptors.update_buffer_set(device, M.pipes.forward_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.lights.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.forward_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.cluster_items.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, M.pipes.forward_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.gpu_objs.light_indices.handle, 0, vk.VK_WHOLE_SIZE, 0)

    -- Register graph resources
    M.res.cluster_aabb = M.graph:register_resource("ClusterAABB", render_graph.TYPE_BUFFER, M.gpu_objs.cluster_aabb.handle)
    M.res.lights = M.graph:register_resource("Lights", render_graph.TYPE_BUFFER, M.gpu_objs.lights.handle)
    M.res.cluster_items = M.graph:register_resource("ClusterItems", render_graph.TYPE_BUFFER, M.gpu_objs.cluster_items.handle)
    M.res.light_indices = M.graph:register_resource("LightIndices", render_graph.TYPE_BUFFER, M.gpu_objs.light_indices.handle)
    M.res.global_counter = M.graph:register_resource("GlobalCounter", render_graph.TYPE_BUFFER, M.gpu_objs.global_counter.handle)
    M.res.final_color = M.graph:register_resource("FinalColor", render_graph.TYPE_IMAGE, M.final_color.handle)
    M.res.depth = M.graph:register_resource("DepthBuffer", render_graph.TYPE_IMAGE, M.depth_image.handle)

    -- Pipelines
    local pc_all = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT)
    M.pipes.layout_build = pipeline.create_layout(device, {cull_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_all, offset = 0, size = 92 }}))
    M.pipes.build = pipeline.create_compute_pipeline(device, M.pipes.layout_build, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_cluster_build.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    M.pipes.layout_cull = pipeline.create_layout(device, {cull_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_all, offset = 0, size = 72 }}))
    M.pipes.cull = pipeline.create_compute_pipeline(device, M.pipes.layout_cull, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_light_cull.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    M.pipes.layout_fp = pipeline.create_layout(device, {bl_layout, forward_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_all, offset = 0, size = ffi.sizeof("RenderPC") }}))
    
    M.pipes.fp_point = pipeline.create_graphics_pipeline(device, M.pipes.layout_fp, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM }, depth_test = true, depth_write = false })

    M.pipes.fp_line = pipeline.create_graphics_pipeline(device, M.pipes.layout_fp, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_line.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), 
        shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/fp_line.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM }, depth_test = true, depth_write = true })

    local v_grid = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/grid.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_grid = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/grid.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipes.fp_grid = pipeline.create_graphics_pipeline(device, M.pipes.layout_fp, v_grid, f_grid, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM }, depth_test = true, depth_write = false })

    M.pipes.layout_plot = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = ffi.sizeof("PlotPC") }}))
    M.pipes.plot = pipeline.create_graphics_pipeline(device, M.pipes.layout_plot, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/plot.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/plot.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, alpha_blend = true, depth_test = false, depth_write = false, color_formats = { vk.VK_FORMAT_B8G8R8A8_UNORM }
    })

    M.point_buffers = { mc.buffer(M.points_count * 16, "storage", nil, false), mc.buffer(M.points_count * 16, "storage", nil, false) }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[1].handle, 0, M.point_buffers[1].size, 11)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[2].handle, 0, M.point_buffers[2].size, 13)

    M.robot_buffers = { mc.buffer(128 * ffi.sizeof("LineVertex"), "vertex", nil, true), mc.buffer(128 * ffi.sizeof("LineVertex"), "vertex", nil, true) }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.robot_buffers[1].handle, 0, M.robot_buffers[1].size, 14)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.robot_buffers[2].handle, 0, M.robot_buffers[2].size, 15)

    M.plot_images = {}
    M.res.plot_imgs = {}
    for i=1, 8 do
        local img = mc.image(2048, 1024, vk.VK_FORMAT_B8G8R8A8_UNORM, "color_attachment_sampled")
        M.plot_images[i] = img
        descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 104 + i)
        M.res.plot_imgs[i] = M.graph:register_resource("PlotImg_" .. i, render_graph.TYPE_IMAGE, img.handle)
    end

    -- Initial random lights for testing
    M.plot_queue = {}
    M.lights_data = ffi.new("Light[?]", MAX_LIGHTS)
    for i = 0, MAX_LIGHTS - 1 do
        M.lights_data[i].pos_radius[0] = (math.random() - 0.5) * 100.0
        M.lights_data[i].pos_radius[1] = (math.random() - 0.5) * 100.0
        M.lights_data[i].pos_radius[2] = math.random() * 10.0
        M.lights_data[i].pos_radius[3] = 5.0 + math.random() * 10.0
        M.lights_data[i].color[0], M.lights_data[i].color[1], M.lights_data[i].color[2] = math.random(), math.random(), math.random()
        M.lights_data[i].color[3] = 2.0
    end
end

function M.reset_frame() 
    if M.graph then M.graph:reset() end
    if M.plot_queue then
        for i=1, #M.plot_queue do M.plot_queue[i] = nil end
    end
end
function M.resize(device, bindless_set)
    M.final_color = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled")
    M.depth_image = mc.image(M.w, M.h, vk.VK_FORMAT_D32_SFLOAT, "depth")
    local sampler = mc.gpu.sampler()
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.final_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, M.final_color_idx)
    M.res.final_color.handle = M.final_color.handle
    M.res.depth.handle = M.depth_image.handle
    M.static.viewport.width, M.static.viewport.height = M.w, M.h
    M.static.scissor.extent.width, M.static.scissor.extent.height = M.w, M.h
end

function M.register_panels()
    panels.register("view3d", "3D Scene", function(gui, node_id, params)
        M.current_params = params
        local s = gui.igGetContentRegionAvail()
        local pos = gui.igGetCursorScreenPos()
        if math.abs(s.x - M.w) > 1 or math.abs(s.y - M.h) > 1 then
            M.w, M.h = math.max(s.x, 1), math.max(s.y, 1)
            M.resize(vulkan.get_device(), mc.gpu.get_bindless_set())
        end
        gui.igInvisibleButton("##scene_hit", s, 0)
        M.is_hovered = gui.igIsItemHovered(0)
        local w_pos, w_size = gui.igGetWindowPos(), gui.igGetWindowSize()
        ui_context.push({ x = pos.x, y = pos.y, w = s.x, h = s.y, r = 1, g = 1, b = 1, a = 1, clip_min_x = w_pos.x, clip_min_y = w_pos.y, clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y, type = 2, extra = M.final_color_idx })
    end)
end

function M.enqueue_plot(data)
    table.insert(M.plot_queue, data)
end

function M.update_robot_buffer(frame_idx, params)
    local rv = ffi.cast("LineVertex*", M.robot_buffers[frame_idx + 1].allocation.ptr)
    if params and params.objects then
        for _, obj in ipairs(params.objects) do
            if obj.type == "robot" then
                -- Sync with live playback pose
                local live = playback.robot_pose
                local last = M.poses[obj.name or "default"] or { x = 0, y = 0, z = 0, yaw = 0, qx = 0, qy = 0, qz = 0, qw = 1 }
                last.x, last.y, last.z, last.yaw = live.x, live.y, live.z, live.yaw
                last.qx, last.qy, last.qz, last.qw = live.qx, live.qy, live.qz, live.qw
                M.poses[obj.name or "default"] = last
                
                if obj.follow then M.current_pose = last end
                local q = {last.qx, last.qy, last.qz, last.qw}
                local offset = 0
                offset = offset + primitives.write_box(rv, offset, last.x, last.y, last.z, q, 5.0, 5.0, 2.5, 1, 1, 0, 1)
                offset = offset + primitives.write_axes(rv, offset, last.x, last.y, last.z, q, 10.0)
                M.active_robot_line_count = offset
            end
        end
    end
end

function M.render_deferred(cb_handle, point_buf_idx, frame_idx, point_count)
    local static = M.static
    local params = M.current_params or {}
    
    -- 0. Render Plots (Aperture pre-pass)
    if #M.plot_queue > 0 then
        local viewport = ffi.new("VkViewport", {0, 0, 2048, 1024, 0, 1})
        local scissor = ffi.new("VkRect2D", {{0,0}, {2048, 1024}})
        local sets = ffi.new("VkDescriptorSet[1]", {mc.gpu.get_bindless_set()})

        for _, plot_item in ipairs(M.plot_queue) do
            local ch = playback.channels_by_id[plot_item.ch_id]
            local pool_idx = (plot_item.tex_idx % 8) + 1
            local img = M.plot_images[pool_idx]
            
            if ch and ch.gtb_offset and img then
                M.graph:add_pass("Plot_" .. plot_item.ch_id, function(cmd)
                    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]", {{ 
                        sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, 
                        imageView = img.view, 
                        imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 
                        loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, 
                        clearValue = {color={float32={0,0,0,0}}} 
                    }})
                    vk.vkCmdBeginRendering(cmd, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = {width=2048, height=1024} }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
                    vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.plot)
                    vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.layout_plot, 0, 1, sets, 0, nil)
                    vk.vkCmdSetViewport(cmd, 0, 1, ffi.new("VkViewport[1]", {viewport}))
                    vk.vkCmdSetScissor(cmd, 0, 1, ffi.new("VkRect2D[1]", {scissor}))

                    static.pc_plot.gtb_idx = 50
                    static.pc_plot.slot_offset = ch.gtb_offset
                    static.pc_plot.msg_size = playback.MSG_SIZE_MAX
                    static.pc_plot.head_idx = playback.get_gtb_slot_index(plot_item.ch_id)
                    static.pc_plot.field_offset = plot_item.field_offset
                    static.pc_plot.history_count = playback.HISTORY_MAX
                    static.pc_plot.is_double = plot_item.is_double
                    static.pc_plot.range_min = plot_item.range_min
                    static.pc_plot.range_max = plot_item.range_max
                    
                    vk.vkCmdPushConstants(cmd, M.pipes.layout_plot, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("PlotPC"), static.pc_plot)
                    vk.vkCmdDraw(cmd, playback.HISTORY_MAX, 1, 0, 0)
                    vk.vkCmdEndRendering(cmd)
                end):using(M.res.plot_imgs[pool_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
            end
        end
    end

    -- 1. Update Camera and PC
    if M.current_pose then M.cam.target[0], M.cam.target[1], M.cam.target[2] = M.current_pose.x, M.current_pose.y, M.current_pose.z + 2.0 end
    local rx, ry = mc.rad(M.cam.orbit_x), mc.rad(M.cam.orbit_y)
    static.cam_target.x, static.cam_target.y, static.cam_target.z = M.cam.target[0], M.cam.target[1], M.cam.target[2]
    static.cam_pos.x = static.cam_target.x + M.cam.dist * math.cos(ry) * math.cos(rx)
    static.cam_pos.y = static.cam_target.y + M.cam.dist * math.cos(ry) * math.sin(rx)
    static.cam_pos.z = static.cam_target.z + M.cam.dist * math.sin(ry)
    
    local mat_proj = mc.mat4_perspective(mc.rad(45), M.w/M.h, 0.1, 10000.0, static.m_proj)
    local mat_view = mc.mat4_look_at({static.cam_pos.x, static.cam_pos.y, static.cam_pos.z}, {static.cam_target.x, static.cam_target.y, static.cam_target.z}, {0,0,1}, static.m_view)
    local mat_inv_proj = mc.mat4_inverse(mat_proj, static.m_inv_proj)
    local mvp = mc.mat4_multiply(mat_proj, mat_view, static.m_mvp)
    
    ffi.copy(static.pc_r.view_proj, mvp.m, 64)
    ffi.copy(static.pc_r.view, mat_view.m, 64)
    static.pc_r.vw, static.pc_r.vh = M.w, M.h
    static.pc_r.z_near, static.pc_r.z_far = 0.1, 10000.0
    static.pc_r.cluster_x, static.pc_r.cluster_y, static.pc_r.cluster_z = CLUSTER_X, CLUSTER_Y, CLUSTER_Z
    static.pc_r.buf_idx = point_buf_idx or 11
    
    local lidar_obj = nil
    if params.objects then for _, obj in ipairs(params.objects) do if obj.type == "lidar" then lidar_obj = obj; break end end end
    if lidar_obj and not M.point_size_initialized then 
        M.p_point_size[0] = lidar_obj.point_size or 50.0 
        M.point_size_initialized = true
    end
    static.pc_r.point_size = M.p_point_size[0]
    for i=0, 2 do static.pc_r.axis_map[i] = M.axis_map[i+1] end
    
    local p_off = {0,0,0,0}
    local q = {0,0,0,1}
    if lidar_obj and lidar_obj.attach_to and M.poses[lidar_obj.attach_to] then
        local p = M.poses[lidar_obj.attach_to]; p_off = {p.x, p.y, p.z, p.yaw}
        q = {p.qx or 0, p.qy or 0, p.qz or 0, p.qw or 1}
    end
    
    if M.p_lidar_transform[0] then
        -- Calculate 4x4 Matrix from Translation + Quaternion
        local x, y, z, w = q[1], q[2], q[3], q[4]
        local x2, y2, z2 = x + x, y + y, z + z
        local xx, xy, xz = x * x2, x * y2, x * z2
        local yy, yz, zz = y * y2, y * z2, z * z2
        local wx, wy, wz = w * x2, w * y2, w * z2

        static.pc_r.pose_matrix[0],  static.pc_r.pose_matrix[1],  static.pc_r.pose_matrix[2],  static.pc_r.pose_matrix[3]  = 1.0 - (yy + zz), xy + wz, xz - wy, 0
        static.pc_r.pose_matrix[4],  static.pc_r.pose_matrix[5],  static.pc_r.pose_matrix[6],  static.pc_r.pose_matrix[7]  = xy - wz, 1.0 - (xx + zz), yz + wx, 0
        static.pc_r.pose_matrix[8],  static.pc_r.pose_matrix[9],  static.pc_r.pose_matrix[10], static.pc_r.pose_matrix[11] = xz + wy, yz - wx, 1.0 - (xx + yy), 0
        static.pc_r.pose_matrix[12], static.pc_r.pose_matrix[13], static.pc_r.pose_matrix[14], static.pc_r.pose_matrix[15] = p_off[1], p_off[2], p_off[3], 1.0
    else
        for i=0, 15 do static.pc_r.pose_matrix[i] = 0 end
        static.pc_r.pose_matrix[0], static.pc_r.pose_matrix[5], static.pc_r.pose_matrix[10], static.pc_r.pose_matrix[15] = 1, 1, 1, 1
    end

    -- 2. Update Lights to View Space
    local view_lights = M.view_lights
    local vm = mat_view.m
    for i = 0, MAX_LIGHTS - 1 do
        local l = M.lights_data[i]
        local lx, ly, lz = l.pos_radius[0], l.pos_radius[1], l.pos_radius[2]
        
        -- Manual View Transform (No table allocations)
        local vx = vm[0] * lx + vm[4] * ly + vm[8]  * lz + vm[12]
        local vy = vm[1] * lx + vm[5] * ly + vm[9]  * lz + vm[13]
        local vz = vm[2] * lx + vm[6] * ly + vm[10] * lz + vm[14]
        
        view_lights[i].pos_radius[0], view_lights[i].pos_radius[1], view_lights[i].pos_radius[2] = vx, vy, vz
        view_lights[i].pos_radius[3] = l.pos_radius[3]
        ffi.copy(view_lights[i].color, l.color, 16)
    end
    M.gpu_objs.lights:upload(view_lights)

    -- 3. Render Graph Execution
    
    -- PASS: Build Clusters
    M.graph:add_pass("BuildClusters", function(cmd)
        ffi.copy(static.pc_build.inv_proj, mat_inv_proj.m, 64)
        static.pc_build.screen_size[0], static.pc_build.screen_size[1] = M.w, M.h
        static.pc_build.z_near, static.pc_build.z_far = static.pc_r.z_near, static.pc_r.z_far
        static.pc_build.cluster_x, static.pc_build.cluster_y, static.pc_build.cluster_z = CLUSTER_X, CLUSTER_Y, CLUSTER_Z
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.pipes.build)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.pipes.layout_build, 0, 1, ffi.new("VkDescriptorSet[1]", {M.pipes.cull_set}), 0, nil)
        vk.vkCmdPushConstants(cmd, M.pipes.layout_build, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 92, static.pc_build)
        vk.vkCmdDispatch(cmd, CLUSTER_X, CLUSTER_Y, CLUSTER_Z)
    end):using(M.res.cluster_aabb, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    -- PASS: Light Cull
    M.graph:add_pass("LightCull", function(cmd)
        vk.vkCmdFillBuffer(cmd, ffi.cast("VkBuffer", M.gpu_objs.global_counter.handle), 0, 4, 0)
        local bar = ffi.new("VkBufferMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED, dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED, buffer = ffi.cast("VkBuffer", M.gpu_objs.global_counter.handle), offset = 0, size = 4 }})
        vk.vkCmdPipelineBarrier(cmd, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, bar, 0, nil)
        
        static.pc_cull.view = mat_view.m
        static.pc_cull.total_lights = MAX_LIGHTS
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.pipes.cull)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.pipes.layout_cull, 0, 1, ffi.new("VkDescriptorSet[1]", {M.pipes.cull_set}), 0, nil)
        vk.vkCmdPushConstants(cmd, M.pipes.layout_cull, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 72, static.pc_cull)
        vk.vkCmdDispatch(cmd, CLUSTER_X, CLUSTER_Y, CLUSTER_Z)
    end):using(M.res.cluster_aabb, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(M.res.lights, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(M.res.cluster_items, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(M.res.light_indices, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(M.res.global_counter, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)

    -- PASS: Forward Render (Aperture)
    M.graph:add_pass("AperturePass", function(cmd)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]", {{ sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageView = M.final_color.view, imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, clearValue = {color={float32={0.01, 0.01, 0.02, 1}}} }})
        local depth_attach = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageView = M.depth_image.view, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, clearValue = {depthStencil = {depth=1.0}} })
        vk.vkCmdBeginRendering(cmd, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = {width=M.w, height=M.h} }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach, pDepthAttachment = depth_attach }))
        
        vk.vkCmdSetViewport(cmd, 0, 1, ffi.new("VkViewport", {0, 0, M.w, M.h, 0, 1}))
        vk.vkCmdSetScissor(cmd, 0, 1, ffi.new("VkRect2D", {{0,0}, {M.w, M.h}}))
        
        local sets = ffi.new("VkDescriptorSet[2]", {mc.gpu.get_bindless_set(), M.pipes.forward_set})
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.layout_fp, 0, 2, sets, 0, nil)

        -- Grid
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.fp_grid)
        local grid_pc = ffi.new("RenderPC", static.pc_r)
        grid_pc.pose_matrix[12], grid_pc.pose_matrix[13] = M.cam.target[0], M.cam.target[1]
        grid_pc.point_size = 1.0
        vk.vkCmdPushConstants(cmd, M.pipes.layout_fp, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), grid_pc)
        vk.vkCmdDraw(cmd, 4, 1, 0, 0)

        -- Robot
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.fp_line)
        local robot_pc = ffi.new("RenderPC", static.pc_r)
        robot_pc.buf_idx = (frame_idx == 0) and 14 or 15
        robot_pc.point_size = 2.0
        vk.vkCmdPushConstants(cmd, M.pipes.layout_fp, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), robot_pc)
        vk.vkCmdDraw(cmd, (M.active_robot_line_count or 0) / 2 * 6, 1, 0, 0)

        -- Lidar Points
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipes.fp_point)
        vk.vkCmdPushConstants(cmd, M.pipes.layout_fp, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("RenderPC"), static.pc_r)
        if (point_count or 0) > 0 then vk.vkCmdDraw(cmd, 4, point_count, 0, 0) end
        
        vk.vkCmdEndRendering(cmd)
    end):using(M.res.final_color, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
       :using(M.res.depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL)
       :using(M.res.cluster_items, vk.VK_ACCESS_SHADER_READ_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT))
       :using(M.res.light_indices, vk.VK_ACCESS_SHADER_READ_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT))
       :using(M.res.lights, vk.VK_ACCESS_SHADER_READ_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT))

    M.graph:execute(cb_handle)
end

if jit then jit.off(M.render_deferred) end
return M
