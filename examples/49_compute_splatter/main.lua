local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")
local input = require("mc.input")
local bit = require("bit")

local M = { cam_pos = { 0, 0, 8 }, cam_rot = { 0, 0 }, current_time = 0, last_frame_ticks = 0, fps_frames = 0, fps_timer = 0 }

-- CONFIG
local GAUSSIAN_COUNT = 16384
local MAX_LARGE_SPLATS = 65536

local device, queue, graphics_family, sw, pipe_layout, pipe_binning, pipe_prefix_sum, pipe_raster, pipe_hybrid
local bindless_set, cb, frame_fence, image_available
local storage_r, storage_g, storage_b, storage_img
local large_splat_buf, large_count_buf
local projected_splat_buf, tile_count_buf, tile_offset_buf, tile_current_offset_buf, tile_data_buf
local noise_buf
local graph, sw_res = {}, {}

ffi.cdef([[
    typedef struct Projected {
        float pos[2];
        float depth;
        float pad1;
        float cov[4];
        float color_alpha[4];
        float sh_r[4];
        float sh_g[4];
        float sh_b[4];
        float pad2[8]; // Total 128 bytes
    } Projected;

    typedef struct BinningPC {
        mc_mat4 view;           // 0
        mc_mat4 proj;           // 64
        float focal;            // 128
        uint32_t p_id;          // 132
        uint32_t tc_id;         // 136
        uint32_t to_id;         // 140
        uint32_t count;         // 144
        uint32_t screen_w;      // 148
        uint32_t screen_h;      // 152
        float time;             // 156
        uint32_t noise_id;      // 160
        uint32_t pad1[3];       // 164, 168, 172 -> Pad to 176
        float cam_pos[4];       // 176
        float world_offset[4];  // 192
        uint32_t mode;          // 208
        uint32_t td_id;         // 212
        uint32_t co_id;         // 216
        uint32_t pad2[9];       // 220...
    } BinningPC;

    typedef struct PrefixSumPC {
        uint32_t tc_id;
        uint32_t to_id;
        uint32_t num_tiles;
        uint32_t pad[61];
    } PrefixSumPC;

    typedef struct RasterPC {
        uint32_t p_id;          // 0
        uint32_t tc_id;         // 4
        uint32_t td_id;         // 8
        uint32_t img_id;        // 12
        uint32_t screen_w;      // 16
        uint32_t screen_h;      // 20
        uint32_t to_id;         // 24
        uint32_t pad1;          // 28
        float cam_pos[4];       // 32
        uint32_t pad2[52];
    } RasterPC;

    typedef struct HybridPC {
        mc_mat4 view;
        mc_mat4 proj;
        uint32_t s_id;
        uint32_t pad[31];
    } HybridPC;
]])

function M.init()
	print("Example 49: PACKED TILE-BASED GAUSSIAN SPLATTER")
	local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
	device = vulkan.get_device()
	queue, graphics_family = vulkan.get_queue()
	sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

	-- 1. Resources
	storage_img =
		mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage_color_attachment")

	large_splat_buf = mc.buffer(32 * MAX_LARGE_SPLATS, "storage")
	large_count_buf = mc.buffer(16, "indirect", ffi.new("uint32_t[4]", { 4, 0, 0, 0 }))

	local noise_data = ffi.new("float[1024]")
	for i = 0, 1023 do noise_data[i] = math.random() end
	noise_buf = mc.buffer(1024 * 4, "storage", noise_data)

	local tiles_x, tiles_y = math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16)
	local tile_count = tiles_x * tiles_y
	projected_splat_buf = mc.buffer(GAUSSIAN_COUNT * 3 * 128, "storage")
	tile_count_buf = mc.buffer(tile_count * 4, "storage")
	tile_offset_buf = mc.buffer(tile_count * 4, "storage")
	tile_current_offset_buf = mc.buffer(tile_count * 4, "storage")
	tile_data_buf = mc.buffer(16 * 1024 * 1024 * 4, "storage")

	-- 2. Bindless Setup
	bindless_set = mc.gpu.get_bindless_set()
	local function update_buf(h, sz, slot)
		descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, h, 0, sz, slot)
	end
	update_buf(large_splat_buf.handle, large_splat_buf.size, 0)
	update_buf(large_count_buf.handle, large_count_buf.size, 1)
	update_buf(noise_buf.handle, noise_buf.size, 2)
	update_buf(projected_splat_buf.handle, projected_splat_buf.size, 10)
	update_buf(tile_count_buf.handle, tile_count_buf.size, 11)
	update_buf(tile_offset_buf.handle, tile_offset_buf.size, 12)
	update_buf(tile_data_buf.handle, tile_data_buf.size, 13)
	update_buf(tile_current_offset_buf.handle, tile_current_offset_buf.size, 14)

	descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, storage_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 3)

	-- 3. Pipelines
	pipe_layout = pipeline.create_layout(device, { mc.gpu.get_bindless_layout() }, { { stageFlags = bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), offset = 0, size = 256 } })
	
	local function load_comp(path)
		return pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open(path):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
	end
	pipe_prefix_sum = load_comp("examples/49_compute_splatter/prefix_sum.comp")
	pipe_binning = load_comp("examples/49_compute_splatter/binning.comp")
	pipe_raster = load_comp("examples/49_compute_splatter/raster.comp")

	-- 4. Sync
	cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
	local pF = ffi.new("VkFence[1]")
	vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF)
	frame_fence = pF[0]
	local pS = ffi.new("VkSemaphore[1]")
	vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS)
	image_available = pS[0]

	-- 5. Graph
	local rg = require("vulkan.graph")
	graph = rg.new(device)
	for i = 0, sw.image_count - 1 do sw_res[i] = graph:register_resource("SW_" .. i, rg.TYPE_IMAGE, sw.images[i]) end
	graph.storage = graph:register_resource("StorageImg", rg.TYPE_IMAGE, storage_img.handle)
	graph.projected = graph:register_resource("Projected", rg.TYPE_BUFFER, projected_splat_buf.handle)
	graph.tile_counts = graph:register_resource("TileCounts", rg.TYPE_BUFFER, tile_count_buf.handle)
	graph.tile_offsets = graph:register_resource("TileOffsets", rg.TYPE_BUFFER, tile_offset_buf.handle)
	graph.tile_data = graph:register_resource("TileData", rg.TYPE_BUFFER, tile_data_buf.handle)
	graph.tile_current_offsets = graph:register_resource("TileCurrentOffsets", rg.TYPE_BUFFER, tile_current_offset_buf.handle)
end

function M.update()
	local sdl = require("vulkan.sdl")
	local current_ticks = tonumber(sdl.SDL_GetTicks())
	if M.last_frame_ticks == 0 then M.last_frame_ticks = current_ticks end
	local dt = (current_ticks - M.last_frame_ticks) / 1000.0
	M.last_frame_ticks = current_ticks

	-- FPS Counter Logic
	M.fps_frames = M.fps_frames + 1
	M.fps_timer = M.fps_timer + dt
	if M.fps_timer >= 1.0 then
		local fps = M.fps_frames / M.fps_timer
		local title = string.format("MoonCrust | Splat Renderer | FPS: %.1f | Gaussians: %d", fps, GAUSSIAN_COUNT * 3)
		sdl.SDL_SetWindowTitle(_G._SDL_WINDOW, title)
		M.fps_timer = 0
		M.fps_frames = 0
	end

	vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFF)
	vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
	local idx = sw:acquire_next_image(image_available)
	if idx == nil then return end

	input.tick()
	M.current_time = M.current_time + dt
	local dx, dy = input.mouse_delta()
	if input.mouse_down(3) then
		M.cam_rot[1] = M.cam_rot[1] - dx * 0.005
		M.cam_rot[2] = math.max(-math.pi / 2, math.min(math.pi / 2, M.cam_rot[2] - dy * 0.005))
	end
	local fwd = { math.sin(M.cam_rot[1]) * math.cos(M.cam_rot[2]), math.sin(M.cam_rot[2]), -math.cos(M.cam_rot[1]) * math.cos(M.cam_rot[2]) }
	local right = { math.cos(M.cam_rot[1]), 0, math.sin(M.cam_rot[1]) }
	local speed = 5.0 * dt
	if input.key_down(input.SCANCODE_LSHIFT) then speed = 15.0 * dt end
	if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + fwd[1] * speed, M.cam_pos[2] + fwd[2] * speed, M.cam_pos[3] + fwd[3] * speed end
	if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - fwd[1] * speed, M.cam_pos[2] - fwd[2] * speed, M.cam_pos[3] - fwd[3] * speed end
	if input.key_down(input.SCANCODE_A) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - right[1] * speed, M.cam_pos[2] - right[2] * speed, M.cam_pos[3] - right[3] * speed end
	if input.key_down(input.SCANCODE_D) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + right[1] * speed, M.cam_pos[2] + right[2] * speed, M.cam_pos[3] + right[3] * speed end

	local view = mc.math.mat4_look_at(M.cam_pos, { M.cam_pos[1] + fwd[1], M.cam_pos[2] + fwd[2], M.cam_pos[3] + fwd[3] }, { 0, 1, 0 })
	local aspect = sw.extent.width / sw.extent.height
	local proj = mc.math.mat4_perspective(mc.math.rad(70), aspect, 0.1, 100.0)
	local focal = sw.extent.height / (2.0 * math.tan(mc.math.rad(70) * 0.5))

	vk.vkResetCommandBuffer(cb, 0)
	vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

	vk.vkCmdFillBuffer(cb, tile_count_buf.handle, 0, tile_count_buf.size, 0)
	vk.vkCmdFillBuffer(cb, tile_current_offset_buf.handle, 0, tile_current_offset_buf.size, 0)

	local b_sync = ffi.new("VkBufferMemoryBarrier[2]", {
		{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = tile_count_buf.handle, size = tile_count_buf.size },
		{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = tile_current_offset_buf.handle, size = tile_current_offset_buf.size }
	})
	vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 2, b_sync, 0, nil)

	graph:reset()
	local pc_common = { view = view, proj = proj, focal = focal, p_id = 10, tc_id = 11, to_id = 12, count = GAUSSIAN_COUNT * 3, screen_w = sw.extent.width, screen_h = sw.extent.height, time = M.current_time, noise_id = 2, cam_pos = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 }, world_offset = { 0, 0, 0, 0 } }

	graph:add_pass("BinningCount", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local pc = ffi.new("BinningPC", pc_common)
		pc.mode = 0
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
		vk.vkCmdDispatch(c, math.ceil((GAUSSIAN_COUNT * 3) / 256), 1, 1)
	end):using(graph.projected, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_counts, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

	graph:add_pass("PrefixSum", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_prefix_sum)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local tiles_x, tiles_y = math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16)
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, ffi.new("PrefixSumPC", { tc_id = 11, to_id = 12, num_tiles = tiles_x * tiles_y }))
		vk.vkCmdDispatch(c, 1, 1, 1)
	end):using(graph.tile_counts, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offsets, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

	graph:add_pass("BinningWrite", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local pc = ffi.new("BinningPC", pc_common)
		pc.mode, pc.td_id, pc.co_id = 1, 13, 14
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
		vk.vkCmdDispatch(c, math.ceil((GAUSSIAN_COUNT * 3) / 256), 1, 1)
	end):using(graph.projected, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offsets, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_current_offsets, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_data, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

	graph:add_pass("Raster", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_raster)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local pc = ffi.new("RasterPC", { p_id = 10, tc_id = 11, td_id = 13, img_id = 3, screen_w = sw.extent.width, screen_h = sw.extent.height, to_id = 12, cam_pos = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 } })
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
		vk.vkCmdDispatch(c, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)
	end):using(graph.projected, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_counts, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offsets, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_data, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.storage, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

	graph:add_pass("Blit", function(c)
		local region = ffi.new("VkImageBlit[1]")
		region[0].srcSubresource, region[0].srcOffsets[1], region[0].dstSubresource, region[0].dstOffsets[1] = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }
		vk.vkCmdBlitImage(c, storage_img.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region, vk.VK_FILTER_LINEAR)
	end):using(graph.storage, vk.VK_ACCESS_TRANSFER_READ_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL):using(sw_res[idx], vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)

	graph:add_pass("Present", function(c) end):using(sw_res[idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

	graph:execute(cb)
	vk.vkEndCommandBuffer(cb)
	vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence)
	sw:present(queue, idx, sw.semaphores[idx])
end

return M
