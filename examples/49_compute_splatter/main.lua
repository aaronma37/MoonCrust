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
local MAX_SORT_COUNT = 131072 
local TILE_SIZE = 16
local NUM_TILES_X = 1280 / TILE_SIZE
local NUM_TILES_Y = 720 / TILE_SIZE
local TOTAL_TILES = NUM_TILES_X * NUM_TILES_Y

local device, queue, graphics_family, sw, pipe_layout
local pipe_project, pipe_raster, pipe_sort, pipe_binning, pipe_identify, pipe_prefix_sum, pipe_radix_hist, pipe_radix_scatter
local bindless_set, cb, frame_fence, image_available
local storage_img, noise_buf, projected_splat_buf, cull_data_buf, sort_buf, sort_buf_alt, tile_count_buf, tile_offset_buf, bin_buf, count_buf, histogram_buf

ffi.cdef([[
    typedef struct ProjectPC {
        mc_mat4 view;
        mc_mat4 proj;
        float focal;
        uint32_t p_id, s_id, c_id, count;
        float time;
        uint32_t noise_id, count_id, hist_id;
        uint32_t pad_sh[3]; // 16-byte alignment for vec4
        float cam_pos[4];
        float light_dir[4];
        float world_offset[4];
        uint32_t pad[7];
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

local project_pc = ffi.new("ProjectPC")
local binning_pc = ffi.new("BinningPC")
local sort_pc = ffi.new("SortPC")
local raster_pc = ffi.new("RasterPC")

function M.init()
	print("Example 49: ULTRA-OPTIMIZED COMPUTE SPLATTER")
	local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
	device = vulkan.get_device()
	queue, graphics_family = vulkan.get_queue()
	sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    NUM_TILES_X = math.ceil(sw.extent.width / TILE_SIZE)
    NUM_TILES_Y = math.ceil(sw.extent.height / TILE_SIZE)
    TOTAL_TILES = NUM_TILES_X * NUM_TILES_Y

	storage_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage_color_attachment")
	noise_buf = mc.buffer(1024 * 4, "storage")
	projected_splat_buf = mc.buffer(MAX_SORT_COUNT * 160, "storage")
	cull_data_buf = mc.buffer(MAX_SORT_COUNT * 16, "storage")
	sort_buf = mc.buffer(MAX_SORT_COUNT * 8, "storage")
	sort_buf_alt = mc.buffer(MAX_SORT_COUNT * 8, "storage")
    tile_count_buf = mc.buffer(TOTAL_TILES * 4, "storage")
    tile_offset_buf = mc.buffer(TOTAL_TILES * 8, "storage")
    bin_buf = mc.buffer(MAX_SORT_COUNT * 64, "storage") 
	count_buf = mc.buffer(16 * 4, "storage") 
	histogram_buf = mc.buffer(256 * 4, "storage") 

	bindless_set = mc.gpu.get_bindless_set()
	local function update_buf(h, sz, slot) descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, h, 0, sz, slot) end
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
	local function load_comp(path) return pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open(path):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT))) end
	pipe_project = load_comp("examples/49_compute_splatter/binning.comp") 
	pipe_raster = load_comp("examples/49_compute_splatter/raster.comp")
	pipe_prefix_sum = load_comp("examples/49_compute_splatter/prefix_sum.comp") 
	pipe_radix_scatter = load_comp("examples/49_compute_splatter/radix_scatter.comp")
	pipe_binning = load_comp("examples/49_compute_splatter/binning_tiles.comp") 
    pipe_identify = load_comp("examples/49_compute_splatter/identify_ranges.comp")

	cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]

    -- INITIAL LAYOUT TRANSITION
    command.encode(cb, function(cmd)
        local barrier = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            srcAccessMask = 0,
            dstAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_GENERAL,
            image = storage_img.handle,
            subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
        }})
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, barrier)
    end)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }) }), nil)
    vk.vkQueueWaitIdle(queue)

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
		sdl.SDL_SetWindowTitle(_G._SDL_WINDOW, string.format("MoonCrust | NAKED PIPELINE | FPS: %.1f", fps))
		M.fps_timer, M.fps_frames = 0, 0
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
	local speed = (input.key_down(input.SCANCODE_LSHIFT) and 15.0 or 5.0) * dt
	if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + fwd[1] * speed, M.cam_pos[2] + fwd[2] * speed, M.cam_pos[3] + fwd[3] * speed end
	if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - fwd[1] * speed, M.cam_pos[2] - fwd[2] * speed, M.cam_pos[3] - fwd[3] * speed end
	if input.key_down(input.SCANCODE_A) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] - right[1] * speed, M.cam_pos[2] - right[2] * speed, M.cam_pos[3] - right[3] * speed end
	if input.key_down(input.SCANCODE_D) then M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] = M.cam_pos[1] + right[1] * speed, M.cam_pos[2] + right[2] * speed, M.cam_pos[3] + right[3] * speed end

	local view = mc.math.mat4_look_at(M.cam_pos, { M.cam_pos[1] + fwd[1], M.cam_pos[2] + fwd[2], M.cam_pos[3] + fwd[3] }, { 0, 1, 0 })
	local aspect = sw.extent.width / sw.extent.height
	local proj = mc.math.mat4_perspective(mc.math.rad(70), aspect, 0.1, 100.0)
	local focal = sw.extent.height / (2.0 * math.tan(mc.math.rad(70) * 0.5))
	local light_dir = { math.sin(M.current_time * 1.5), 0.5, math.cos(M.current_time * 1.5), 0 }

    command.encode(cb, function(cmd)
        -- 0. CLEAR COUNTERS & INVALIDATE SORT ENTRIES
        vk.vkCmdFillBuffer(cmd.buffer, count_buf.handle, 0, count_buf.size, 0)
        vk.vkCmdFillBuffer(cmd.buffer, tile_count_buf.handle, 0, tile_count_buf.size, 0)
        vk.vkCmdFillBuffer(cmd.buffer, histogram_buf.handle, 0, histogram_buf.size, 0)
        vk.vkCmdFillBuffer(cmd.buffer, sort_buf.handle, 0, sort_buf.size, 0xFFFFFFFF)
        
        local clear_barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT) }})
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, clear_barrier, 0, nil, 0, nil)

        -- 1. PROJECT
        project_pc.view, project_pc.proj, project_pc.focal = view, proj, focal
        project_pc.p_id, project_pc.s_id, project_pc.c_id, project_pc.count = 10, 15, 11, GAUSSIAN_COUNT * 3
        project_pc.time, project_pc.noise_id, project_pc.count_id, project_pc.hist_id = M.current_time, 2, 16, 18
        project_pc.cam_pos, project_pc.light_dir, project_pc.world_offset = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 }, light_dir, { 0, 0, 0, 0 }
        
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_project)
        vk.vkCmdBindDescriptorSets(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, project_pc)
        vk.vkCmdDispatch(cmd.buffer, math.ceil((GAUSSIAN_COUNT * 3) / 256), 1, 1)

        local full_barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT) }})
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)

        -- 2. SORT (1-Pass Radix: Most Significant 8 bits)
        sort_pc.buf_id, sort_pc.alt_id, sort_pc.hist_id, sort_pc.pass, sort_pc.count = 15, 17, 18, 3, GAUSSIAN_COUNT * 3
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_prefix_sum)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, sort_pc)
        vk.vkCmdDispatch(cmd.buffer, 1, 1, 1)
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)
        
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_radix_scatter)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, sort_pc)
        vk.vkCmdDispatch(cmd.buffer, math.ceil(sort_pc.count / 512), 1, 1)
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)

        -- 3. BINNING (Pre-pass to count tile splats)
        binning_pc.s_id, binning_pc.c_id, binning_pc.tc_id, binning_pc.to_id, binning_pc.b_id = 17, 11, 12, 13, 14
        binning_pc.count, binning_pc.screen_w, binning_pc.screen_h = GAUSSIAN_COUNT * 3, sw.extent.width, sw.extent.height
        binning_pc.tiles_x, binning_pc.tiles_y, binning_pc.scatter_mode = NUM_TILES_X, NUM_TILES_Y, 0
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, binning_pc)
        vk.vkCmdDispatch(cmd.buffer, math.ceil(binning_pc.count / 256), 1, 1)
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)

        -- 4. RANGE IDENTIFICATION
        binning_pc.count = TOTAL_TILES 
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_identify)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, binning_pc)
        vk.vkCmdDispatch(cmd.buffer, 1, 1, 1)
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)

        -- 5. BINNING (Scatter-pass to fill tile splat lists)
        binning_pc.count = GAUSSIAN_COUNT * 3 
        binning_pc.scatter_mode = 1
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_binning)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, binning_pc)
        vk.vkCmdDispatch(cmd.buffer, math.ceil(binning_pc.count / 256), 1, 1)
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, full_barrier, 0, nil, 0, nil)

        -- 6. RASTER
        raster_pc.p_id, raster_pc.s_id, raster_pc.b_id, raster_pc.tr_id, raster_pc.img_id = 10, 17, 14, 13, 3
        raster_pc.screen_w, raster_pc.screen_h, raster_pc.count = sw.extent.width, sw.extent.height, GAUSSIAN_COUNT * 3
        raster_pc.cam_pos, raster_pc.light_dir = { M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 0 }, light_dir
        vk.vkCmdBindPipeline(cmd.buffer, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_raster)
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, 256, raster_pc)
        vk.vkCmdDispatch(cmd.buffer, NUM_TILES_X, NUM_TILES_Y, 1)

        -- 6. BLIT (Manual)
        local image_barrier = ffi.new("VkImageMemoryBarrier[2]", {
            { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_TRANSFER_READ_BIT, oldLayout = vk.VK_IMAGE_LAYOUT_GENERAL, newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, image = storage_img.handle, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 } },
            { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 } }
        })
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 2, image_barrier)

        local region = ffi.new("VkImageBlit[1]")
        region[0].srcSubresource, region[0].srcOffsets[1], region[0].dstSubresource, region[0].dstOffsets[1] = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }
        vk.vkCmdBlitImage(cmd.buffer, storage_img.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region, vk.VK_FILTER_LINEAR)

        local present_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = 0, oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 } }})
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, present_barrier)
    end)

	vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence)
	sw:present(queue, idx, sw.semaphores[idx])
end

return M
