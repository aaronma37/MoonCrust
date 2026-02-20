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

local REBUILD_INTERVAL = 1.20
local NX, NY, NZ = 32, 16, 32
local X_EXTENT, Y_EXTENT, Z_EXTENT = 20.0, 10.0, 20.0
local ROOT_SIZE, MIN_SIZE = 8, 1
local SITE_COUNT, SITE_MARGIN, START_GOAL_CLEARANCE, SITE_SPEED_SCALE, SITE_SWAY_SCALE = 170, 0.25, 1.35, 2.7, 1.1
local MAX_NODE_POINTS, MAX_PATH_POINTS, MAX_MARKERS, MAX_GRAPH_NODES = 12000, 8192, 640, 6500
local START, GOAL = { x = -8.0, y = -2.0, z = -8.0 }, { x = 8.0, y = 2.0, z = 8.0 }

local device, queue, graphics_family, sw, layout_graph, bindless_set, pipe_points, pipe_lines
local node_ptr, path_ptr, marker_ptr
local node_count, path_count, marker_count, has_valid_path = 0, 0, 0, false
local image_available, cb, frame_fence

local sites = {}

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local t = f:read("*all"); f:close()
    return t
end

local function clamp(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end
local function world_xf(ix) return ((ix / (NX - 1)) - 0.5) * X_EXTENT end
local function world_yf(iy) return ((iy / (NY - 1)) - 0.5) * Y_EXTENT end
local function world_zf(iz) return ((iz / (NZ - 1)) - 0.5) * Z_EXTENT end
local function grid_xf(x) return ((x / X_EXTENT) + 0.5) * (NX - 1) end
local function grid_yf(y) return ((y / Y_EXTENT) + 0.5) * (NY - 1) end
local function grid_zf(z) return ((z / Z_EXTENT) + 0.5) * (NZ - 1) end
local function idx3(x, y, z) return (z * NY + y) * NX + x end

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].size = x, y, z, size
    ptr[i].r, ptr[i].g, ptr[i].b, ptr[i].a = r, g, b, a
end

local function sdf_to_sites(px, py, pz)
    local best = 1e9
    for i = 1, #sites do
        local s = sites[i]; local d = math.sqrt((px - s.x)^2 + (py - s.y)^2 + (pz - s.z)^2) - s.r
        if d < best then best = d end
    end
    return best
end

local function segment_clear(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local n = math.max(2, math.floor(math.sqrt(dx*dx + dy*dy + dz*dz) / 0.22))
    for i = 0, n do if sdf_to_sites(a.x + dx * (i/n), a.y + dy * (i/n), a.z + dz * (i/n)) < 0.03 then return false end end
    return true
end

local function init_sites()
    sites = {}
    for i = 1, SITE_COUNT do
        local phase = i * 1.37
        local s = { x = math.sin(phase * 0.93) * 7.8, y = math.cos(phase * 1.11) * 3.2, z = math.cos(phase * 0.79) * 7.8, r = 0.45 + 0.18 * (i % 5), vx = (0.20 + 0.025 * (i % 5)) * SITE_SPEED_SCALE, vy = (0.14 + 0.02 * (i % 4)) * SITE_SPEED_SCALE, vz = (0.22 + 0.02 * (i % 6)) * SITE_SPEED_SCALE, p1 = phase * 0.73, p2 = phase * 0.57, p3 = phase * 0.91 }
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
    for i = 1, math.min(#sites, MAX_MARKERS-2) do local s = sites[i]; set_draw_point(marker_ptr, marker_count, s.x, s.y, s.z, s.r * 28.0, 1.0, 0.16, 0.16, 0.88); marker_count = marker_count + 1 end
end

local function cube_sdf_range(ox, oy, oz, size)
    local hi = size - 1; local mx, my, mz = ox + hi*0.5, oy + hi*0.5, oz + hi*0.5
    local pts = {{ox, oy, oz}, {ox+hi, oy, oz}, {ox, oy+hi, oz}, {ox, oy, oz+hi}, {ox+hi, oy+hi, oz}, {ox+hi, oy, oz+hi}, {ox, oy+hi, oz+hi}, {ox+hi, oy+hi, oz+hi}, {mx, my, mz}, {mx, oy, mz}, {mx, oy+hi, mz}, {ox, my, mz}, {ox+hi, my, mz}, {mx, my, oz}, {mx, my, oz+hi}}
    local b_min, b_max = 1e9, -1e9
    for i = 1, #pts do local sdf = sdf_to_sites(world_xf(pts[i][1]), world_yf(pts[i][2]), world_zf(pts[i][3])); if sdf < b_min then b_min = sdf end; if sdf > b_max then b_max = sdf end end
    return b_min, b_max
end

local function build_octree_graph_and_path()
    local nodes, sx, sy, sz, gx, gy, gz = {}, grid_xf(START.x), grid_yf(START.y), grid_zf(START.z), grid_xf(GOAL.x), grid_yf(GOAL.y), grid_zf(GOAL.z)
    local dxw, dyw, dzw = X_EXTENT/(NX-1), Y_EXTENT/(NY-1), Z_EXTENT/(NZ-1)
    local function contains(ox, oy, oz, sz) local hi = sz-1; return (sx>=ox and sx<=ox+hi and sy>=oy and sy<=oy+hi and sz>=oz and sz<=oz+hi) or (gx>=ox and gx<=ox+hi and gy>=oy and gy<=oy+hi and gz>=oz and gz<=oz+hi) end
    local function split(ox, oy, oz, sz)
        local b_min, b_max = cube_sdf_range(ox, oy, oz, sz); if b_max <= 0.03 then return end
        if sz <= MIN_SIZE then local csdf = sdf_to_sites(world_xf(ox), world_yf(oy), world_zf(oz)); if csdf > 0.03 then nodes[#nodes+1] = { ox=ox, oy=oy, oz=oz, size=sz, x=world_xf(ox), y=world_yf(oy), z=world_zf(oz), clear=csdf } end; return end
        local span = math.sqrt((sz*dxw)^2 + (sz*dyw)^2 + (sz*dzw)^2)
        if b_min > 0.72*span and not contains(ox, oy, oz, sz) then local c = sz-1; nodes[#nodes+1] = { ox=ox, oy=oy, oz=oz, size=sz, x=world_xf(ox+0.5*c), y=world_yf(oy+0.5*c), z=world_zf(oz+0.5*c), clear=b_min }; return end
        local half = math.max(1, math.floor(sz/2))
        for dz=0,1 do for dy=0,1 do for dx=0,1 do local cx, cy, cz = ox+dx*half, oy+dy*half, oz+dz*half; if cx<NX and cy<NY and cz<NZ then local csz = math.min(half, math.min(NX-cx, math.min(NY-cy, NZ-cz))); if csz>0 then split(cx, cy, cz, csz) end end; if #nodes >= MAX_GRAPH_NODES then return end end end end
    end
    for oz=0, NZ-1, ROOT_SIZE do for oy=0, NY-1, ROOT_SIZE do for ox=0, NX-1, ROOT_SIZE do split(ox, oy, oz, math.min(ROOT_SIZE, math.min(NX-ox, math.min(NY-oy, NZ-oz)))) end end end
    if #nodes < 2 then return nodes, {}, {} end
    local owner = {}; for i=1, NX*NY*NZ do owner[i]=0 end
    for i, n in ipairs(nodes) do local hi = n.size-1; for z=n.oz, n.oz+hi do for y=n.oy, n.oy+hi do for x=n.ox, n.ox+hi do owner[idx3(x,y,z)+1]=i end end end end
    local adj = {}; for i=1, #nodes do adj[i]={} end; local seen = {}
    local function edge(a, b) if a==b or a==0 or b==0 then return end; local k = math.min(a,b)*65536 + math.max(a,b); if seen[k] then return end; seen[k]=true; table.insert(adj[a], b); table.insert(adj[b], a) end
    for z=0, NZ-1 do for y=0, NY-1 do for x=0, NX-1 do local a = owner[idx3(x,y,z)+1]; if a~=0 then if x+1<NX then edge(a, owner[idx3(x+1,y,z)+1]) end; if y+1<NY then edge(a, owner[idx3(x,y+1,z)+1]) end; if z+1<NZ then edge(a, owner[idx3(x,y,z+1)+1]) end end end end end
    local function nearest(p) local cand = {}; for i, n in ipairs(nodes) do local d2 = (n.x-p.x)^2 + (n.y-p.y)^2 + (n.z-p.z)^2; if d2 < 90.25 and segment_clear(p, n) then table.insert(cand, {i=i, d2=d2}) end end; table.sort(cand, function(a,b) return a.d2 < b.d2 end); local out = {}; for i=1, math.min(20, #cand) do table.insert(out, cand[i].i) end; return out end
    if segment_clear(START, GOAL) then return nodes, adj, {START, GOAL} end
    local N, VS, VG, path = #nodes, #nodes+1, #nodes+2, {}
    local all_adj = {}; for i=1, N do all_adj[i]=adj[i] end; all_adj[VS], all_adj[VG] = {}, {}
    for _, v in ipairs(nearest(START)) do table.insert(all_adj[VS], v); table.insert(all_adj[v], VS) end
    for _, v in ipairs(nearest(GOAL)) do table.insert(all_adj[VG], v); table.insert(all_adj[v], VG) end
    if #all_adj[VS]==0 or #all_adj[VG]==0 then return nodes, adj, {} end
    local function pof(i) return i==VS and START or (i==VG and GOAL or nodes[i]) end
    local function heur(i) local p=pof(i); return math.sqrt((p.x-GOAL.x)^2 + (p.y-GOAL.y)^2 + (p.z-GOAL.z)^2) end
    local gs, fs, par, closed, open = {[VS]=0}, {[VS]=heur(VS)}, {[VS]=-1}, {}, {VS}
    while #open > 0 do
        local bk, bi, bf = 1, open[1], fs[open[1]] or 1e30
        for k=2, #open do if (fs[open[k]] or 1e30) < bf then bk, bi, bf = k, open[k], fs[open[k]] end end
        table.remove(open, bk); if bi==VG then local cur = VG; while cur~=-1 do table.insert(path, 1, pof(cur)); cur = par[cur] or -1 end; return nodes, adj, path end
        closed[bi]=true; for _, nb in ipairs(all_adj[bi]) do if not closed[nb] then local a, b = pof(bi), pof(nb); local d = (gs[bi] or 1e30) + math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2); if d < (gs[nb] or 1e30) then par[nb], gs[nb], fs[nb] = bi, d, d+heur(nb); local found = false; for _, v in ipairs(open) do if v==nb then found=true; break end end; if not found then table.insert(open, nb) end end end end
    end
    return nodes, adj, {}
end

local function simplify(pts) if #pts <= 2 then return pts end; local out, i = {pts[1]}, 1; while i < #pts do local bj = i + 1; for j = i+2, #pts do if segment_clear(pts[i], pts[j]) then bj = j else break end end; table.insert(out, pts[bj]); i = bj end; return out end

function M.init()
    print("Example 19: Octree A* 3D (using mc.gpu StdLib)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    ffi.cdef[[ typedef struct DrawPoint { float x, y, z, size, r, g, b, a; } DrawPoint; typedef struct DrawPC { float mvp[16]; uint32_t mode, count, pad0, pad1; } DrawPC; ]]
    local n_sz, p_sz, m_sz = ffi.sizeof("DrawPoint") * MAX_NODE_POINTS, ffi.sizeof("DrawPoint") * MAX_PATH_POINTS, ffi.sizeof("DrawPoint") * MAX_MARKERS
    local b_n, b_p, b_m = mc.buffer(n_sz, "storage", nil, true), mc.buffer(p_sz, "storage", nil, true), mc.buffer(m_sz, "storage", nil, true)
    node_ptr, path_ptr, marker_ptr = ffi.cast("DrawPoint*", b_n.allocation.ptr), ffi.cast("DrawPoint*", b_p.allocation.ptr), ffi.cast("DrawPoint*", b_m.allocation.ptr)
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_n.handle, 0, n_sz, 0); descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_p.handle, 0, p_sz, 1); descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_m.handle, 0, m_sz, 2)
    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = ffi.sizeof("DrawPC") }}))
    local d_v = shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, d_v, shader.create_module(device, shader.compile_glsl(read_text("examples/19_octree_astar/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    init_sites(); refresh_markers()
end

function M.update()
 M.current_time = M.current_time + 0.016; update_sites(0.016); refresh_markers()
    if M.current_time - M.last_rebuild > REBUILD_INTERVAL then
        local nodes, _, route = build_octree_graph_and_path(); node_count = 0
        for i=1, math.min(#nodes, MAX_NODE_POINTS) do local n, t = nodes[i], clamp((nodes[i].size-1)/(ROOT_SIZE-1), 0, 1); set_draw_point(node_ptr, node_count, n.x, n.y, n.z, 1.5+2.4*t, 0.05+0.2*t, 0.45+0.45*t, 1.0, 0.22+0.2*t); node_count = node_count + 1 end
        if #route > 1 then route = simplify(route); path_count = 0; for i, p in ipairs(route) do set_draw_point(path_ptr, path_count, p.x, p.y, p.z, (i==1 or i==#route) and 7.2 or 6.0, 3.9, 2.9, 0.3, 0.96); path_count = path_count + 1 end; has_valid_path = true elseif not has_valid_path then path_count = 0 end
        M.last_rebuild = M.current_time
    end
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local mvp = mc.mat4_multiply(mc.mat4_perspective(math.rad(45), sw.extent.width/sw.extent.height, 0.1, 120.0), mc.mat4_look_at({ math.cos(M.angle)*24.0, 12.0, math.sin(M.angle)*24.0 }, {0,0,0}, {0,1,0}))
    M.angle, pc = M.angle + 0.002, ffi.new("DrawPC"); for i=1,16 do pc.mvp[i-1] = mvp.m[i-1] end
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.008, 0.008, 0.015, 1.0 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent })); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    pc.mode, pc.count = 0, node_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, node_count, 1, 0, 0)
    if path_count > 1 then pc.mode, pc.count = 1, path_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines); vk.vkCmdDraw(cb, path_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, path_count, 1, 0, 0) end
    pc.mode, pc.count = 2, marker_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, marker_count, 1, 0, 0); vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
