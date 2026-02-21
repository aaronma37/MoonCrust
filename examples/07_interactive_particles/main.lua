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
local graph, g_pBuffer, g_attrBuffer, g_swImages = {}, {}, {}, {}
local current_time = 0

function M.init()
    print("Example 07: STABLE INTERACTIVE 1M Particles (using mc.gpu StdLib)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Particle { float px, py, pz, p1; float vx, vy, vz, p2; } Particle;
        typedef struct AttractorData {
            float time;
            float mouse_x;
            float mouse_y;
            uint32_t mouse_down;
        } AttractorData;
        typedef struct PushConstants { 
            float dt;
            uint32_t buf_id;
            uint32_t attr_id;
            uint32_t tex_id; 
        } PushConstants;
    ]]
    
    -- 1. Use mc.gpu factories
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do initial_data[i].px = (math.random()*2)-1; initial_data[i].py = (math.random()*2)-1; initial_data[i].pz = (math.random()*2)-1 end
    
    local particle_buffer = mc.buffer(BUFFER_SIZE, "storage", initial_data)
    local attractor_buffer = mc.buffer(ffi.sizeof("AttractorData"), "storage", nil, true) -- Host visible
    M.attr_ptr = ffi.cast("AttractorData*", attractor_buffer.allocation.ptr)

    -- 2. Glow Texture
    local TW, TH = 16, 16
    local tex_data = ffi.new("uint8_t[?]", TW * TH * 4)
    for y = 0, TH - 1 do for x = 0, TW - 1 do 
        local dist = math.sqrt(((x-8)/8)^2 + ((y-8)/8)^2)
        local idx = (y*TW+x)*4; tex_data[idx]=255; tex_data[idx+1]=255; tex_data[idx+2]=255; tex_data[idx+3]=math.floor(math.max(0,1-dist)^2 * 255)
    end end
    local glow_img = mc.gpu.image(TW, TH, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
    staging.new(physical_device, device, mc.gpu.heaps.host, TW*TH*4 + 1024):upload_image(glow_img.handle, TW, TH, tex_data, queue, graphics_family)
    local glow_samp = mc.gpu.sampler(vk.VK_FILTER_LINEAR)

    -- 3. Bindless
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer.handle, 0, BUFFER_SIZE, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, attractor_buffer.handle, 0, ffi.sizeof("AttractorData"), 1)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, glow_img.view, glow_samp, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)

    -- 4. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 16 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/07_interactive_particles/physics.comp", pipe_layout)
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/07_interactive_particles/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/07_interactive_particles/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        additive = true,
        depth_write = false,
        depth_test = false,
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST
    })

    -- 5. Render Graph
    graph = render_graph.new(device)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer.handle)
    g_attrBuffer = graph:register_resource("AttrBuffer", render_graph.TYPE_BUFFER, attractor_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end
    
    -- Sync Objects (Frames in Flight)
    local pF = ffi.new("VkFence[1]")
    local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})

    M.frame_fences = {}
    M.image_available_sems = {}
    M.render_finished_sems = {}
    M.MAX_FRAMES_IN_FLIGHT = 3
    M.current_frame = 0

    for i=0, M.MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, fence_info, nil, pF); M.frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.render_finished_sems[i] = pS[0]
    end
    
    local pool = command.create_pool(device, graphics_family)
    cbs = command.allocate_buffers(device, pool, M.MAX_FRAMES_IN_FLIGHT)
    M.cache = cache
end

local last_ticks = 0

function M.update()
    M.cache:update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks
    
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    
    local img_idx = sw:acquire_next_image(M.image_available_sems[M.current_frame])
    if not img_idx then return end
    
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}))
    
    current_time = current_time + dt
    local mx, my = mc.input.mouse_pos()
    M.attr_ptr.time = current_time
    M.attr_ptr.mouse_x = (mx / (sw.extent.width or 1280)) * 2 - 1
    M.attr_ptr.mouse_y = (my / (sw.extent.height or 720)) * 2 - 1
    M.attr_ptr.mouse_down = mc.input.mouse_down(1) and 1 or 0

    local cb = cbs[M.current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { dt = dt, buf_id = 0, attr_id = 1, tex_id = 0 })
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})
    local sw_res = g_swImages[img_idx]

    graph:reset()
    graph:add_pass("Physics", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.cache.pipelines["physics"])
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 16, pc)
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_attrBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

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
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 16, pc)
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(sw_res, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("Present", function(c) end):using(sw_res, 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb)
    vk.vkEndCommandBuffer(cb)

    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {M.image_available_sems[M.current_frame]}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {M.render_finished_sems[M.current_frame]}) 
    }), M.frame_fences[M.current_frame])
    
    sw:present(queue, img_idx, M.render_finished_sems[M.current_frame])
    M.current_frame = (M.current_frame + 1) % M.MAX_FRAMES_IN_FLIGHT
end

return M
