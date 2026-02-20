local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local sdl = require("vulkan.sdl")
local bit = require("bit")

local M = {
    current_time = 0,
    audio_time = 0,
}

local SAMPLE_RATE = 44100
local CHUNK_SIZE = 1024 
local TOTAL_SAMPLES = CHUNK_SIZE * 8

local device, queue, graphics_family, sw
local pipe_audio, pipe_vis, layout_graph, bindless_set
local audio_buf, waveguide_buf, audio_stream, image_available, cb, frame_fence, audio_fence
local audio_host_ptr
local frame_no = 0

function M.init()
    print("Example 24: ROBUST PHYSICAL AUDIO")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    local spec = ffi.new("SDL_AudioSpec", { format = sdl.SDL_AUDIO_F32, channels = 1, freq = SAMPLE_RATE })
    audio_stream = sdl.SDL_OpenAudioDeviceStream(sdl.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, spec, nil, nil)
    if audio_stream then sdl.SDL_ResumeAudioStreamDevice(audio_stream) end

    audio_buf = mc.buffer(TOTAL_SAMPLES * 4, "storage", nil, true)
    audio_host_ptr = ffi.cast("float*", audio_buf.allocation.ptr)
    waveguide_buf = mc.buffer(65536 * 4, "storage", nil, false)

    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, audio_buf.handle, 0, audio_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, waveguide_buf.handle, 0, waveguide_buf.size, 1)

    ffi.cdef[[
        typedef struct AudioPC {
            float time, morph, lfo_freq, lfo_depth, noise_mix, grain_mix, res_freq, res_feedback, formant_f, grit, sample_rate;
            uint32_t sample_offset, count;
            float freq;
        } AudioPC;
        typedef struct VisPC { uint32_t buffer_id, count; float time, pad; } VisPC;
    ]]

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{ stageFlags = 0x7FFFFFFF, offset = 0, size = 64 }}))
    pipe_audio = pipeline.create_compute_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/24_neuro_audio/audio.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_vis = pipeline.create_graphics_pipeline(device, layout_graph, shader.create_module(device, shader.compile_glsl(io.open("examples/24_neuro_audio/vis.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/24_neuro_audio/vis.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST })

    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    
    -- SEPARATE FENCES to prevent deadlock
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, pF); frame_fence = pF[0]
    local pAF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=0}), nil, pAF); audio_fence = pAF[0]
    
    local pS = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, pS); image_available = pS[0]
end

local chunk_idx, roar_t, bark_t = 0, 0, 0
local params = { freq = 20, grit = 0.1, res_fb = 0.1, morph = 0, noise = 0 }

function M.update()
    -- 1. FRAME THROTTLING (Graphics Fence)
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

    frame_no = frame_no + 1
    M.current_time = M.current_time + 0.016
    
    local keys = sdl.SDL_GetKeyboardState(nil)
    if keys[sdl.SDL_SCANCODE_SPACE] ~= 0 and roar_t <= 0 then roar_t = 4.0; print("DRAGON ROAR!") end
    if keys[sdl.SDL_SCANCODE_A] ~= 0 and bark_t <= 0 then bark_t = 0.5; print("DOG BARK!") end

    if roar_t > 0 then
        local t = 1.0 - (roar_t / 4.0); roar_t = roar_t - 0.016
        params.freq = 40 * math.exp(-t * 3.0) + 25
        params.grit = 0.9 * math.sin(t * 3.14 * 0.5)
        params.res_fb = 0.95
        params.morph = t
        params.noise = 0.4
    elseif bark_t > 0 then
        local t = 1.0 - (bark_t / 0.5); bark_t = bark_t - 0.016
        params.freq = 150 * math.exp(-t * 10.0) + 80
        params.grit = 0.8 * (1.0 - t)
        params.res_fb = 0.4
        params.morph = 0.2
        params.noise = 0.2
    else
        params.freq = 15; params.grit = 0.02; params.res_fb = math.max(0.1, params.res_fb * 0.95); params.noise = 0
    end

    -- 2. AUDIO COMPUTE (Audio Fence)
    if audio_stream and sdl.SDL_GetAudioStreamQueued(audio_stream) < CHUNK_SIZE * 8 then
        local offset = chunk_idx * CHUNK_SIZE
        local apc = ffi.new("AudioPC", { time = M.audio_time, sample_offset = offset, count = CHUNK_SIZE, sample_rate = SAMPLE_RATE, freq = params.freq, morph = params.morph, grit = params.grit, noise_mix = params.noise, res_feedback = params.res_fb })
        
        vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_audio)
        vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
        vk.vkCmdPushConstants(cb, layout_graph, 0x7FFFFFFF, 0, 64, apc)
        vk.vkCmdDispatch(cb, math.ceil(CHUNK_SIZE / 256), 1, 1)
        
        local b = ffi.new("VkBufferMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT, buffer = audio_buf.handle, size = audio_buf.size }})
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, 0, 0, nil, 1, b, 0, nil)
        vk.vkEndCommandBuffer(cb)
        
        -- Submit with AUDIO FENCE
        vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }) }), audio_fence)
        
        -- Wait for AUDIO FENCE (Sync CPU to GPU Audio)
        vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { audio_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
        vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { audio_fence }))
        
        sdl.SDL_PutAudioStreamData(audio_stream, audio_host_ptr + offset, CHUNK_SIZE * 4)
        M.audio_time = M.audio_time + CHUNK_SIZE / SAMPLE_RATE; chunk_idx = (chunk_idx + 1) % 8
    end

    -- 3. GRAPHICS RENDER
    local idx = sw:acquire_next_image(image_available)
    if idx == nil then return end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, { 0.01, 0.01, 0.02, 1 }
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width = sw.extent.width, height = sw.extent.height, maxDepth = 1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_vis); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    local vpc = ffi.new("VisPC", { buffer_id = 0, count = TOTAL_SAMPLES, time = M.current_time })
    vk.vkCmdPushConstants(cb, layout_graph, 0x7FFFFFFF, 0, 16, vpc); vk.vkCmdDraw(cb, TOTAL_SAMPLES, 1, 0, 0); vk.vkCmdEndRendering(cb)
    bar[0].oldLayout, bar[0].newLayout, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    
    -- Submit with FRAME FENCE
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] }) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
