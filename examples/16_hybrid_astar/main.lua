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
    last_reset = 0,
}

local FPS_LIMIT = 120
local FRAME_TIME = 1000 / FPS_LIMIT
local RESET_INTERVAL = 16.0

local NX, NY, NZ = 32, 14, 32
local NH, NP = 16, 7
local STATE_COUNT = NX * NY * NZ * NH * NP
local MAX_FRONTIER = 65536
local INF_COST = 0x3FFFFFFF
local MAX_PATH_POINTS = 4096
local MAX_VIS_POINTS = NX * NY * NZ
local MAX_MARKERS = 48
local VIS_EXTRACT_PERIOD = 8
local SOLUTION_HOLD_TIME = 2.5

local START_X, START_Y, START_Z, START_H, START_P = 3, 2, 3, 2, 3
local GOAL_X, GOAL_Y, GOAL_Z = 27, 11, 27

local device, queue, graphics_family, sw
local layout_graph, bindless_set
local pipe_expand, pipe_points, pipe_lines
local cost_ptr, parent_ptr, open_curr_ptr, open_next_ptr, occupancy_ptr, stats_ptr
local vis_ptr, path_ptr, marker_ptr
local image_available, cb, planning_cb, frame_fence
local visited_count = 0
local path_count = 0
local marker_count = 0
local iter = 0
local frame_id = 0
local solution_latched = false
local solution_latched_time = 0.0

local function read_text(path)
    local f = io.open(path, "r")
    if not f then error("Failed to read " .. tostring(path)) end
    local t = f:read("*all"); f:close()
    return t
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function idx_state(x, y, z, h, p) return (((((z * NY + y) * NX + x) * NH + h) * NP) + p) end
local function decode_state(s)
    local p = s % NP; s = math.floor(s / NP)
    local h = s % NH; s = math.floor(s / NH)
    local x = s % NX; s = math.floor(s / NX)
    local y = s % NY; local z = math.floor(s / NY)
    return x, y, z, h, p
end

local function world_x(x) return ((x / (NX - 1)) - 0.5) * 20.0 end
local function world_y(y) return ((y / (NY - 1)) - 0.5) * 10.0 end
local function world_z(z) return ((z / (NZ - 1)) - 0.5) * 20.0 end
local function grid_x(xw) return clamp(math.floor(((xw / 20.0) + 0.5) * (NX - 1) + 0.5), 0, NX - 1) end
local function grid_y(yw) return clamp(math.floor(((yw / 10.0) + 0.5) * (NY - 1) + 0.5), 0, NY - 1) end
local function grid_z(zw) return clamp(math.floor(((zw / 20.0) + 0.5) * (NZ - 1) + 0.5), 0, NZ - 1) end
local function occ_idx(x, y, z) return (z * NY + y) * NX + x end

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].size = x, y, z, size
    ptr[i].r, ptr[i].g, ptr[i].b, ptr[i].a = r, g, b, a
end

local function reset_search()
    for i = 0, STATE_COUNT - 1 do cost_ptr[i], parent_ptr[i] = INF_COST, 0xFFFFFFFF end
    local sidx = idx_state(START_X, START_Y, START_Z, START_H, START_P)
    cost_ptr[sidx], parent_ptr[sidx], open_curr_ptr[0] = 0, sidx, sidx
    stats_ptr.curr_count, stats_ptr.next_count, stats_ptr.goal_state, stats_ptr.best_goal_cost, stats_ptr.expanded = 1, 0, 0xFFFFFFFF, INF_COST, 0
    path_count, iter, solution_latched, solution_latched_time, M.last_reset = 0, 0, false, 0.0, M.current_time
end

local function update_occupancy(t)
    for i = 0, NX * NY * NZ - 1 do occupancy_ptr[i] = 0 end
    local sx, sy, sz = world_x(START_X), world_y(START_Y), world_z(START_Z)
    local gx, gy, gz = world_x(GOAL_X), world_y(GOAL_Y), world_z(GOAL_Z)
    marker_count = 0
    set_draw_point(marker_ptr, marker_count, sx, sy, sz, 11.0, 0.2, 1.0, 0.3, 1.0); marker_count = marker_count + 1
    set_draw_point(marker_ptr, marker_count, gx, gy, gz, 12.0, 1.0, 1.0, 0.2, 1.0); marker_count = marker_count + 1
    local obs_count, vx, vy, vz = 12, gx - sx, gy - sy, gz - sz
    local vlen = math.sqrt(vx * vx + vy * vy + vz * vz); if vlen < 1e-6 then vlen = 1 end
    vx, vy, vz = vx / vlen, vy / vlen, vz / vlen
    for i = 0, obs_count - 1 do
        local base = 0.08 + 0.84 * (math.abs(math.sin((i + 1) * 9.173)) % 1.0)
        local along = clamp(base + 0.11 * math.sin(t * (0.33 + 0.03 * i) + i * 0.77), 0.08, 0.92)
        local ox, oy, oz = sx + vx * (vlen * along) + math.sin(t * (0.49 + 0.05 * i) + i * 0.41) * (1.6 + 0.2 * (i % 3)), sy + vy * (vlen * along) + math.cos(t * (0.43 + 0.04 * i) + i * 1.1) * (1.1 + 0.15 * (i % 2)), sz + vz * (vlen * along) + math.cos(t * (0.53 + 0.02 * i) + i * 0.29) * (1.5 + 0.22 * ((i + 1) % 3))
        local rr = 0.7 + 0.08 * (i % 4)
        set_draw_point(marker_ptr, marker_count, ox, oy, oz, rr * 28.0, 1.0, 0.18, 0.18, 0.95); marker_count = marker_count + 1
        local minx, maxx, miny, maxy, minz, maxz = grid_x(ox - rr), grid_x(ox + rr), grid_y(oy - rr), grid_y(oy + rr), grid_z(oz - rr), grid_z(oz + rr)
        for z = minz, maxz do for y = miny, maxy do for x = minx, maxx do if (world_x(x)-ox)^2 + (world_y(y)-oy)^2 + (world_z(z)-oz)^2 <= rr * rr then occupancy_ptr[occ_idx(x, y, z)] = 1 end end end end
    end
end

local function advance_frontier()
    if iter == 0 then return end
    local next_count = tonumber(stats_ptr.next_count); if next_count > MAX_FRONTIER then next_count = MAX_FRONTIER end
    if next_count <= 0 then stats_ptr.curr_count = 0; return end
    for i = 0, next_count - 1 do open_curr_ptr[i] = open_next_ptr[i] end
    stats_ptr.curr_count, stats_ptr.next_count = next_count, 0
end

local function extract_visited_points()
    visited_count = 0
    for z = 0, NZ - 1 do for y = 0, NY - 1 do for x = 0, NX - 1 do
        local best = INF_COST
        for h = 0, NH - 1 do for p = 0, NP - 1 do local c = cost_ptr[idx_state(x, y, z, h, p)]; if c < best then best = c end end end
        if best < INF_COST and visited_count < MAX_VIS_POINTS then
            local t = clamp(best / 1400.0, 0.0, 1.0)
            set_draw_point(vis_ptr, visited_count, world_x(x), world_y(y), world_z(z), 2.0, 0.10, 0.28 + 0.52 * (1.0 - t), 0.82 + 0.16 * (1.0 - t), 0.24); visited_count = visited_count + 1
        end
    end end end
end

local function smooth_path(points)
    if #points < 3 then return points end
    local out = { points[1] }
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        out[#out + 1] = { x = 0.75 * a.x + 0.25 * b.x, y = 0.75 * a.y + 0.25 * b.y, z = 0.75 * a.z + 0.25 * b.z }
        out[#out + 1] = { x = 0.25 * a.x + 0.75 * b.x, y = 0.25 * a.y + 0.75 * b.y, z = 0.25 * a.z + 0.75 * b.z }
    end
    out[#out + 1] = points[#points]; return out
end

local function extract_path()
    path_count = 0
    local gstate = tonumber(stats_ptr.goal_state); if gstate == 0xFFFFFFFF then return end
    local rev = {}; local cur = gstate
    for _ = 1, MAX_PATH_POINTS do
        local x, y, z = decode_state(cur); rev[#rev + 1] = { x = world_x(x), y = world_y(y), z = world_z(z) }
        local p = tonumber(parent_ptr[cur]); if p == 0xFFFFFFFF or p == cur then break end
        cur = p
    end
    local path = {}; for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
    path = smooth_path(path)
    for i = 1, math.min(#path, MAX_PATH_POINTS) do local p = path[i]; set_draw_point(path_ptr, i - 1, p.x, p.y, p.z, 6.5, 3.9, 2.8, 0.35, 0.98); path_count = path_count + 1 end
end

function M.init()
    print("Example 16: Hybrid A* 3D (using mc.gpu StdLib)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct Stats { uint32_t curr_count, next_count, goal_state, best_goal_cost, expanded; } Stats;
        typedef struct DrawPoint { float x, y, z, size, r, g, b, a; } DrawPoint;
        typedef struct GraphPC { float mvp[16]; uint32_t mode, count, pad0, pad1; } GraphPC;
        typedef struct ExpandPC { uint32_t curr_count, nx, ny, nz, nh, np, max_frontier, goal_x, goal_y, goal_z, iter; } ExpandPC;
    ]]

    local cost_size, parent_size, frontier_size, occ_size, stats_size, vis_size, path_size, marker_size = ffi.sizeof("uint32_t") * STATE_COUNT, ffi.sizeof("uint32_t") * STATE_COUNT, ffi.sizeof("uint32_t") * MAX_FRONTIER, ffi.sizeof("uint32_t") * (NX * NY * NZ), ffi.sizeof("Stats"), ffi.sizeof("DrawPoint") * MAX_VIS_POINTS, ffi.sizeof("DrawPoint") * MAX_PATH_POINTS, ffi.sizeof("DrawPoint") * MAX_MARKERS
    local b_cost = mc.buffer(cost_size, "storage", nil, true)
    local b_parent = mc.buffer(parent_size, "storage", nil, true)
    local b_open_curr = mc.buffer(frontier_size, "storage", nil, true)
    local b_open_next = mc.buffer(frontier_size, "storage", nil, true)
    local b_occ = mc.buffer(occ_size, "storage", nil, true)
    local b_stats = mc.buffer(stats_size, "storage", nil, true)
    local b_vis = mc.buffer(vis_size, "storage", nil, true)
    local b_path = mc.buffer(path_size, "storage", nil, true)
    local b_marker = mc.buffer(marker_size, "storage", nil, true)

    cost_ptr, parent_ptr, open_curr_ptr, open_next_ptr, occupancy_ptr, stats_ptr, vis_ptr, path_ptr, marker_ptr = ffi.cast("uint32_t*", b_cost.allocation.ptr), ffi.cast("uint32_t*", b_parent.allocation.ptr), ffi.cast("uint32_t*", b_open_curr.allocation.ptr), ffi.cast("uint32_t*", b_open_next.allocation.ptr), ffi.cast("uint32_t*", b_occ.allocation.ptr), ffi.cast("Stats*", b_stats.allocation.ptr), ffi.cast("DrawPoint*", b_vis.allocation.ptr), ffi.cast("DrawPoint*", b_path.allocation.ptr), ffi.cast("DrawPoint*", b_marker.allocation.ptr)

    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_cost.handle, 0, cost_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_parent.handle, 0, parent_size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_open_curr.handle, 0, frontier_size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_open_next.handle, 0, frontier_size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_occ.handle, 0, occ_size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_stats.handle, 0, stats_size, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_vis.handle, 0, vis_size, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_path.handle, 0, path_size, 7)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, b_marker.handle, 0, marker_size, 8)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), offset = 0, size = ffi.sizeof("GraphPC") }}))
    pipe_expand = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/expand.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    local draw_vert = shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/draw.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/point.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, draw_vert, shader.create_module(device, shader.compile_glsl(read_text("examples/16_hybrid_astar/line.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })

    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pSem); image_available = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cb, planning_cb = command.allocate_buffers(device, pool, 1)[1], command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    reset_search()
end

function M.update()
    local ok, err = pcall(function()
 frame_id = frame_id + 1; M.current_time = M.current_time + 0.016
        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
        update_occupancy(M.current_time)
        if not solution_latched then
            advance_frontier()
            local curr_count = tonumber(stats_ptr.curr_count)
            if curr_count > 0 and curr_count <= MAX_FRONTIER then
                local epc = ffi.new("ExpandPC", { curr_count = curr_count, nx = NX, ny = NY, nz = NZ, nh = NH, np = NP, max_frontier = MAX_FRONTIER, goal_x = GOAL_X, goal_y = GOAL_Y, goal_z = GOAL_Z, iter = iter })
                vk.vkResetCommandBuffer(planning_cb, 0); vk.vkBeginCommandBuffer(planning_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
                vk.vkCmdBindPipeline(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_expand); vk.vkCmdBindDescriptorSets(planning_cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil); vk.vkCmdPushConstants(planning_cb, layout_graph, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("ExpandPC"), epc); vk.vkCmdDispatch(planning_cb, math.ceil(curr_count / 256), 1, 1); vk.vkEndCommandBuffer(planning_cb)
                vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { planning_cb }) }), ffi.cast("VkFence", 0)); iter = iter + 1
            end
        end
        if frame_id % VIS_EXTRACT_PERIOD == 0 or solution_latched then extract_visited_points(); extract_path() end
        if not solution_latched and tonumber(stats_ptr.goal_state) ~= 0xFFFFFFFF then solution_latched, solution_latched_time = true, M.current_time; extract_path() end
        if (M.current_time - M.last_reset > RESET_INTERVAL) or (tonumber(stats_ptr.curr_count) == 0 and not solution_latched) or (solution_latched and (M.current_time - solution_latched_time) > SOLUTION_HOLD_TIME) then reset_search() end
        local idx = sw:acquire_next_image(image_available); if idx == nil then return end
        vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        local view = mc.mat4_look_at({ math.cos(M.angle) * 24.0, 14.0, math.sin(M.angle) * 24.0 }, { 0, 0, 0 }, { 0, 1, 0 })
        local proj = mc.mat4_perspective(math.rad(45), sw.extent.width / sw.extent.height, 0.1, 120.0); local mvp = mc.mat4_multiply(proj, view); M.angle = M.angle + 0.002
        local gpc = ffi.new("GraphPC"); for i = 1, 16 do gpc.mvp[i - 1] = mvp.m[i - 1] end
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }}); vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.01, 0.01, 0.015, 1.0 }
        vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach })); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent })); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        gpc.mode, gpc.count = 0, visited_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, visited_count, 1, 0, 0)
        if path_count > 1 then gpc.mode, gpc.count = 1, path_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines); vk.vkCmdDraw(cb, path_count, 1, 0, 0); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, path_count, 1, 0, 0) end
        gpc.mode, gpc.count = 2, marker_count; vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("GraphPC"), gpc); vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points); vk.vkCmdDraw(cb, marker_count, 1, 0, 0); vk.vkCmdEndRendering(cb)
        bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0; vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
        vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
    end)
    if not ok then print("M.update: ERROR:", err) end
end

return M
