local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local bit = require("bit")

local M = {
    last_frame_time = 0,
    current_time = 0,
    angle = 0,
    last_rebuild = 0,
}

local REBUILD_INTERVAL = 0.25
local NX, NY, NZ = 52, 26, 52
local X_EXTENT, Y_EXTENT, Z_EXTENT = 20.0, 10.0, 20.0
local SITE_COUNT = 180
local MAX_VORONOI_POINTS = NX * NY * NZ
local MAX_PATH_POINTS = 8192
local MAX_MARKERS = 320

local START = { x = -8.6, y = -2.3, z = -8.6 }
local GOAL = { x = 8.4, y = 2.2, z = 8.4 }

local device, queue, graphics_family, sw
local layout_graph, bindless_set, pipe_points, pipe_lines
local voronoi_ptr, path_ptr, marker_ptr
local voronoi_count, path_count, marker_count = 0, 0, 0
local image_available, cb, frame_fence

local sites = {}
local SITE_MARGIN, START_GOAL_CLEARANCE, SITE_SPEED_SCALE, SITE_SWAY_SCALE = 0.25, 1.35, 3.0, 1.2

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local t = f:read("*all"); f:close()
    return t
end

local function clamp(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end
local function world_x(ix) return ((ix / (NX - 1)) - 0.5) * X_EXTENT end
local function world_y(iy) return ((iy / (NY - 1)) - 0.5) * Y_EXTENT end
local function world_z(iz) return ((iz / (NZ - 1)) - 0.5) * Z_EXTENT end
local function grid_x(x) return clamp(math.floor(((x / X_EXTENT) + 0.5) * (NX - 1) + 0.5), 0, NX - 1) end
local function grid_y(y) return clamp(math.floor(((y / Y_EXTENT) + 0.5) * (NY - 1) + 0.5), 0, NY - 1) end
local function grid_z(z) return clamp(math.floor(((z / Z_EXTENT) + 0.5) * (NZ - 1) + 0.5), 0, NZ - 1) end
local function idx3(x, y, z) return (z * NY + y) * NX + x end

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].size = x, y, z, size
    ptr[i].r, ptr[i].g, ptr[i].b, ptr[i].a = r, g, b, a
end

local function sdf_to_sites(px, py, pz)
    local best, best_i = 1e9, -1
    for i = 1, #sites do
        local s = sites[i]
        local d = math.sqrt((px - s.x)^2 + (py - s.y)^2 + (pz - s.z)^2) - s.r
        if d < best then best, best_i = d, i end
    end
    return best, best_i
end

local function segment_clear(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local n = math.max(2, math.floor(math.sqrt(dx*dx + dy*dy + dz*dz) / 0.25))
    for i = 0, n do if sdf_to_sites(a.x + dx * (i/n), a.y + dy * (i/n), a.z + dz * (i/n)) < 0.02 then return false end end
    return true
end

local function init_sites()
    sites = {}
    for i = 1, SITE_COUNT do
        local phase = i * 1.37
        local s = { x = math.sin(phase * 0.93) * 7.8, y = math.cos(phase * 1.11) * 3.2, z = math.cos(phase * 0.79) * 7.8, r = 0.58 + 0.14 * (i % 4), vx = (0.22 + 0.03 * (i % 5)) * SITE_SPEED_SCALE, vy = (0.15 + 0.02 * (i % 4)) * SITE_SPEED_SCALE, vz = (0.24 + 0.025 * (i % 6)) * SITE_SPEED_SCALE, p1 = phase * 0.73, p2 = phase * 0.57, p3 = phase * 0.91 }
        if (i % 2) == 0 then s.vx = -s.vx end; if (i % 3) == 0 then s.vy = -s.vy end; if (i % 5) == 0 then s.vz = -s.vz end
        sites[#sites + 1] = s
    end
end

local function update_sites(dt)
    for i = 1, #sites do
        local s = sites[i]; local sway_t = M.current_time
        s.x, s.y, s.z = s.x + (s.vx + math.sin(sway_t * 1.6 + s.p1) * SITE_SWAY_SCALE) * dt, s.y + (s.vy + math.cos(sway_t * 1.9 + s.p2) * SITE_SWAY_SCALE * 0.85) * dt, s.z + (s.vz + math.sin(sway_t * 1.4 + s.p3) * SITE_SWAY_SCALE) * dt
        local mx, my, mz = X_EXTENT * 0.5 - s.r - SITE_MARGIN, Y_EXTENT * 0.5 - s.r - SITE_MARGIN, Z_EXTENT * 0.5 - s.r - SITE_MARGIN
        if s.x < -mx then s.x, s.vx = -mx, math.abs(s.vx) elseif s.x > mx then s.x, s.vx = mx, -math.abs(s.vx) end
        if s.y < -my then s.y, s.vy = -my, math.abs(s.vy) elseif s.y > my then s.y, s.vy = my, -math.abs(s.vy) end
        if s.z < -mz then s.z, s.vz = -mz, math.abs(s.vz) elseif s.z > mz then s.z, s.vz = mz, -math.abs(s.vz) end
    end
end

local function refresh_markers()
    marker_count = 0; set_draw_point(marker_ptr, 0, START.x, START.y, START.z, 11.0, 0.2, 1.0, 0.3, 1.0); set_draw_point(marker_ptr, 1, GOAL.x, GOAL.y, GOAL.z, 12.0, 1.0, 1.0, 0.2, 1.0); marker_count = 2
    for i = 1, math.min(#sites, MAX_MARKERS-2) do local s = sites[i]; set_draw_point(marker_ptr, marker_count, s.x, s.y, s.z, s.r * 30.0, 1.0, 0.18, 0.18, 0.92); marker_count = marker_count + 1 end
end

local function build_voronoi_graph_and_path()
    local clearance, label, free = {}, {}, {}
    for z = 0, NZ - 1 do for y = 0, NY - 1 do for x = 0, NX - 1 do
        local id = idx3(x, y, z); clearance[id], label[id] = sdf_to_sites(world_x(x), world_y(y), world_z(z)); free[id] = clearance[id] > 0.03
    end end end
    local vnodes, node_of, dirs = {}, {}, {{1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1}}
    for z = 1, NZ - 2 do for y = 1, NY - 2 do for x = 1, NX - 2 do
        local id = idx3(x, y, z)
        if free[id] and clearance[id] > 0.12 then
            local site_set, distinct, mylab = { [label[id]] = true }, 0, label[id]
            for _, d in ipairs(dirs) do local nid = idx3(x+d[1], y+d[2], z+d[3]); if free[nid] and not site_set[label[nid]] then site_set[label[nid]], distinct = true, distinct + 1 end end
            if distinct >= 1 then vnodes[#vnodes+1] = { x = x, y = y, z = z, id = id }; node_of[id] = #vnodes end
        end
    end end end
    local adj = {}; for i = 1, #vnodes do adj[i] = {} end
    for i = 1, #vnodes do for _, d in ipairs(dirs) do local nid = idx3(vnodes[i].x+d[1], vnodes[i].y+d[2], vnodes[i].z+d[3]); if node_of[nid] then table.insert(adj[i], node_of[nid]) end end end
    local function nearest(p)
        local best_i, best_d = -1, 1e9
        for i = 1, #vnodes do local wx, wy, wz = world_x(vnodes[i].x), world_y(vnodes[i].y), world_z(vnodes[i].z); local dd = (wx-p.x)^2 + (wy-p.y)^2 + (wz-p.z)^2; if dd < best_d and segment_clear(p, {x=wx, y=wy, z=wz}) then best_d, best_i = dd, i end end
        return best_i
    end
    local s_idx, g_idx, path_nodes = nearest(START), nearest(GOAL), {}
    if s_idx ~= -1 and g_idx ~= -1 then
        local parent, seen, q, head = { [s_idx] = -1 }, { [s_idx] = true }, { s_idx }, 1
        while head <= #q do local u = q[head]; head = head + 1; if u == g_idx then break end; for _, v in ipairs(adj[u]) do if not seen[v] then seen[v], parent[v] = true, u; q[#q+1] = v end end end
        if seen[g_idx] then local cur = g_idx; while cur ~= -1 do table.insert(path_nodes, 1, cur); cur = parent[cur] or -1 end end
    end
    voronoi_count = 0; for i = 1, math.min(#vnodes, MAX_VORONOI_POINTS) do local v = vnodes[i]; set_draw_point(voronoi_ptr, voronoi_count, world_x(v.x), world_y(v.y), world_z(v.z), 2.3, 0.12, 0.45, 0.95, 0.28); voronoi_count = voronoi_count + 1 end
    local function simplify(pts) if #pts <= 2 then return pts end; local out, i = {pts[1]}, 1; while i < #pts do local bj = i + 1; for j = i+2, #pts do if segment_clear(pts[i], pts[j]) then bj = j else break end end; table.insert(out, pts[bj]); i = bj end; return out end
    local route = {START}
    if #path_nodes > 0 then for _, idx in ipairs(path_nodes) do table.insert(route, {x=world_x(vnodes[idx].x), y=world_y(vnodes[idx].y), z=world_z(vnodes[idx].z)}) end end
    table.insert(route, GOAL); route = simplify(route)
    if #route > 1 then path_count = 0; for i, p in ipairs(route) do set_draw_point(path_ptr, path_count, p.x, p.y, p.z, (i==1 or i==#route) and 7.0 or 6.2, 3.8, 2.8, 0.35, 0.95); path_count = path_count + 1 end end
    refresh_markers()
end

function M.init()
    print("Example 18: 3D Voronoi Graph (using mc.gpu StdLib)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    ffi.cdef[[ typedef struct DrawPoint { float x, y, z, size, r, g, b, a; } DrawPoint; typedef struct DrawPC { float mvp[16]; uint32_t mode, count, pad0, pad1; } DrawPC; ]]
    local v_sz, p_sz, m_sz = ffi.sizeof("DrawPoint") * MAX_VORONOI_POINTS, ffi.sizeof("DrawPoint") * MAX_PATH_POINTS, ffi.sizeof("DrawPoint") * MAX_MARKERS
    local b_v, b_p, b_m = mc.buffer(v_sz, "storage", nil, true), mc.buffer(p_sz, "storage", nil, true), mc.buffer(m_sz, "storage", nil, true)
    voronoi_ptr, path_ptr, marker_ptr = ffi.cast("DrawPoint*", b_v.allocation.ptr), ffi.cast("DrawPoint*", b_p.allocation.ptr), ffi.cast("DrawPoint*", b_m.allocation.ptr)
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_v.handle, 0, v_sz, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_p.handle, 0, p_sz, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_m.handle, 0, m_sz, 2)
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = ffi.sizeof("DrawPC") }}))
    local d_v = shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/18_voronoi_sdf_graph/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    init_sites(); build_voronoi_graph_and_path()
end

function M.update()
 M.current_time = M.current_time + 0.016; update_sites(0.016); refresh_markers()
    if M.current_time - M.last_rebuild > REBUILD_INTERVAL then build_voronoi_graph_and_path(); M.last_rebuild = M.current_time end
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local mvp = mc.mat4_multiply(mc.mat4_perspective(math.rad(45), sw.extent.width/sw.extent.height, 0.1, 120.0), mc.mat4_look_at({ math.cos(M.angle)*24.0, 12.0, math.sin(M.angle)*24.0 }, {0,0,0}, {0,1,0}))
    M.angle, pc = M.angle + 0.002, ffi.new("DrawPC"); for i=1,16 do pc.mvp[i-1] = mvp.m[i-1] end
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.008, 0.008, 0.015, 1.0 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent })); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    pc.mode, pc.count = 0, voronoi_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, voronoi_count, 1, 0, 0)
    if path_count > 1 then pc.mode, pc.count = 1, path_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines); vk.vkCmdDraw(cb, path_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, path_count, 1, 0, 0) end
    pc.mode, pc.count = 2, marker_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, marker_count, 1, 0, 0); vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
