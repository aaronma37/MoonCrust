local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local mc = require("mc")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")
local primitives = require("examples.42_robot_visualizer.primitives")
local robot = require("mc.robot")
local imgui = require("imgui")
local ui_context = require("examples.42_robot_visualizer.ui.context")

local M = {
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = ffi.new("float[3]", {0, 0, 5}), ortho = false, follow = true },
    points_count = 10000000,
    pipe_layout = nil, pipe_render_g = nil, pipe_line_g = nil, pipe_grid_g = nil,
    pipe_layout_light = nil, pipe_light = nil,
    pipe_layout_blur = nil, pipe_blur = nil,
    pipe_layout_plot = nil, pipe_plot = nil,
    point_buffer = nil, line_buffer = nil, line_count = 0, robot_buffers = nil, robot_line_count = 128,
    w = 1920, h = 1080,
    g_color = nil, g_normal = nil, g_pos = nil, final_color = nil, blurred_color = nil, depth_image = nil,
    final_color_idx = 103,
    blurred_color_idx = 104,
    is_hovered = false,
    is_dragging = false,
    poses = {},
    
    -- STATIC DATA (Moved from local to M to avoid upvalue issues)
    static = {
        pc_r = ffi.new("RenderPC"),
        pc_l = ffi.new("struct { uint32_t color_idx, normal_idx, pos_idx; float dummy; float light_dir[4]; }"),
        pc_b = ffi.new("struct { uint32_t in_idx, out_idx; float inv_size[2]; }"),
        pc_plot = ffi.new("PlotPC"),
        viewport = ffi.new("VkViewport", {0, 0, 1920, 1080, 0, 1}),
        scissor = ffi.new("VkRect2D", {offset={0,0}, extent={1920,1080}}),
        v_buffs = ffi.new("VkBuffer[1]"),
        v_offs = ffi.new("VkDeviceSize[1]", {0}),
        sets = ffi.new("VkDescriptorSet[1]"),
        cam_pos = ffi.new("mc_vec3"),
        cam_target = ffi.new("mc_vec3"),
        depth_attach = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE }),
        color_attach_g = ffi.new("VkRenderingAttachmentInfo[3]"),
        color_attach_l = ffi.new("VkRenderingAttachmentInfo[1]"),
        color_attach_plot = ffi.new("VkRenderingAttachmentInfo[1]"),
        img_barrier_g = ffi.new("VkImageMemoryBarrier[4]"),
        img_barrier_l = ffi.new("VkImageMemoryBarrier[1]"),
        img_barrier_plot = ffi.new("VkImageMemoryBarrier[1]"),
        img_barrier_b = ffi.new("VkImageMemoryBarrier[1]"),
        render_info_g = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 3 }),
        render_info_l = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
        render_info_plot = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
        m_proj = ffi.new("mc_mat4"),
        m_view = ffi.new("mc_mat4"),
        m_mvp = ffi.new("mc_mat4"),
    }
}

function M.init(device, bindless_set, sw)
    local static = M.static
    local bl_layout = mc.gpu.get_bindless_layout()
    M.pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }}))
    
    local v_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_render_g = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_point, f_point, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R32G32B32A32_SFLOAT },
        depth_test = true, depth_write = true 
    })

    local v_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_line.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_line.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_line_g = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_line, f_line, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R32G32B32A32_SFLOAT },
        depth_test = true, depth_write = true,
    })

    local v_grid = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/grid.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_grid = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/grid.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_grid_g = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_grid, f_grid, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R32G32B32A32_SFLOAT },
        depth_test = true, depth_write = false 
    })

    M.pipe_layout_light = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = 32 }}))
    local v_light = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_light.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_light = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_light.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_light = pipeline.create_graphics_pipeline(device, M.pipe_layout_light, v_light, f_light, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM },
        depth_test = false, depth_write = false 
    })

    M.pipe_layout_blur = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 16 }}))
    M.pipe_blur = pipeline.create_compute_pipeline(device, M.pipe_layout_blur, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/blur.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    M.pipe_layout_plot = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = ffi.sizeof("PlotPC") }}))
    M.pipe_plot = pipeline.create_graphics_pipeline(device, M.pipe_layout_plot, shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/plot.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/plot.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, alpha_blend = true, depth_test = false, depth_write = false, color_formats = { vk.VK_FORMAT_B8G8R8A8_UNORM }
    })

    M.point_buffers = { mc.buffer(M.points_count * 16, "storage", nil, false), mc.buffer(M.points_count * 16, "storage", nil, false) }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[1].handle, 0, M.point_buffers[1].size, 11)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[2].handle, 0, M.point_buffers[2].size, 13)

    local sampler = mc.gpu.sampler()
    M.g_color, M.g_normal, M.g_pos = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled"), mc.image(M.w, M.h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "color_attachment_sampled"), mc.image(M.w, M.h, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "color_attachment_sampled")
    M.final_color, M.blurred_color = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled"), mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "storage_sampled")
    M.depth_image = mc.image(M.w, M.h, vk.VK_FORMAT_D32_SFLOAT, "depth")
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 100)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_normal.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 101)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_pos.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 102)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.final_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, M.final_color_idx)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.blurred_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, M.blurred_color_idx)
    descriptors.update_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, M.blurred_color.view, nil, vk.VK_IMAGE_LAYOUT_GENERAL, M.blurred_color_idx)

    M.plot_images = {}
    for i=1, 8 do
        local img = mc.image(2048, 1024, vk.VK_FORMAT_B8G8R8A8_UNORM, "color_attachment_sampled")
        M.plot_images[i] = img
        descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 104 + i)
    end

    static.depth_attach.imageView = M.depth_image.view
    static.depth_attach.clearValue.depthStencil.depth = 1.0
    for i=0,2 do static.color_attach_g[i].sType, static.color_attach_g[i].imageLayout, static.color_attach_g[i].loadOp, static.color_attach_g[i].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE end
    static.color_attach_g[0].imageView, static.color_attach_g[1].imageView, static.color_attach_g[2].imageView = M.g_color.view, M.g_normal.view, M.g_pos.view
    static.render_info_g.renderArea.extent, static.render_info_g.pColorAttachments, static.render_info_g.pDepthAttachment = {width=M.w, height=M.h}, static.color_attach_g, static.depth_attach
    static.color_attach_l[0].sType, static.color_attach_l[0].imageLayout, static.color_attach_l[0].loadOp, static.color_attach_l[0].storeOp, static.color_attach_l[0].imageView = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE, vk.VK_ATTACHMENT_STORE_OP_STORE, M.final_color.view
    static.render_info_l.renderArea.extent, static.render_info_l.pColorAttachments = {width=M.w, height=M.h}, static.color_attach_l
    static.color_attach_plot[0].sType, static.color_attach_plot[0].imageLayout, static.color_attach_plot[0].loadOp, static.color_attach_plot[0].storeOp, static.color_attach_plot[0].imageView = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, M.plot_images[1].view
    static.color_attach_plot[0].clearValue.color.float32[0], static.color_attach_plot[0].clearValue.color.float32[1], static.color_attach_plot[0].clearValue.color.float32[2], static.color_attach_plot[0].clearValue.color.float32[3] = 0, 0, 0, 0
    static.render_info_plot.renderArea.extent, static.render_info_plot.pColorAttachments = {width=2048, height=1024}, static.color_attach_plot
    for i=0,3 do static.img_barrier_g[i].sType, static.img_barrier_g[i].subresourceRange.levelCount, static.img_barrier_g[i].subresourceRange.layerCount = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, 1, 1 end
    static.img_barrier_g[0].image, static.img_barrier_g[0].subresourceRange.aspectMask = M.g_color.handle, vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[1].image, static.img_barrier_g[1].subresourceRange.aspectMask = M.g_normal.handle, vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[2].image, static.img_barrier_g[2].subresourceRange.aspectMask = M.g_pos.handle, vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[3].image, static.img_barrier_g[3].subresourceRange.aspectMask = M.depth_image.handle, vk.VK_IMAGE_ASPECT_DEPTH_BIT
    static.img_barrier_l[0].sType, static.img_barrier_l[0].image, static.img_barrier_l[0].subresourceRange.levelCount, static.img_barrier_l[0].subresourceRange.layerCount, static.img_barrier_l[0].subresourceRange.aspectMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, M.final_color.handle, 1, 1, vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_plot[0].sType, static.img_barrier_plot[0].image, static.img_barrier_plot[0].subresourceRange.levelCount, static.img_barrier_plot[0].subresourceRange.layerCount, static.img_barrier_plot[0].subresourceRange.aspectMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, M.plot_images[1].handle, 1, 1, vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_b[0].sType, static.img_barrier_b[0].image, static.img_barrier_b[0].subresourceRange.levelCount, static.img_barrier_b[0].subresourceRange.layerCount, static.img_barrier_b[0].subresourceRange.aspectMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, M.blurred_color.handle, 1, 1, vk.VK_IMAGE_ASPECT_COLOR_BIT

    M.robot_buffers = { mc.buffer(M.robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true), mc.buffer(M.robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true) }
    M.plot_queue = {}
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.robot_buffers[1].handle, 0, M.robot_buffers[1].size, 14)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.robot_buffers[2].handle, 0, M.robot_buffers[2].size, 15)
end

function M.reset_frame() end

function M.register_panels()
    panels.register("view3d", "3D Scene", function(gui, node_id, params)
        M.current_params = params
        local s = gui.igGetContentRegionAvail()
        local pos = gui.igGetCursorScreenPos()
        
        if math.abs(s.x - M.w) > 1 or math.abs(s.y - M.h) > 1 then
            M.w, M.h = math.max(s.x, 1), math.max(s.y, 1)
            M.resize(vulkan.get_device(), mc.gpu.get_bindless_set(), nil)
        end

        gui.igInvisibleButton("##scene_hit", s, 0)
        M.is_hovered = gui.igIsItemHovered(0)
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()

        ui_context.push({
            x = pos.x, y = pos.y, w = s.x, h = s.y,
            r = 1, g = 1, b = 1, a = 1,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 2, -- Aperture
            extra = M.final_color_idx
        })
    end)
end

function M.enqueue_plot(data)
    table.insert(M.plot_queue, {
        ch_id = data.ch_id,
        field_offset = data.field_offset,
        is_double = data.is_double,
        tex_idx = data.tex_idx,
        range_min = data.range_min,
        range_max = data.range_max,
        x = data.x, y = data.y, w = data.w, h = data.h
    })
end

function M.update_robot_buffer(frame_idx, params)
    local rv = ffi.cast("LineVertex*", M.robot_buffers[frame_idx + 1].allocation.ptr)
    if params and params.objects then
        for _, obj in ipairs(params.objects) do
            if obj.type == "robot" then
                local last = M.poses[obj.name or "default"] or { x = 0, y = 0, z = 0, yaw = 0 }
                local px, py, pz, yaw = last.x, last.y, last.z, last.yaw
                
                -- [GPU-NATIVE ARCHITECTURE PENDING]
                -- The Lua decoder has been killed. The CPU no longer wastes cycles 
                -- dynamically parsing Pose strings. A Compute Shader will be built 
                -- to read the GTB directly and resolve these kinematics.
                -- For now, the drone sits at its initial/last known position.
                
                M.poses[obj.name or "default"] = { x = px, y = py, z = pz, yaw = yaw }
                if obj.follow then M.current_pose = M.poses[obj.name or "default"] end
                local offset = 0
                offset = offset + primitives.write_box(rv, offset, px, py, pz, yaw, 5.0, 5.0, 2.5, 1, 1, 0, 1)
                offset = offset + primitives.write_axes(rv, offset, px, py, pz, yaw, 10.0)
                M.active_robot_line_count = offset
            end
        end
    end
end

function M.render_deferred(cb_handle, point_buf_idx, frame_idx, point_count)
    local static = M.static
    if #M.plot_queue > 0 then
        local sets = ffi.new("VkDescriptorSet[1]", {mc.gpu.get_bindless_set()})
        local viewport = ffi.new("VkViewport", {0, 0, 2048, 1024, 0, 1})
        local scissor = ffi.new("VkRect2D", {{0,0}, {2048, 1024}})

        for _, plot_item in ipairs(M.plot_queue) do
            local ch = nil
            if playback.channels then
                for _, c in ipairs(playback.channels) do if c.id == plot_item.ch_id then ch = c; break end end
            end
            
            -- Find the texture in the pool (tex_idx is 1-based index into M.plot_images)
            local pool_idx = (plot_item.tex_idx % 8) + 1
            local img = M.plot_images[pool_idx]
            
            if ch and ch.gtb_offset and img then
                -- Transition this specific texture to COLOR_ATTACHMENT
                static.img_barrier_plot[0].image = img.handle
                static.img_barrier_plot[0].oldLayout, static.img_barrier_plot[0].newLayout, static.img_barrier_plot[0].srcAccessMask, static.img_barrier_plot[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
                vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_plot)
                
                static.color_attach_plot[0].imageView = img.view
                vk.vkCmdBeginRendering(cb_handle, static.render_info_plot)
                
                vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_plot)
                vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_layout_plot, 0, 1, sets, 0, nil)
                vk.vkCmdSetViewport(cb_handle, 0, 1, ffi.new("VkViewport[1]", {viewport}))
                vk.vkCmdSetScissor(cb_handle, 0, 1, ffi.new("VkRect2D[1]", {scissor}))

                static.pc_plot.gtb_idx = 50
                static.pc_plot.slot_offset = ch.gtb_offset
                static.pc_plot.msg_size = playback.MSG_SIZE_MAX
                static.pc_plot.head_idx = playback.get_gtb_slot_index(plot_item.ch_id)
                static.pc_plot.field_offset = plot_item.field_offset
                static.pc_plot.history_count = playback.HISTORY_MAX
                static.pc_plot.is_double = plot_item.is_double
                static.pc_plot.range_min = plot_item.range_min
                static.pc_plot.range_max = plot_item.range_max
                
                vk.vkCmdPushConstants(cb_handle, M.pipe_layout_plot, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("PlotPC"), static.pc_plot)
                vk.vkCmdDraw(cb_handle, playback.HISTORY_MAX, 1, 0, 0)
                
                vk.vkCmdEndRendering(cb_handle)
                
                -- Transition back to SHADER_READ_ONLY
                static.img_barrier_plot[0].oldLayout, static.img_barrier_plot[0].newLayout, static.img_barrier_plot[0].srcAccessMask, static.img_barrier_plot[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT
                vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_plot)
            end
        end
        M.plot_queue = {}
    end

    local params = M.current_params or {}
    if M.current_pose then
        M.cam.target[0], M.cam.target[1], M.cam.target[2] = M.current_pose.x, M.current_pose.y, M.current_pose.z + 2.0
    end
    local rx, ry = mc.rad(M.cam.orbit_x), mc.rad(M.cam.orbit_y)
    static.cam_target.x, static.cam_target.y, static.cam_target.z = M.cam.target[0], M.cam.target[1], M.cam.target[2]
    static.cam_pos.x = static.cam_target.x + M.cam.dist * math.cos(ry) * math.cos(rx)
    static.cam_pos.y = static.cam_target.y + M.cam.dist * math.cos(ry) * math.sin(rx)
    static.cam_pos.z = static.cam_target.z + M.cam.dist * math.sin(ry)
    local mat_proj = mc.mat4_perspective(mc.rad(45), M.w/M.h, 0.1, 10000.0, static.m_proj)
    local mat_view = mc.mat4_look_at({static.cam_pos.x, static.cam_pos.y, static.cam_pos.z}, {static.cam_target.x, static.cam_target.y, static.cam_target.z}, {0,0,1}, static.m_view)
    local mvp = mc.mat4_multiply(mat_proj, mat_view, static.m_mvp)
    for i=0,15 do static.pc_r.view_proj[i] = mvp.m[i] end
    local vw, vh = math.max(M.w or 1280, 1), math.max(M.h or 720, 1)
    static.pc_r.buf_idx, static.pc_r.point_size, static.pc_r.vw, static.pc_r.vh = point_buf_idx or 11, 100.0, vw, vh
    local lidar_obj = nil
    if params.objects then for _, obj in ipairs(params.objects) do if obj.type == "lidar" then lidar_obj = obj; break end end end
    if lidar_obj then static.pc_r.point_size = lidar_obj.point_size or 100.0 end
    local p_off = {0,0,0,0}
    if lidar_obj and lidar_obj.attach_to and M.poses[lidar_obj.attach_to] then
        local p = M.poses[lidar_obj.attach_to]; p_off = {p.x, p.y, p.z, p.yaw}
    end
    static.pc_r.pose_x, static.pc_r.pose_y, static.pc_r.pose_z, static.pc_r.pose_yaw = p_off[1], p_off[2], p_off[3], p_off[4]

    static.img_barrier_g[0].oldLayout, static.img_barrier_g[0].newLayout, static.img_barrier_g[0].srcAccessMask, static.img_barrier_g[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[1].oldLayout, static.img_barrier_g[1].newLayout, static.img_barrier_g[1].srcAccessMask, static.img_barrier_g[1].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[2].oldLayout, static.img_barrier_g[2].newLayout, static.img_barrier_g[2].srcAccessMask, static.img_barrier_g[2].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[3].oldLayout, static.img_barrier_g[3].newLayout, static.img_barrier_g[3].srcAccessMask, static.img_barrier_g[3].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 4, static.img_barrier_g)
    vk.vkCmdBeginRendering(cb_handle, static.render_info_g); vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport); vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)
    static.sets[0] = mc.gpu.get_bindless_set(); vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_layout, 0, 1, static.sets, 0, nil)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_grid_g); static.pc_r.pose_x, static.pc_r.pose_y = M.cam.target[0], M.cam.target[1]
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r); vk.vkCmdDraw(cb_handle, 4, 1, 0, 0)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_line_g); static.pc_r.buf_idx = (frame_idx == 0) and 14 or 15
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r); vk.vkCmdDraw(cb_handle, (M.active_robot_line_count or 0) / 2 * 6, 1, 0, 0)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_render_g); vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    if (point_count or 0) > 0 then vk.vkCmdDraw(cb_handle, 4, point_count, 0, 0) end
    vk.vkCmdEndRendering(cb_handle)
    for i=0,2 do static.img_barrier_g[i].oldLayout, static.img_barrier_g[i].newLayout, static.img_barrier_g[i].srcAccessMask, static.img_barrier_g[i].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT end
    static.img_barrier_l[0].oldLayout, static.img_barrier_l[0].newLayout, static.img_barrier_l[0].srcAccessMask, static.img_barrier_l[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 0, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, bit.bor(vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT), 0, 0, nil, 0, nil, 3, static.img_barrier_g)
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_l)
    vk.vkCmdBeginRendering(cb_handle, static.render_info_l); vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport); vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_light); static.pc_l.color_idx, static.pc_l.normal_idx, static.pc_l.pos_idx = 100, 101, 102
    static.pc_l.light_dir[0], static.pc_l.light_dir[1], static.pc_l.light_dir[2] = 1.0, 1.0, 1.0
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout_light, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, 32, static.pc_l); static.sets[0] = mc.gpu.get_bindless_set()
    vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_layout_light, 0, 1, static.sets, 0, nil); vk.vkCmdDraw(cb_handle, 3, 1, 0, 0); vk.vkCmdEndRendering(cb_handle)
    static.img_barrier_l[0].oldLayout, static.img_barrier_l[0].newLayout, static.img_barrier_l[0].srcAccessMask, static.img_barrier_l[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_l)
    static.img_barrier_b[0].oldLayout, static.img_barrier_b[0].newLayout, static.img_barrier_b[0].srcAccessMask, static.img_barrier_b[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL, 0, vk.VK_ACCESS_SHADER_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_b)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.pipe_blur); static.pc_b.in_idx, static.pc_b.out_idx, static.pc_b.inv_size[0], static.pc_b.inv_size[1] = M.final_color_idx, M.blurred_color_idx, 1.0 / M.w, 1.0 / M.h
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout_blur, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, static.pc_b); vk.vkCmdDispatch(cb_handle, math.ceil(M.w / 16), math.ceil(M.h / 16), 1)
    static.img_barrier_b[0].oldLayout, static.img_barrier_b[0].newLayout, static.img_barrier_b[0].srcAccessMask, static.img_barrier_b[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_GENERAL, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_b)
end

if jit then
    jit.off(M.render_deferred)
end

return M
