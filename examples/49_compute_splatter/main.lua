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

local M = { cam_pos = { 0, 0, 8 }, cam_rot = { 0, 0 }, current_time = 0, last_frame_ticks = 0 }

-- CONFIG
local GAUSSIAN_COUNT = 16384
local MAX_LARGE_SPLATS = 65536

local device, queue, graphics_family, sw, pipe_layout, pipe_splat, pipe_resolve, pipe_hybrid
local bindless_set, cb, frame_fence, image_available
local storage_r, storage_g, storage_b, storage_img
local large_splat_buf, large_count_buf
local graph, sw_res = {}, {}

ffi.cdef([[
    typedef struct SplatPC {
        mc_mat4 view;
        mc_mat4 proj;
        float focal;
        uint32_t large_s_id, large_c_id, count;
        uint32_t screen_w, screen_h;
        float time;
        uint32_t noise_id;
        uint32_t asset_type;
        uint32_t pad_align[3];
        float world_offset[4];
        uint32_t pad[17];
    } SplatPC;

    typedef struct ResolvePC {
        uint32_t img_id;
        uint32_t screen_w, screen_h;
        uint32_t pad[61];
    } ResolvePC;

    typedef struct HybridPC {
        mc_mat4 view;
        mc_mat4 proj;
        uint32_t s_id;
        uint32_t pad[31];
    } HybridPC;
]])

function M.init()
	print("Example 49: HYBRID COMPUTE/GRAPHICS GAUSSIAN SPLATTER")
	local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
	device = vulkan.get_device()
	queue, graphics_family = vulkan.get_queue()
	sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

	-- 1. Resources
	storage_r = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32_UINT, "storage")
	storage_g = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32_UINT, "storage")
	storage_b = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32_UINT, "storage")
	storage_img =
		mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage_color_attachment")

	large_splat_buf = mc.buffer(32 * MAX_LARGE_SPLATS, "storage") -- vec4, vec4
	large_count_buf = mc.buffer(4, "storage") -- uint32

	-- Permutation Table (Noise Buffer)
	local noise_data = ffi.new("float[1024]")
	for i = 0, 1023 do
		noise_data[i] = math.random()
	end
	noise_buf = mc.buffer(1024 * 4, "storage", noise_data)

	-- 2. Bindless Setup
	bindless_set = mc.gpu.get_bindless_set()
	descriptors.update_buffer_set(
		device,
		bindless_set,
		0,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		large_splat_buf.handle,
		0,
		large_splat_buf.size,
		0
	)
	descriptors.update_buffer_set(
		device,
		bindless_set,
		0,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		large_count_buf.handle,
		0,
		large_count_buf.size,
		1
	)
	descriptors.update_buffer_set(
		device,
		bindless_set,
		0,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		noise_buf.handle,
		0,
		noise_buf.size,
		2
	)

	descriptors.update_storage_image_set(
		device,
		bindless_set,
		2,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		storage_r.view,
		vk.VK_IMAGE_LAYOUT_GENERAL,
		0
	)
	descriptors.update_storage_image_set(
		device,
		bindless_set,
		2,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		storage_g.view,
		vk.VK_IMAGE_LAYOUT_GENERAL,
		1
	)
	descriptors.update_storage_image_set(
		device,
		bindless_set,
		2,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		storage_b.view,
		vk.VK_IMAGE_LAYOUT_GENERAL,
		2
	)
	descriptors.update_storage_image_set(
		device,
		bindless_set,
		2,
		vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		storage_img.view,
		vk.VK_IMAGE_LAYOUT_GENERAL,
		3
	)

	-- 3. Pipelines
	pipe_layout = pipeline.create_layout(
		device,
		{ mc.gpu.get_bindless_layout() },
		ffi.new("VkPushConstantRange[1]", { { stageFlags = vk.VK_SHADER_STAGE_ALL, offset = 0, size = 256 } })
	)
	pipe_splat = pipeline.create_compute_pipeline(
		device,
		pipe_layout,
		shader.create_module(
			device,
			shader.compile_glsl(
				io.open("examples/49_compute_splatter/splat.comp"):read("*all"),
				vk.VK_SHADER_STAGE_COMPUTE_BIT
			)
		)
	)
	pipe_resolve = pipeline.create_compute_pipeline(
		device,
		pipe_layout,
		shader.create_module(
			device,
			shader.compile_glsl(
				io.open("examples/49_compute_splatter/resolve.comp"):read("*all"),
				vk.VK_SHADER_STAGE_COMPUTE_BIT
			)
		)
	)

	pipe_hybrid = pipeline.create_graphics_pipeline(
		device,
		pipe_layout,
		shader.create_module(
			device,
			shader.compile_glsl(
				io.open("examples/49_compute_splatter/hybrid.vert"):read("*all"),
				vk.VK_SHADER_STAGE_VERTEX_BIT
			)
		),
		shader.create_module(
			device,
			shader.compile_glsl(
				io.open("examples/49_compute_splatter/hybrid.frag"):read("*all"),
				vk.VK_SHADER_STAGE_FRAGMENT_BIT
			)
		),
		{
			topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP,
			additive = true,
			color_formats = { vk.VK_FORMAT_R32G32B32A32_SFLOAT },
		}
	)

	-- 4. Sync
	cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
	local pF = ffi.new("VkFence[1]")
	vk.vkCreateFence(
		device,
		ffi.new(
			"VkFenceCreateInfo",
			{ sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags = vk.VK_FENCE_CREATE_SIGNALED_BIT }
		),
		nil,
		pF
	)
	frame_fence = pF[0]
	local pS = ffi.new("VkSemaphore[1]")
	vk.vkCreateSemaphore(
		device,
		ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }),
		nil,
		pS
	)
	image_available = pS[0]

	-- 5. Graph
	local rg = require("vulkan.graph")
	graph = rg.new(device)
	for i = 0, sw.image_count - 1 do
		sw_res[i] = graph:register_resource("SW_" .. i, rg.TYPE_IMAGE, sw.images[i])
	end
	graph.r = graph:register_resource("AtomicR", rg.TYPE_IMAGE, storage_r.handle)
	graph.g = graph:register_resource("AtomicG", rg.TYPE_IMAGE, storage_g.handle)
	graph.b = graph:register_resource("AtomicB", rg.TYPE_IMAGE, storage_b.handle)
	graph.storage = graph:register_resource("StorageImg", rg.TYPE_IMAGE, storage_img.handle)
	graph.l_splats = graph:register_resource("LargeSplats", rg.TYPE_BUFFER, large_splat_buf.handle)
	graph.l_count = graph:register_resource("LargeCount", rg.TYPE_BUFFER, large_count_buf.handle)
end

function M.update()
	local sdl = require("vulkan.sdl")
	local current_ticks = tonumber(sdl.SDL_GetTicks())
	if M.last_frame_ticks == 0 then
		M.last_frame_ticks = current_ticks
	end
	local dt_ms = current_ticks - M.last_frame_ticks

	-- Cap at 60 FPS (approx 16.6ms)
	if dt_ms < 16.6 then
		sdl.SDL_Delay(math.floor(16.6 - dt_ms))
		current_ticks = tonumber(sdl.SDL_GetTicks())
		dt_ms = current_ticks - M.last_frame_ticks
	end
	M.last_frame_ticks = current_ticks
	local dt = dt_ms / 1000.0

	vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFF)
	vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))
	local idx = sw:acquire_next_image(image_available)
	if idx == nil then
		return
	end

	input.tick()
	M.current_time = M.current_time + dt
	local dx, dy = input.mouse_delta()
	if input.mouse_down(3) then
		M.cam_rot[1] = M.cam_rot[1] - dx * 0.005
		M.cam_rot[2] = math.max(-math.pi / 2, math.min(math.pi / 2, M.cam_rot[2] - dy * 0.005))
	end
	local fwd = {
		math.sin(M.cam_rot[1]) * math.cos(M.cam_rot[2]),
		math.sin(M.cam_rot[2]),
		-math.cos(M.cam_rot[1]) * math.cos(M.cam_rot[2]),
	}
	local right = { math.cos(M.cam_rot[1]), 0, math.sin(M.cam_rot[1]) }
	local speed = 5.0 * dt
	if input.key_down(input.SCANCODE_LSHIFT) then
		speed = 15.0 * dt
	end
	if input.key_down(input.SCANCODE_W) then
		M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] =
			M.cam_pos[1] + fwd[1] * speed, M.cam_pos[2] + fwd[2] * speed, M.cam_pos[3] + fwd[3] * speed
	end
	if input.key_down(input.SCANCODE_S) then
		M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] =
			M.cam_pos[1] - fwd[1] * speed, M.cam_pos[2] - fwd[2] * speed, M.cam_pos[3] - fwd[3] * speed
	end
	if input.key_down(input.SCANCODE_A) then
		M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] =
			M.cam_pos[1] - right[1] * speed, M.cam_pos[2] - right[2] * speed, M.cam_pos[3] - right[3] * speed
	end
	if input.key_down(input.SCANCODE_D) then
		M.cam_pos[1], M.cam_pos[2], M.cam_pos[3] =
			M.cam_pos[1] + right[1] * speed, M.cam_pos[2] + right[2] * speed, M.cam_pos[3] + right[3] * speed
	end

	local view = mc.math.mat4_look_at(
		M.cam_pos,
		{ M.cam_pos[1] + fwd[1], M.cam_pos[2] + fwd[2], M.cam_pos[3] + fwd[3] },
		{ 0, 1, 0 }
	)
	local fov = 70
	local aspect = sw.extent.width / sw.extent.height
	local proj = mc.math.mat4_perspective(mc.math.rad(fov), aspect, 0.1, 100.0)
	local focal = sw.extent.height / (2.0 * math.tan(mc.math.rad(fov) * 0.5))

	vk.vkResetCommandBuffer(cb, 0)
	vk.vkBeginCommandBuffer(
		cb,
		ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO })
	)

	-- 1. Clear Atomic and Indirect Data
	local color_zero = ffi.new("VkClearColorValue", { uint32 = { 0, 0, 0, 0 } })
	local sub_range = ffi.new(
		"VkImageSubresourceRange",
		{ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
	)
	local clear_bars = ffi.new("VkImageMemoryBarrier[3]")
	local clear_imgs = { storage_r.handle, storage_g.handle, storage_b.handle }
	for i = 0, 2 do
		clear_bars[i].sType, clear_bars[i].oldLayout, clear_bars[i].newLayout, clear_bars[i].image, clear_bars[i].subresourceRange, clear_bars[i].dstAccessMask =
			vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
			vk.VK_IMAGE_LAYOUT_UNDEFINED,
			vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			clear_imgs[i + 1],
			sub_range,
			vk.VK_ACCESS_TRANSFER_WRITE_BIT
	end
	vk.vkCmdPipelineBarrier(
		cb,
		vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
		vk.VK_PIPELINE_STAGE_TRANSFER_BIT,
		0,
		0,
		nil,
		0,
		nil,
		3,
		clear_bars
	)
	for i = 0, 2 do
		vk.vkCmdClearColorImage(
			cb,
			clear_imgs[i + 1],
			vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			color_zero,
			1,
			sub_range
		)
	end
	vk.vkCmdFillBuffer(cb, large_count_buf.handle, 0, 4, 0) -- Reset large splat counter

	local b_sync = ffi.new(
		"VkBufferMemoryBarrier[1]",
		{
			{
				sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
				srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT,
				dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT,
				buffer = large_count_buf.handle,
				size = 4,
			},
		}
	)
	vk.vkCmdPipelineBarrier(
		cb,
		vk.VK_PIPELINE_STAGE_TRANSFER_BIT,
		vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		0,
		0,
		nil,
		1,
		b_sync,
		0,
		nil
	)
	for i = 0, 2 do
		clear_bars[i].oldLayout, clear_bars[i].newLayout, clear_bars[i].srcAccessMask, clear_bars[i].dstAccessMask =
			vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			vk.VK_IMAGE_LAYOUT_GENERAL,
			vk.VK_ACCESS_TRANSFER_WRITE_BIT,
			vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT
	end
	vk.vkCmdPipelineBarrier(
		cb,
		vk.VK_PIPELINE_STAGE_TRANSFER_BIT,
		vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		0,
		0,
		nil,
		0,
		nil,
		3,
		clear_bars
	)

	graph:reset()

	-- Pass 1: Splatting (Assigns large splats to buffer, atomics small splats)
	graph
		:add_pass("Splat", function(c)
			vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_splat)
			vk.vkCmdBindDescriptorSets(
				c,
				vk.VK_PIPELINE_BIND_POINT_COMPUTE,
				pipe_layout,
				0,
				1,
				ffi.new("VkDescriptorSet[1]", { bindless_set }),
				0,
				nil
			)

			local assets = {
				{ type = 2, offset = { -4, 0, 0, 0 } }, -- Tree (First)
				{ type = 3, offset = { -3, 0, 0, 0 } }, -- Chair (Center)
				{ type = 0, offset = { -2, 0, 0, 0 } }, -- Ghost (Right)
			}

			for _, asset in ipairs(assets) do
				local pc_val = ffi.new("SplatPC", {
					view = view,
					proj = proj,
					focal = focal,
					large_s_id = 0,
					large_c_id = 1,
					count = GAUSSIAN_COUNT,
					screen_w = sw.extent.width,
					screen_h = sw.extent.height,
					time = M.current_time,
					noise_id = 2,
					asset_type = asset.type,
					world_offset = asset.offset,
				})
				vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 256, pc_val)
				vk.vkCmdDispatch(c, math.ceil(GAUSSIAN_COUNT / 256), 1, 1)
			end
		end)
		:using(
			graph.r,
			vk.VK_ACCESS_SHADER_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(
			graph.g,
			vk.VK_ACCESS_SHADER_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(
			graph.b,
			vk.VK_ACCESS_SHADER_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(graph.l_splats, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
		:using(
			graph.l_count,
			vk.VK_ACCESS_SHADER_WRITE_BIT + vk.VK_ACCESS_SHADER_READ_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT
		)

	-- Pass 2: Resolve and Render Hybrid Large Splats
	graph
		:add_pass("Resolve", function(c)
			vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_resolve)
			vk.vkCmdBindDescriptorSets(
				c,
				vk.VK_PIPELINE_BIND_POINT_COMPUTE,
				pipe_layout,
				0,
				1,
				ffi.new("VkDescriptorSet[1]", { bindless_set }),
				0,
				nil
			)
			local pc = ffi.new("ResolvePC", { img_id = 3, screen_w = sw.extent.width, screen_h = sw.extent.height })
			vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 256, pc)
			vk.vkCmdDispatch(c, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)
		end)
		:using(
			graph.r,
			vk.VK_ACCESS_SHADER_READ_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(
			graph.g,
			vk.VK_ACCESS_SHADER_READ_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(
			graph.b,
			vk.VK_ACCESS_SHADER_READ_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)
		:using(
			graph.storage,
			vk.VK_ACCESS_SHADER_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
			vk.VK_IMAGE_LAYOUT_GENERAL
		)

	graph
		:add_pass("LargeSplats", function(c)
			local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
			color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout =
				vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
				storage_img.view,
				vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
			color_attach[0].loadOp, color_attach[0].storeOp =
				vk.VK_ATTACHMENT_LOAD_OP_LOAD, vk.VK_ATTACHMENT_STORE_OP_STORE
			vk.vkCmdBeginRendering(
				c,
				ffi.new(
					"VkRenderingInfo",
					{
						sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
						renderArea = { extent = sw.extent },
						layerCount = 1,
						colorAttachmentCount = 1,
						pColorAttachments = color_attach,
					}
				)
			)
			vk.vkCmdSetViewport(
				c,
				0,
				1,
				ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 })
			)
			vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
			vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_hybrid)
			vk.vkCmdBindDescriptorSets(
				c,
				vk.VK_PIPELINE_BIND_POINT_GRAPHICS,
				pipe_layout,
				0,
				1,
				ffi.new("VkDescriptorSet[1]", { bindless_set }),
				0,
				nil
			)
			local pc = ffi.new("HybridPC", { view = view, proj = proj, s_id = 0 })
			vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_ALL, 0, 256, pc)
			-- Indirect draw from the counter buffer
			vk.vkCmdDrawIndirect(c, large_count_buf.handle, 0, 1, 16)
			vk.vkCmdEndRendering(c)
		end)
		:using(
			graph.storage,
			vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
			vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
		)
		:using(graph.l_splats, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
		:using(graph.l_count, vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT)

	-- Pass 3: Blit
	graph
		:add_pass("Blit", function(c)
			local region = ffi.new("VkImageBlit[1]")
			region[0].srcSubresource, region[0].srcOffsets[1], region[0].dstSubresource, region[0].dstOffsets[1] =
				{ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 },
				{ x = sw.extent.width, y = sw.extent.height, z = 1 },
				{ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 },
				{ x = sw.extent.width, y = sw.extent.height, z = 1 }
			vk.vkCmdBlitImage(
				c,
				storage_img.handle,
				vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				ffi.cast("VkImage", sw.images[idx]),
				vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				1,
				region,
				vk.VK_FILTER_LINEAR
			)
		end)
		:using(
			graph.storage,
			vk.VK_ACCESS_TRANSFER_READ_BIT,
			vk.VK_PIPELINE_STAGE_TRANSFER_BIT,
			vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
		)
		:using(
			sw_res[idx],
			vk.VK_ACCESS_TRANSFER_WRITE_BIT,
			vk.VK_PIPELINE_STAGE_TRANSFER_BIT,
			vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
		)

	graph
		:add_pass("Present", function(c) end)
		:using(sw_res[idx], 0, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

	graph:execute(cb)
	vk.vkEndCommandBuffer(cb)
	vk.vkQueueSubmit(
		queue,
		1,
		ffi.new(
			"VkSubmitInfo",
			{
				sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
				waitSemaphoreCount = 1,
				pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }),
				pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT }),
				commandBufferCount = 1,
				pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }),
				signalSemaphoreCount = 1,
				pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }),
			}
		),
		frame_fence
	)
	sw:present(queue, idx, sw.semaphores[idx])
end

return M
