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

local M = {
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = {0, 0, 5}, ortho = false, follow = true },
    points_count = 10000000,
    -- Pipelines
    pipe_layout = nil, pipe_render_g = nil, pipe_line_g = nil,
    pipe_layout_light = nil, pipe_light = nil,
    -- Buffers
    point_buffer = nil, line_buffer = nil, line_count = 0, robot_buffers = nil, robot_line_count = 128,
    
    -- Deferred Targets
    w = 1920, h = 1080,
    g_color = nil, g_normal = nil, g_pos = nil, final_color = nil, depth_image = nil,
    final_color_idx = 103,
    is_hovered = false,
    is_dragging = false,
}

local static = {
    pc_r = ffi.new("RenderPC"),
    pc_l = ffi.new("struct { uint32_t color_idx, normal_idx, pos_idx; float dummy; float light_dir[4]; }"),
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
    img_barrier_g = ffi.new("VkImageMemoryBarrier[4]"),
    img_barrier_l = ffi.new("VkImageMemoryBarrier[1]"),
    render_info_g = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 3 }),
    render_info_l = ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, layerCount = 1, colorAttachmentCount = 1 }),
}

function M.init(device, bindless_set, sw)
    local bl_layout = mc.gpu.get_bindless_layout()
    M.pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }}))
    
    local v_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_render_g = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_point, f_point, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, 
        alpha_blend = false, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R32G32B32A32_SFLOAT },
        depth_test = true, depth_write = true 
    })

    local v_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_line.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_line.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    
    local line_opts = { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, 
        alpha_blend = false, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R32G32B32A32_SFLOAT },
        depth_test = true, depth_write = true,
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", { { binding = 0, stride = ffi.sizeof("LineVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX } }),
        vertex_attribute_count = 2,
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[2]", { 
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 12 }
        })
    }
    M.pipe_line_g = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_line, f_line, line_opts)

    M.pipe_layout_light = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = 32 }}))
    local v_light = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_light.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_light = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/def_light.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_light = pipeline.create_graphics_pipeline(device, M.pipe_layout_light, v_light, f_light, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, 
        alpha_blend = false, color_formats = { vk.VK_FORMAT_R8G8B8A8_UNORM },
        depth_test = false, depth_write = false 
    })

    M.point_buffers = {
        mc.buffer(M.points_count * 16, "storage", nil, false),
        mc.buffer(M.points_count * 16, "storage", nil, false)
    }
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[1].handle, 0, M.point_buffers[1].size, 11)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffers[2].handle, 0, M.point_buffers[2].size, 13)

    local sampler = mc.gpu.sampler()
    M.g_color = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled")
    M.g_normal = mc.image(M.w, M.h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "color_attachment_sampled")
    M.g_pos = mc.image(M.w, M.h, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "color_attachment_sampled")
    M.final_color = mc.image(M.w, M.h, vk.VK_FORMAT_R8G8B8A8_UNORM, "color_attachment_sampled")
    M.depth_image = mc.image(M.w, M.h, vk.VK_FORMAT_D32_SFLOAT, "depth")

    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 100)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_normal.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 101)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.g_pos.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 102)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, M.final_color.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, M.final_color_idx)

    static.depth_attach.imageView = M.depth_image.view
    static.depth_attach.clearValue.depthStencil.depth = 1.0
    
    for i=0,2 do
        static.color_attach_g[i].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        static.color_attach_g[i].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        static.color_attach_g[i].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        static.color_attach_g[i].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        static.color_attach_g[i].clearValue.color.float32[0] = 0.0
        static.color_attach_g[i].clearValue.color.float32[1] = 0.0
        static.color_attach_g[i].clearValue.color.float32[2] = 0.0
        static.color_attach_g[i].clearValue.color.float32[3] = 0.0
    end
    static.color_attach_g[0].imageView = M.g_color.view
    static.color_attach_g[1].imageView = M.g_normal.view
    static.color_attach_g[2].imageView = M.g_pos.view

    static.render_info_g.renderArea.extent = {width=M.w, height=M.h}
    static.render_info_g.pColorAttachments = static.color_attach_g
    static.render_info_g.pDepthAttachment = static.depth_attach

    static.color_attach_l[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    static.color_attach_l[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    static.color_attach_l[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_DONT_CARE
    static.color_attach_l[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    static.color_attach_l[0].imageView = M.final_color.view

    static.render_info_l.renderArea.extent = {width=M.w, height=M.h}
    static.render_info_l.pColorAttachments = static.color_attach_l

    for i=0,3 do
        static.img_barrier_g[i].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
        static.img_barrier_g[i].subresourceRange.levelCount = 1
        static.img_barrier_g[i].subresourceRange.layerCount = 1
    end
    static.img_barrier_g[0].image = M.g_color.handle; static.img_barrier_g[0].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[1].image = M.g_normal.handle; static.img_barrier_g[1].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[2].image = M.g_pos.handle; static.img_barrier_g[2].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT
    static.img_barrier_g[3].image = M.depth_image.handle; static.img_barrier_g[3].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT
    
    static.img_barrier_l[0].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
    static.img_barrier_l[0].image = M.final_color.handle
    static.img_barrier_l[0].subresourceRange.levelCount = 1
    static.img_barrier_l[0].subresourceRange.layerCount = 1
    static.img_barrier_l[0].subresourceRange.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT

    local verts = {}
    local function add_line(x1,y1,z1, x2,y2,z2, r,g,b,a)
        table.insert(verts, {x=x1,y=y1,z=z1, r=r,g=g,b=b,a=a})
        table.insert(verts, {x=x2,y=y2,z=z2, r=r,g=g,b=b,a=a})
    end
    local grid_size = 50
    for i = -grid_size, grid_size do
        local major = (i % 10 == 0)
        local axis = (i == 0)
        local alpha = axis and 0.8 or (major and 0.6 or 0.2)
        local r, g, b = 1, 1, 1
        if axis then r, g, b = 1, 1, 1 end 
        add_line(i, -grid_size, -0.01, i, grid_size, -0.01, r, g, b, alpha)
        add_line(-grid_size, i, -0.01, grid_size, i, -0.01, r, g, b, alpha)
    end
    M.line_count = #verts
    M.line_buffer = mc.buffer(M.line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)
    local p_verts = ffi.cast("LineVertex*", M.line_buffer.allocation.ptr)
    for i, v in ipairs(verts) do 
        p_verts[i-1].x, p_verts[i-1].y, p_verts[i-1].z = v.x, v.y, v.z
        p_verts[i-1].r, p_verts[i-1].g, p_verts[i-1].b, p_verts[i-1].a = v.r, v.g, v.b, v.a
    end

    M.robot_buffers = {
        mc.buffer(M.robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true),
        mc.buffer(M.robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)
    }
end

function M.reset_frame()
end

local igImage_hack = nil

function M.register_panels()
    panels.register("view3d", "3D Scene", function(gui, node_id, params)
        if not igImage_hack then
            igImage_hack = ffi.cast("void(*)(void*, uint64_t, ImVec2_c, ImVec2_c, ImVec2_c)", gui.igImage)
        end
        
        -- Store params for the rendering pass
        M.current_params = params

        local p = gui.igGetWindowPos()
        local s = gui.igGetContentRegionAvail()
        gui.igInvisibleButton("##scene_hit", s, 0)
        M.is_hovered = gui.igIsItemHovered(0)
        
        local aspect = M.w / M.h
        local avail_aspect = s.x / s.y
        local img_s = ffi.new("ImVec2_c", {s.x, s.y})
        if avail_aspect > aspect then img_s.x = s.y * aspect else img_s.y = s.x / aspect end
        
        local offset_x = (s.x - img_s.x) * 0.5
        local offset_y = (s.y - img_s.y) * 0.5
        gui.igSetCursorPos(ffi.new("ImVec2_c", {gui.igGetCursorPosX() + offset_x, gui.igGetCursorPosY() - s.y + offset_y}))
        igImage_hack(nil, M.final_color_idx, img_s, ffi.new("ImVec2_c", {0,0}), ffi.new("ImVec2_c", {1,1}))
    end)
    panels.register("lidar", "Lidar Cloud", function(gui, node_id)
        gui.igText("Merged into 3D Scene in Deferred")
    end)
end

function M.update_robot_buffer(frame_idx, params)
    local rv = ffi.cast("LineVertex*", M.robot_buffers[frame_idx + 1].allocation.ptr)
    
    -- 1. Extract Pose Dynamically from Params
    local px, py, pz, yaw = 0, 0, 0, 0
    local pose_topic = params and params.pose_topic
    
    if pose_topic then
        local ch = nil
        if playback.channels then
            for _, c in ipairs(playback.channels) do if c.topic == pose_topic then ch = c; break end end
        end
        
        if ch then
            local buf = playback.message_buffers[ch.id]
            if buf and buf.size > 0 then
                -- Reuse or fetch schema
                if not M.pose_schema then
                    local raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id)
                    if raw then 
                        M.pose_schema = require("examples.42_robot_visualizer.decoder").parse_schema(ffi.string(raw)) 
                        print("Pose: Schema loaded for", pose_topic)
                    end
                end
                
                if M.pose_schema then
                    local vals = require("examples.42_robot_visualizer.decoder").decode(buf.data, M.pose_schema)
                    for _, v in ipairs(vals) do
                        if v.name:find("%.x$") or v.name == "x" then px = tonumber(v.value) end
                        if v.name:find("%.y$") or v.name == "y" then py = tonumber(v.value) end
                        if v.name:find("%.z$") or v.name == "z" then pz = tonumber(v.value) end
                        if v.name:find("yaw") or v.name:find("heading") then yaw = tonumber(v.value) end
                    end
                end
            end
        else
            -- Topic not found yet, don't spam
        end
    end
    
    -- Store current pose for camera following
    M.current_pose = { x = px, y = py, z = pz, yaw = yaw }

    -- 2. Create Base Primitives
    local box = primitives.create_box(2.0, 2.0, 1.0, 1, 1, 0, 1) -- Smaller robot box
    local axes = primitives.create_axes(3.0) -- TF Axes
    
    -- 3. Transform and Copy
    local combined = {}
    for _, v in ipairs(primitives.transform(box, px, py, pz, yaw)) do table.insert(combined, v) end
    for _, v in ipairs(primitives.transform(axes, px, py, pz, yaw)) do table.insert(combined, v) end
    
    for i, v in ipairs(combined) do
        if i > M.robot_line_count then break end
        rv[i-1].x, rv[i-1].y, rv[i-1].z = v.x, v.y, v.z
        rv[i-1].r, rv[i-1].g, rv[i-1].b, rv[i-1].a = v.r, v.g, v.b, v.a
    end
    M.active_robot_line_count = #combined
    -- print("DEBUG: Robot Visual Lines:", M.active_robot_line_count, "at", px, py, pz)
end

function M.render_deferred(cb_handle, point_buf_idx, frame_idx, point_count)
    local params = M.current_params or {}
    
    if (params.follow ~= false) and M.current_pose then
        M.cam.target[1] = M.current_pose.x
        M.cam.target[2] = M.current_pose.y
        M.cam.target[3] = M.current_pose.z + 2.0
    end

    local rx, ry = mc.rad(M.cam.orbit_x), mc.rad(M.cam.orbit_y)
    static.cam_target.x, static.cam_target.y, static.cam_target.z = M.cam.target[1], M.cam.target[2], M.cam.target[3]
    static.cam_pos.x = static.cam_target.x + M.cam.dist * math.cos(ry) * math.cos(rx)
    static.cam_pos.y = static.cam_target.y + M.cam.dist * math.cos(ry) * math.sin(rx)
    static.cam_pos.z = static.cam_target.z + M.cam.dist * math.sin(ry)
    
    local p = mc.mat4_perspective(mc.rad(45), M.w/M.h, 0.1, 1000.0)
    local v = mc.mat4_look_at({static.cam_pos.x, static.cam_pos.y, static.cam_pos.z}, {static.cam_target.x, static.cam_target.y, static.cam_target.z}, {0,0,1})
    local mvp = mc.mat4_multiply(p, v)
    for i=0,15 do static.pc_r.view_proj[i] = mvp.m[i] end
    
    static.pc_r.buf_idx = point_buf_idx or 11
    static.pc_r.point_size = params.point_size or 2.0
    
    if (params.attach ~= false) and M.current_pose then
        static.pc_r.pose_offset[0] = M.current_pose.x
        static.pc_r.pose_offset[1] = M.current_pose.y
        static.pc_r.pose_offset[2] = M.current_pose.z
        static.pc_r.pose_offset[3] = M.current_pose.yaw
    else
        static.pc_r.pose_offset[0], static.pc_r.pose_offset[1], static.pc_r.pose_offset[2], static.pc_r.pose_offset[3] = 0,0,0,0
    end

    static.img_barrier_g[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED; static.img_barrier_g[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[0].srcAccessMask = 0; static.img_barrier_g[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[1].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED; static.img_barrier_g[1].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[1].srcAccessMask = 0; static.img_barrier_g[1].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[2].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED; static.img_barrier_g[2].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[2].srcAccessMask = 0; static.img_barrier_g[2].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    static.img_barrier_g[3].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED; static.img_barrier_g[3].newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL; static.img_barrier_g[3].srcAccessMask = 0; static.img_barrier_g[3].dstAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 4, static.img_barrier_g)

    vk.vkCmdBeginRendering(cb_handle, static.render_info_g)
    vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
    vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)

    static.sets[0] = mc.gpu.get_bindless_set()
    vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_layout, 0, 1, static.sets, 0, nil)

    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_line_g)
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    static.v_buffs[0] = M.line_buffer.handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdDraw(cb_handle, M.line_count, 1, 0, 0)

    static.v_buffs[0] = M.robot_buffers[(frame_idx or 0) + 1].handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdDraw(cb_handle, M.active_robot_line_count or 0, 1, 0, 0)

    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_render_g)
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    if (point_count or 0) > 0 then
        vk.vkCmdDraw(cb_handle, point_count, 1, 0, 0)
    end
    vk.vkCmdEndRendering(cb_handle)

    static.img_barrier_g[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[0].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL; static.img_barrier_g[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT; static.img_barrier_g[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    static.img_barrier_g[1].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[1].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL; static.img_barrier_g[1].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT; static.img_barrier_g[1].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    static.img_barrier_g[2].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_g[2].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL; static.img_barrier_g[2].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT; static.img_barrier_g[2].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    
    static.img_barrier_l[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED; static.img_barrier_l[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_l[0].srcAccessMask = 0; static.img_barrier_l[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, bit.bor(vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT), 0, 0, nil, 0, nil, 3, static.img_barrier_g)
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_l)

    vk.vkCmdBeginRendering(cb_handle, static.render_info_l)
    vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
    vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)
    
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_light)
    static.pc_l.color_idx = 100
    static.pc_l.normal_idx = 101
    static.pc_l.pos_idx = 102
    static.pc_l.light_dir[0] = 1.0; static.pc_l.light_dir[1] = 1.0; static.pc_l.light_dir[2] = 1.0
    
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout_light, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, 32, static.pc_l)
    static.sets[0] = mc.gpu.get_bindless_set()
    vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_layout_light, 0, 1, static.sets, 0, nil)
    
    vk.vkCmdDraw(cb_handle, 3, 1, 0, 0)
    vk.vkCmdEndRendering(cb_handle)

    static.img_barrier_l[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; static.img_barrier_l[0].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL; static.img_barrier_l[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT; static.img_barrier_l[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb_handle, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, static.img_barrier_l)
end

return M