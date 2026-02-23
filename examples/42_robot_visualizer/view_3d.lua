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
local imgui = require("imgui")

local M = {
    cam = { orbit_x = 45, orbit_y = 45, dist = 50, target = {0, 0, 5}, ortho = false },
    points_count = 10000,
    -- Pipelines
    pipe_layout = nil, pipe_render = nil, pipe_line = nil, pipe_line_no_depth = nil,
    -- Buffers
    point_buffer = nil, line_buffer = nil, line_count = 0, robot_buffer = nil, robot_line_count = 24,
    depth_image = nil,
}

local static = {
    pc_r = ffi.new("RenderPC"),
    viewport = ffi.new("VkViewport"),
    scissor = ffi.new("VkRect2D"),
    v_buffs = ffi.new("VkBuffer[1]"),
    v_offs = ffi.new("VkDeviceSize[1]", {0}),
    sets = ffi.new("VkDescriptorSet[1]"),
    cam_pos = ffi.new("mc_vec3"),
    cam_target = ffi.new("mc_vec3"),
    depth_attach = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE }),
    -- State saving
    saved_viewport = ffi.new("VkViewport"),
    saved_scissor = ffi.new("VkRect2D"),
}

local callback_data_pool = {}
for i=1, 10 do table.insert(callback_data_pool, ffi.new("LidarCallbackData")) end
local callback_data_idx = 1

function M.init(device, bindless_set, sw)
    local bl_layout = mc.gpu.get_bindless_layout()
    M.pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_ALL_GRAPHICS, offset = 0, size = ffi.sizeof("RenderPC") }}))
    
    local v_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/point.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_point = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/point.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    M.pipe_render = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_point, f_point, { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB },
        depth_test = true, depth_write = true 
    })

    local v_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/line.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_line = shader.create_module(device, shader.compile_glsl(io.open("examples/42_robot_visualizer/shaders/line.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    
    local line_opts = { 
        topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, 
        alpha_blend = true, color_formats = { vk.VK_FORMAT_B8G8R8A8_SRGB },
        depth_test = true, depth_write = true,
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", { { binding = 0, stride = ffi.sizeof("LineVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX } }),
        vertex_attribute_count = 2,
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[2]", { 
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 12 }
        })
    }
    M.pipe_line = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_line, f_line, line_opts)
    
    line_opts.depth_test, line_opts.depth_write = false, false
    M.pipe_line_no_depth = pipeline.create_graphics_pipeline(device, M.pipe_layout, v_line, f_line, line_opts)

    M.point_buffer = mc.buffer(M.points_count * 16, "storage", nil, false)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, M.point_buffer.handle, 0, M.point_buffer.size, 11)

    M.depth_image = mc.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    static.depth_attach.imageView = M.depth_image.view
    static.depth_attach.clearValue.depthStencil.depth = 1.0
    M.depth_attach = static.depth_attach

    -- Geometry generation
    local verts = {}
    local function add_line(x1,y1,z1, x2,y2,z2, r,g,b,a)
        table.insert(verts, {x=x1,y=y1,z=z1, r=r,g=g,b=b,a=a})
        table.insert(verts, {x=x2,y=y2,z=z2, r=r,g=g,b=b,a=a})
    end
    for i = -10, 10 do
        local alpha = (i == 0) and 0.5 or 0.2
        add_line(i, -10, -0.01, i, 10, -0.01, 1, 1, 1, alpha)
        add_line(-10, i, -0.01, 10, i, -0.01, 1, 1, 1, alpha)
    end
    local function add_cube(x,y,z, sz, r,g,b,a)
        local s = sz/2
        add_line(x-s,y-s,z-s, x+s,y-s,z-s, r,g,b,a)
        add_line(x+s,y-s,z-s, x+s,y+s,z-s, r,g,b,a)
        add_line(x+s,y+s,z-s, x-s,y+s,z-s, r,g,b,a)
        add_line(x-s,y+s,z-s, x-s,y-s,z-s, r,g,b,a)
        add_line(x-s,y-s,z+s, x+s,y-s,z+s, r,g,b,a)
        add_line(x+s,y-s,z+s, x+s,y+s,z+s, r,g,b,a)
        add_line(x+s,y+s,z+s, x-s,y+s,z+s, r,g,b,a)
        add_line(x-s,y+s,z+s, x-s,y-s,z+s, r,g,b,a)
        add_line(x-s,y-s,z-s, x-s,y-s,z+s, r,g,b,a)
        add_line(x+s,y-s,z-s, x+s,y-s,z+s, r,g,b,a)
        add_line(x+s,y+s,z-s, x+s,y+s,z+s, r,g,b,a)
        add_line(x-s,y+s,z-s, x-s,y+s,z+s, r,g,b,a)
    end
    add_cube(1, 0, 0.5, 1.0, 1, 0, 1, 1)
    add_cube(0, 1, 0.5, 1.0, 0, 1, 1, 1)
    add_cube(0, 0, 0.5, 1.0, 1, 1, 0, 1)
    add_line(0,0,0, 2,0,0, 1,0,0,1)
    add_line(0,0,0, 0,2,0, 0,1,0,1)
    add_line(0,0,0, 0,0,2, 0,0,1,1)

    M.line_count = #verts
    M.line_buffer = mc.buffer(M.line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)
    local p_verts = ffi.cast("LineVertex*", M.line_buffer.allocation.ptr)
    for i, v in ipairs(verts) do 
        p_verts[i-1].x, p_verts[i-1].y, p_verts[i-1].z = v.x, v.y, v.z
        p_verts[i-1].r, p_verts[i-1].g, p_verts[i-1].b, p_verts[i-1].a = v.r, v.g, v.b, v.a
    end

    M.robot_buffer = mc.buffer(M.robot_line_count * ffi.sizeof("LineVertex"), "vertex", nil, true)
end

function M.reset_frame()
    callback_data_idx = 1
end

function M.register_panels()
    panels.register("view3d", "3D Scene", function(gui, node_id)
        if gui.igBeginChild_Str("Scene", {0,0}, false, 0) then
            local p, s = imgui.gui.igGetWindowPos(), imgui.gui.igGetWindowSize()
            local data = callback_data_pool[callback_data_idx]; callback_data_idx = (callback_data_idx % 10) + 1
            data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
            imgui.gui.ImDrawList_AddCallback(imgui.gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
        end
        gui.igEndChild()
    end)
    panels.register("lidar", "Lidar Cloud", function(gui, node_id)
        if gui.igBeginChild_Str("Lidar", {0,0}, false, 0) then
            local p, s = imgui.gui.igGetWindowPos(), imgui.gui.igGetWindowSize()
            local data = callback_data_pool[callback_data_idx]; callback_data_idx = (callback_data_idx % 10) + 1
            data.x, data.y, data.w, data.h = p.x, p.y, s.x, s.y
            imgui.gui.ImDrawList_AddCallback(imgui.gui.igGetWindowDrawList(), ffi.cast("ImDrawCallback", 1), data, ffi.sizeof("LidarCallbackData")) 
        end
        gui.igEndChild()
    end)
end

function M.update_robot_buffer()
    local rv = ffi.cast("LineVertex*", M.robot_buffer.allocation.ptr)
    local px, py, pz, yaw = playback.robot_pose.x, playback.robot_pose.y, playback.robot_pose.z, playback.robot_pose.yaw
    local s, c = math.sin(yaw), math.cos(yaw)
    local function add_robot_line(idx, x1,y1,z1, x2,y2,z2, r,g,b,a)
        local rx1, ry1 = x1*c - y1*s, x1*s + y1*c
        local rx2, ry2 = x2*c - y2*s, x2*s + y2*c
        rv[idx].x, rv[idx].y, rv[idx].z = px+rx1, py+ry1, pz+z1
        rv[idx].r, rv[idx].g, rv[idx].b, rv[idx].a = r, g, b, a
        rv[idx+1].x, rv[idx+1].y, rv[idx+1].z = px+rx2, py+ry2, pz+z2
        rv[idx+1].r, rv[idx+1].g, rv[idx+1].b, rv[idx+1].a = r, g, b, a
        return idx + 2
    end
    local cur_i = 0
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0,  0.5,-0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0,  0.5, 0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0, -0.5, 0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0, -0.5,-0.5,0, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0.5,  0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0.5,  0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0.5, -0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0.5, -0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5,-0.5,0, -0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5,-0.5,0,  0.5,-0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i,  0.5, 0.5,0,  0.5, 0.5,0.5, 1,1,0,1)
    cur_i = add_robot_line(cur_i, -0.5, 0.5,0, -0.5, 0.5,0.5, 1,1,0,1)
end

function M.on_callback(cb_handle, data_ptr, imgui_renderer)
    local data = ffi.cast("LidarCallbackData*", data_ptr)
    local rx, ry = mc.rad(M.cam.orbit_x), mc.rad(M.cam.orbit_y)
    static.cam_target.x, static.cam_target.y, static.cam_target.z = M.cam.target[1], M.cam.target[2], M.cam.target[3]
    static.cam_pos.x = static.cam_target.x + M.cam.dist * math.cos(ry) * math.cos(rx)
    static.cam_pos.y = static.cam_target.y + M.cam.dist * math.cos(ry) * math.sin(rx)
    static.cam_pos.z = static.cam_target.z + M.cam.dist * math.sin(ry)
    
    local p
    if M.cam.ortho then
        local h = M.cam.dist * 0.5
        local w = h * (data.w / data.h)
        p = mc.mat4_ortho(-w, w, -h, h, -1000.0, 1000.0)
    else
        p = mc.mat4_perspective(mc.rad(45), data.w/data.h, 0.1, 1000.0)
    end
    local v = mc.mat4_look_at({static.cam_pos.x, static.cam_pos.y, static.cam_pos.z}, {static.cam_target.x, static.cam_target.y, static.cam_target.z}, {0,0,1})
    local mvp = mc.mat4_multiply(p, v)
    for i=0,15 do static.pc_r.view_proj[i] = mvp.m[i] end
    static.pc_r.buf_idx, static.pc_r.point_size = 11, 3.0
    
    local sx, sy = _G._WIN_PW / _G._WIN_LW, _G._WIN_PH / _G._WIN_LH
    static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height, static.viewport.minDepth, static.viewport.maxDepth = data.x*sx, data.y*sy, data.w*sx, data.h*sy, 0, 1
    vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
    static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height
    vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)

    -- Clear Depth
    local clear_depth = ffi.new("VkClearAttachment[1]", {{ aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, clearValue = { depthStencil = { depth = 1.0 } } }})
    local clear_rect = ffi.new("VkClearRect[1]", {{ rect = static.scissor, layerCount = 1 }})
    vk.vkCmdClearAttachments(cb_handle, 1, clear_depth, 1, clear_rect)

    -- 1. Draw Grid and Axes
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_line)
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    static.v_buffs[0] = M.line_buffer.handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdDraw(cb_handle, M.line_count, 1, 0, 0)

    -- 1b. Draw Robot
    static.v_buffs[0] = M.robot_buffer.handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdDraw(cb_handle, M.robot_line_count, 1, 0, 0)

    -- 2. Draw Lidar
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_render)
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    vk.vkCmdDraw(cb_handle, M.points_count, 1, 0, 0)

    -- 3. Orientation Gizmo
    local gz_size = 80 * sx
    static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height = (data.x + data.w)*sx - gz_size - 10*sx, (data.y + data.h)*sy - gz_size - 10*sy, gz_size, gz_size
    vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
    static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height
    vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)

    local gp = mc.mat4_ortho(-1.5, 1.5, -1.5, 1.5, -10, 10)
    local gv = mc.mat4_look_at({static.cam_pos.x - static.cam_target.x, static.cam_pos.y - static.cam_target.y, static.cam_pos.z - static.cam_target.z}, {0,0,0}, {0,0,1})
    local gmvp = mc.mat4_multiply(gp, gv)
    for i=0,15 do static.pc_r.view_proj[i] = gmvp.m[i] end
    
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipe_line_no_depth)
    vk.vkCmdPushConstants(cb_handle, M.pipe_layout, vk.VK_SHADER_STAGE_ALL_GRAPHICS, 0, ffi.sizeof("RenderPC"), static.pc_r)
    static.v_buffs[0] = M.line_buffer.handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdDraw(cb_handle, 6, 1, M.line_count - 6, 0)

    -- 4. Restore ImGui State (Full window so ImGui can manage its own clipping)
    vk.vkCmdBindPipeline(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.pipeline)
    static.viewport.x, static.viewport.y, static.viewport.width, static.viewport.height = 0, 0, _G._WIN_PW, _G._WIN_PH
    vk.vkCmdSetViewport(cb_handle, 0, 1, static.viewport)
    static.scissor.offset.x, static.scissor.offset.y, static.scissor.extent.width, static.scissor.extent.height = 0, 0, _G._WIN_PW, _G._WIN_PH
    vk.vkCmdSetScissor(cb_handle, 0, 1, static.scissor)
    
    static.sets[0] = mc.gpu.get_bindless_set()
    vk.vkCmdBindDescriptorSets(cb_handle, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, imgui_renderer.layout, 0, 1, static.sets, 0, nil)
    static.v_buffs[0] = imgui_renderer.v_buffer.handle
    vk.vkCmdBindVertexBuffers(cb_handle, 0, 1, static.v_buffs, static.v_offs)
    vk.vkCmdBindIndexBuffer(cb_handle, imgui_renderer.i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT16)
end

return M
