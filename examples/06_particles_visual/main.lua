local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local image = require("vulkan.image")
local swapchain = require("vulkan.swapchain")
local staging = require("vulkan.staging")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local M = {}

local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local image_available_sem, frame_fence, cbs, bindless_set
local graph, g_pBuffer, g_swImages = {}, {}, {}
local depth_img, g_depthBuffer
local current_time = 0

local MAX_FRAMES_IN_FLIGHT = 3
local current_frame = 0
local frame_fences = {}
local image_available_sems = {}
local render_finished_sems = {}

function M.init()
    print("Example 06: 1M Particles 3D (using mc.gpu StdLib)")
    -- ... (Keep existing init code up to Sync) ...
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Particle { float px, py, pz, p1; float vx, vy, vz, p2; } Particle;
        typedef struct PushConstants { float dt, time; uint32_t buf_id, tex_id; } PushConstants;
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- 1. Use mc.gpu for depth and buffers
    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")
    
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do 
        initial_data[i].px = (math.random()*2)-1; initial_data[i].py = (math.random()*2)-1; initial_data[i].pz = (math.random()*2)-1 
    end
    local particle_buffer = mc.buffer(BUFFER_SIZE, "storage", initial_data)

    -- 2. Glow Texture
    local TW, TH = 16, 16
    local tex_data = ffi.new("uint8_t[?]", TW * TH * 4)
    for y = 0, TH - 1 do for x = 0, TW - 1 do 
        local dist = math.sqrt(((x-8)/8)^2 + ((y-8)/8)^2)
        local idx = (y*TW+x)*4; tex_data[idx]=255; tex_data[idx+1]=255; tex_data[idx+2]=255; tex_data[idx+3]=math.floor(math.max(0,1-dist)^2 * 255)
    end end
    
    local glow_img = mc.gpu.image(TW, TH, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
    local pd = vulkan.get_physical_device()
    local d = vulkan.get_device()
    local q, family = vulkan.get_queue()
    staging.new(pd, d, mc.gpu.heaps.host, TW*TH*4 + 1024):upload_image(glow_img.handle, TW, TH, tex_data, q, family)
    local glow_samp = mc.gpu.sampler(vk.VK_FILTER_LINEAR)

    -- 3. Bindless Setup
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(d, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer.handle, 0, BUFFER_SIZE, 0)
    descriptors.update_image_set(d, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, glow_img.view, glow_samp, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)

    -- 4. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 16 }})
    pipe_layout = pipeline.create_layout(d, {mc.gpu.get_bindless_layout()}, pc_range)
    
    local compute_pipe = pipeline.create_compute_pipeline(d, pipe_layout, shader.create_module(d, shader.compile_glsl(io.open("examples/06_particles_visual/physics.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    graphics_pipe = pipeline.create_graphics_pipeline(d, pipe_layout, shader.create_module(d, shader.compile_glsl(io.open("examples/06_particles_visual/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(d, shader.compile_glsl(io.open("examples/06_particles_visual/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        additive = true,
        depth_test = false,
        depth_write = false,
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST
    })

    -- 5. Render Graph
    graph = render_graph.new(d)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SwapchainImage_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    -- Sync Objects (Frames in Flight)
    local pF = ffi.new("VkFence[1]")
    local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})

    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(d, fence_info, nil, pF); frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(d, sem_info, nil, pS); image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(d, sem_info, nil, pS); render_finished_sems[i] = pS[0]
    end
    
    cbs = command.allocate_buffers(d, command.create_pool(d, graphics_family), MAX_FRAMES_IN_FLIGHT)
    M.compute_pipe = compute_pipe
end

local last_ticks = 0

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame])
    if img_idx == nil then return end 
    
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fences[current_frame]}))
    current_time = current_time + dt
    
    local cb = cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local pc = ffi.new("PushConstants", { dt = dt, time = current_time, buf_id = 0, tex_id = 0 })
    local stages = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT)

    graph:reset()
    graph:add_pass("Physics", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.compute_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, stages, 0, 16, pc)
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
        color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
        color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[0] = 0.0
        color_attach[0].clearValue.color.float32[1] = 0.0
        color_attach[0].clearValue.color.float32[2] = 0.0
        color_attach[0].clearValue.color.float32[3] = 1.0

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, stages, 0, 16, pc)
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)

    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sems[current_frame]}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {render_finished_sems[current_frame]}) 
    }), frame_fences[current_frame])
    
    sw:present(queue, img_idx, render_finished_sems[current_frame])
    
    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
