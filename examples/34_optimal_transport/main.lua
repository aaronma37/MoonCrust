local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local M = {}

local PARTICLE_COUNT = 4096 
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe, compute_pipe, bindless_set
local graph, g_pBuffer, g_swImages = {}, {}, {}
local current_time = 0
local epsilon = 0.05

function M.init()
    print("Example 34: Optimal Transport (Sinkhorn Algorithm)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct Particle {
            float cx, cy;
            float sx, sy;
            float tx, ty;
            float u, v;
        } Particle;
        typedef struct PushConstants {
            float dt, time;
            uint32_t buf_id;
            uint32_t num_particles;
            float epsilon;
            uint32_t mode;
        } PushConstants;
    ]]
    
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do 
        initial_data[i].sx = (math.random()*1.6)-0.8
        initial_data[i].sy = (math.random()*1.6)-0.8
        initial_data[i].cx = initial_data[i].sx
        initial_data[i].cy = initial_data[i].sy
        
        local ang = (i / PARTICLE_COUNT) * math.pi * 2
        initial_data[i].tx = math.cos(ang) * 0.6
        initial_data[i].ty = math.sin(ang) * 0.6
        
        initial_data[i].u = 1.0
        initial_data[i].v = 1.0
    end
    
    local p_buffer = mc.buffer(ffi.sizeof("Particle") * PARTICLE_COUNT, "storage", initial_data, true)
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, p_buffer.handle, 0, ffi.sizeof("Particle") * PARTICLE_COUNT, 0)

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT), offset = 0, size = 24 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    
    compute_pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/34_optimal_transport/ot.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/34_optimal_transport/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/34_optimal_transport/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), {
        additive = true,
        topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST
    })

    graph = render_graph.new(device)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, p_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    M.frame_fences, M.image_available_sems, M.render_finished_sems = {}, {}, {}
    local pF = ffi.new("VkFence[1]")
    local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})
    for i=0, 1 do
        vk.vkCreateFence(device, fence_info, nil, pF); M.frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.render_finished_sems[i] = pS[0]
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), 2)
    M.current_frame = 0
    M.particle_ptr = ffi.cast("Particle*", p_buffer.allocation.ptr)
end

local last_ticks = 0
local shape_timer = 0
local shape_index = 0

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(M.image_available_sems[M.current_frame])
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}))
    
    current_time = current_time + dt
    shape_timer = shape_timer + dt
    
    if shape_timer > 5.0 then
        shape_timer = 0
        shape_index = (shape_index + 1) % 3
        for i=0, PARTICLE_COUNT-1 do
            if shape_index == 0 then
                local ang = (i / PARTICLE_COUNT) * math.pi * 2
                M.particle_ptr[i].tx, M.particle_ptr[i].ty = math.cos(ang) * 0.7, math.sin(ang) * 0.7
            elseif shape_index == 1 then
                local side = math.floor(i / (PARTICLE_COUNT/4))
                local t = (i % (PARTICLE_COUNT/4)) / (PARTICLE_COUNT/4)
                if side == 0 then M.particle_ptr[i].tx, M.particle_ptr[i].ty = -0.7 + t*1.4, -0.7
                elseif side == 1 then M.particle_ptr[i].tx, M.particle_ptr[i].ty = 0.7, -0.7 + t*1.4
                elseif side == 2 then M.particle_ptr[i].tx, M.particle_ptr[i].ty = 0.7 - t*1.4, 0.7
                else M.particle_ptr[i].tx, M.particle_ptr[i].ty = -0.7, 0.7 - t*1.4 end
            else
                local t = (i / PARTICLE_COUNT) * math.pi * 2
                local scale = 0.8 / (3.0 - math.cos(2.0*t))
                M.particle_ptr[i].tx, M.particle_ptr[i].ty = scale * math.cos(t), scale * math.sin(2.0*t) / 2.0
            end
        end
    end

    local cb = cbs[M.current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { dt = dt, time = current_time, buf_id = 0, num_particles = PARTICLE_COUNT, epsilon = epsilon, mode = 0 })
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()
    graph:add_pass("OT_Solve", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        for i=1, 4 do
            pc.mode = 0; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 24, pc)
            vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
            local bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, bar, 0, nil, 0, nil)
            pc.mode = 1; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 24, pc)
            vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, bar, 0, nil, 0, nil)
        end
        pc.mode = 2; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 24, pc)
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuffer, bit.bor(vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_ACCESS_SHADER_READ_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[0] = 0.0
        color_attach[0].clearValue.color.float32[1] = 0.0
        color_attach[0].clearValue.color.float32[2] = 0.01
        color_attach[0].clearValue.color.float32[3] = 1.0

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 24, pc)
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("Present", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {M.image_available_sems[M.current_frame]}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {M.render_finished_sems[M.current_frame]}) 
    }), M.frame_fences[M.current_frame])
    
    sw:present(queue, img_idx, M.render_finished_sems[M.current_frame])
    M.current_frame = (M.current_frame + 1) % 2
end

return M
