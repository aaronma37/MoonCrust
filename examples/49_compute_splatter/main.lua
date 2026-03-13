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
local GAUSSIAN_COUNT = 32768
local MAX_SORT_COUNT = 524288 -- Increased for better coverage
local TILE_SIZE = 16
local NUM_TILES_X = math.ceil(1280 / TILE_SIZE) -- Fixed for now, will dynamic
local NUM_TILES_Y = math.ceil(720 / TILE_SIZE)
local TOTAL_TILES = NUM_TILES_X * NUM_TILES_Y

local device, queue, graphics_family, sw, pipe_layout, pipe_project, pipe_raster, pipe_sort, pipe_cluster
local bindless_set, cb, frame_fence, image_available
local storage_img
local projected_splat_buf, cull_data_buf, sort_buf, sort_buf_alt, tile_count_buf, tile_offset_buf, bin_buf, count_buf, histogram_buf
local graph, sw_res = {}, {}

ffi.cdef([[
    typedef struct Projected {
        float pos[2];
        uint32_t depth_key; 
        float pad1;
        float cov[4];
        float color_alpha[4];
        float sh_r[4];
        float sh_g[4];
        float sh_b[4];
        float world_pos[4];
        float pad2[4]; 
    } Projected;

    typedef struct CullData {
        float pos[2];
        float radius;
        uint32_t pad;
    } CullData;

    typedef struct TileRange {
        uint32_t start;
        uint32_t count;
    } TileRange;

    typedef struct ProjectPC {
        mc_mat4 view;
        mc_mat4 proj;
        float focal;
        uint32_t p_id, s_id, c_id, count;
        float time;
        uint32_t noise_id;
        uint32_t count_id;
        uint32_t pad0;
        float cam_pos[4];
        float light_dir[4];
        float world_offset[4];
        uint32_t pad[10];
    } ProjectPC;

    typedef struct BinningPC {
        uint32_t s_id, c_id, tc_id, to_id, b_id, count;
        uint32_t screen_w, screen_h, tiles_x, tiles_y, scatter_mode;
        uint32_t pad[53];
    } BinningPC;

    typedef struct SortPC {
        uint32_t buf_id;
        uint32_t alt_id;
        uint32_t hist_id;
        uint32_t pass;
        uint32_t count;
        uint32_t pad[59];
    } SortPC;

    typedef struct RasterPC {
        uint32_t p_id, s_id, b_id, tr_id;
        uint32_t img_id, screen_w, screen_h, count;
        float cam_pos[4];
        float light_dir[4];
        uint32_t pad[40];
    } RasterPC;
]])

function M.init()
	print("Example 49: TILE-BASED RADIX SPLATTER")
	local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
	device = vulkan.get_device()
	queue, graphics_family = vulkan.get_queue()
	sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    NUM_TILES_X = math.ceil(sw.extent.width / TILE_SIZE)
    NUM_TILES_Y = math.ceil(sw.extent.height / TILE_SIZE)
    TOTAL_TILES = NUM_TILES_X * NUM_TILES_Y

	storage_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage_color_attachment")
	noise_buf = mc.buffer(1024 * 4, "storage")
	projected_splat_buf = mc.buffer(GAUSSIAN_COUNT * 3 * 160, "storage")
	cull_data_buf = mc.buffer(MAX_SORT_COUNT * 16, "storage")
	sort_buf = mc.buffer(MAX_SORT_COUNT * 8, "storage")
	sort_buf_alt = mc.buffer(MAX_SORT_COUNT * 8, "storage")
    
    tile_count_buf = mc.buffer(TOTAL_TILES * 4, "storage")
    tile_offset_buf = mc.buffer(TOTAL_TILES * 8, "storage")
    bin_buf = mc.buffer(MAX_SORT_COUNT * 16, "storage") -- Global bin storage

	count_buf = mc.buffer(16 * 4, "storage") -- Atomic counters
	histogram_buf = mc.buffer(256 * 4, "storage") -- 256 buckets for Radix

	bindless_set = mc.gpu.get_bindless_set()
	local function update_buf(h, sz, slot)
		descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, h, 0, sz, slot)
	end
	update_buf(noise_buf.handle, noise_buf.size, 2)
	update_buf(projected_splat_buf.handle, projected_splat_buf.size, 10)
	update_buf(cull_data_buf.handle, cull_data_buf.size, 11)
	update_buf(tile_count_buf.handle, tile_count_buf.size, 12)
    update_buf(tile_offset_buf.handle, tile_offset_buf.size, 13)
    update_buf(bin_buf.handle, bin_buf.size, 14)

	update_buf(sort_buf.handle, sort_buf.size, 15)
	update_buf(count_buf.handle, count_buf.size, 16)
	update_buf(sort_buf_alt.handle, sort_buf_alt.size, 17)
	update_buf(histogram_buf.handle, histogram_buf.size, 18)

	descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, storage_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 3)

	pipe_layout = pipeline.create_layout(device, { mc.gpu.get_bindless_layout() }, { { stageFlags = bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), offset = 0, size = 256 } })
	
	local function load_comp(path)
		return pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open(path):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
	end
	pipe_project = load_comp("examples/49_compute_splatter/binning.comp") 
	pipe_raster = load_comp("examples/49_compute_splatter/raster.comp")
	pipe_sort = load_comp("examples/49_compute_splatter/global_sort.comp")
	pipe_binning = load_comp("examples/49_compute_splatter/binning_tiles.comp") 
    pipe_identify = load_comp("examples/49_compute_splatter/identify_ranges.comp")
	pipe_prefix_sum = load_comp("examples/49_compute_splatter/prefix_sum.comp") 

	pipe_radix_hist = load_comp("examples/49_compute_splatter/radix_histogram.comp")
	pipe_radix_scatter = load_comp("examples/49_compute_splatter/radix_scatter.comp")
	
	local rg = require("vulkan.graph")
	graph = rg.new(device)
	for i = 0, sw.image_count - 1 do sw_res[i] = graph:register_resource("SW_" .. i, rg.TYPE_IMAGE, sw.images[i]) end
	graph.storage = graph:register_resource("StorageImg", rg.TYPE_IMAGE, storage_img.handle)
	graph.projected = graph:register_resource("Projected", rg.TYPE_BUFFER, projected_splat_buf.handle)
	graph.cull = graph:register_resource("CullData", rg.TYPE_BUFFER, cull_data_buf.handle)
	graph.tile_count = graph:register_resource("TileCount", rg.TYPE_BUFFER, tile_count_buf.handle)
    graph.tile_offset = graph:register_resource("TileOffset", rg.TYPE_BUFFER, tile_offset_buf.handle)
    graph.bin = graph:register_resource("BinBuf", rg.TYPE_BUFFER, bin_buf.handle)
	graph.sort = graph:register_resource("SortBuf", rg.TYPE_BUFFER, sort_buf.handle)
	graph.sort_alt = graph:register_resource("SortBufAlt", rg.TYPE_BUFFER, sort_buf_alt.handle)
	graph.count = graph:register_resource("CountBuf", rg.TYPE_BUFFER, count_buf.handle)
	graph.histogram = graph:register_resource("Histogram", rg.TYPE_BUFFER, histogram_buf.handle)

	cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
	local pF = ffi.new("VkFence[1]")
	vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF)
	frame_fence = pF[0]
	local pS = ffi.new("VkSemaphore[1]")
	vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pS)
	image_available = pS[0]
end

function M.update()
	local sdl = require("vulkan.sdl")
	local current_ticks = tonumber(sdl.SDL_GetTicks())
	if M.last_frame_ticks == 0 then M.last_frame_ticks = current_ticks end
	local dt = (current_ticks - M.last_frame_ticks) / 1000.0
	M.last_frame_ticks = current_ticks

	M.fps_frames = M.fps_frames + 1
	M.fps_timer = M.fps_timer + dt
	if M.fps_timer >= 1.0 then
		local fps = M.fps_frames / M.fps_timer
		local title = string.format("MoonCrust | Clustered Binless | FPS: %.1f | Gaussians: %d", fps, GAUSSIAN_COUNT * 3)
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

	local lt = M.current_time * 1.5
	local light_dir = { math.sin(lt), 0.5, math.cos(lt), 0 }

	vk.vkResetCommandBuffer(cb, 0)
	vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

	vk.vkCmdFillBuffer(cb, sort_buf.handle, 0, sort_buf.size, 0xFFFFFFFF) 
	vk.vkCmdFillBuffer(cb, count_buf.handle, 0, count_buf.size, 0)
    vk.vkCmdFillBuffer(cb, tile_count_buf.handle, 0, tile_count_buf.size, 0)

	local b_sync = ffi.new("VkBufferMemoryBarrier[3]", { 
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = sort_buf.handle, size = sort_buf.size },
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = count_buf.handle, size = count_buf.size },
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = tile_count_buf.handle, size = tile_count_buf.size }
    })
	vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 3, b_sync, 0, nil)

	graph:reset()
	
	graph:add_pass("Project", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_project)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local pc = ffi.new("ProjectPC", { view = view, proj = proj, focal = focal, p_id = 10, s_id = 15, c_id = 11, count = GAUSSIAN_COUNT * 3, time = M.current_time, noise_id = 2, count_id = 16, cam_pos = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 }, light_dir = light_dir, world_offset = { 0, 0, 0, 0 } })
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
		vk.vkCmdDispatch(c, math.ceil((GAUSSIAN_COUNT * 3) / 256), 1, 1)
	end):using(graph.projected, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.cull, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.sort, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.count, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

	graph:add_pass("GlobalSort", function(c)
		local pc = ffi.new("SortPC", { buf_id = 15, alt_id = 17, hist_id = 18, count = MAX_SORT_COUNT })
		for pass = 0, 3 do
			vk.vkCmdFillBuffer(c, histogram_buf.handle, 0, histogram_buf.size, 0)
			local h_sync = ffi.new("VkBufferMemoryBarrier[1]", { { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = histogram_buf.handle, size = histogram_buf.size } })
			vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, h_sync, 0, nil)

			pc.pass = pass
			vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
			vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)

			vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_radix_hist)
			vk.vkCmdDispatch(c, MAX_SORT_COUNT / 256, 1, 1)
			local hist_sync = ffi.new("VkBufferMemoryBarrier[1]", { { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, buffer = histogram_buf.handle, size = histogram_buf.size } })
			vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, hist_sync, 0, nil)

            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_prefix_sum)
            vk.vkCmdDispatch(c, 1, 1, 1) 
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, hist_sync, 0, nil)

			vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_radix_scatter)
			vk.vkCmdDispatch(c, MAX_SORT_COUNT / 256, 1, 1)
			
			pc.buf_id, pc.alt_id = pc.alt_id, pc.buf_id
			local b_sync = ffi.new("VkBufferMemoryBarrier[2]", { 
				{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, buffer = sort_buf.handle, size = sort_buf.size },
				{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, buffer = sort_buf_alt.handle, size = sort_buf_alt.size }
			})
			vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 2, b_sync, 0, nil)
		end
	end):using(graph.sort, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.sort_alt, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.histogram, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("BinningTiles", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        local pc = ffi.new("BinningPC", { s_id = 15, c_id = 11, tc_id = 12, to_id = 13, b_id = 14, count = MAX_SORT_COUNT, screen_w = sw.extent.width, screen_h = sw.extent.height, tiles_x = NUM_TILES_X, tiles_y = NUM_TILES_Y, scatter_mode = 0 })
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
        vk.vkCmdDispatch(c, math.ceil(MAX_SORT_COUNT / 256), 1, 1)
    end):using(graph.sort, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.cull, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_count, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("IdentifyRanges", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_identify)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        local pc = ffi.new("BinningPC", { tc_id = 12, to_id = 13, count = TOTAL_TILES })
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
        vk.vkCmdDispatch(c, 1, 1, 1) 
    end):using(graph.tile_count, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offset, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("BinningScatter", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        local pc = ffi.new("BinningPC", { s_id = 15, c_id = 11, tc_id = 12, to_id = 13, b_id = 14, count = MAX_SORT_COUNT, screen_w = sw.extent.width, screen_h = sw.extent.height, tiles_x = NUM_TILES_X, tiles_y = NUM_TILES_Y, scatter_mode = 1 })
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
        vk.vkCmdDispatch(c, math.ceil(MAX_SORT_COUNT / 256), 1, 1)
    end):using(graph.sort, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offset, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.bin, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

	graph:add_pass("Raster", function(c)
		vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_raster)
		vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
		local pc = ffi.new("RasterPC", { p_id = 10, s_id = 15, b_id = 14, tr_id = 13, img_id = 3, screen_w = sw.extent.width, screen_h = sw.extent.height, count = MAX_SORT_COUNT, cam_pos = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 }, light_dir = light_dir })
		vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, pc)
		vk.vkCmdDispatch(c, NUM_TILES_X, NUM_TILES_Y, 1)
	end):using(graph.projected, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.tile_offset, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.bin, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT):using(graph.storage, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)


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
