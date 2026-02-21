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

local GRID_SIZE = 256
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe, compute_field, compute_update, bindless_set
local density_map, pot_a, pot_b
local graph, g_density, g_potA, g_potB, g_swImages = {}, {}, {}, {}, {}
local current_time = 0

local MAX_FRAMES_IN_FLIGHT = 1
local current_frame = 0
local frame_fences, image_available_sems, render_finished_sems = {}, {}, {}
local cbs = {}

function M.init()
    print("Example 36: Stable GPU Topology Optimization (SIMP)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    ffi.cdef[[
        typedef struct PushConstants {
            float dt, time;
            uint32_t width, height;
            uint32_t mode;
            uint32_t p1, p2, p3;
        } PushConstants;
    ]]
    
    density_map = mc.gpu.image(GRID_SIZE, GRID_SIZE, vk.VK_FORMAT_R32_SFLOAT, "storage")
    pot_a = mc.gpu.image(GRID_SIZE, GRID_SIZE, vk.VK_FORMAT_R32_SFLOAT, "storage")
    pot_b = mc.gpu.image(GRID_SIZE, GRID_SIZE, vk.VK_FORMAT_R32_SFLOAT, "storage")
    local sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)

    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_storage_image_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, density_map.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, pot_a.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, pot_b.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    
    -- Combined Samplers for Rendering
    descriptors.update_image_set(device, bindless_set, 3, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, density_map.view, sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, bindless_set, 4, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, pot_a.view, sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    
    compute_field = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/36_topology_opt/field.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    compute_update = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/36_topology_opt/update.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/36_topology_opt/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)),
        shader.create_module(device, shader.compile_glsl(io.open("examples/36_topology_opt/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, depth_test = false }
    )

    graph = render_graph.new(device)
    g_density = graph:register_resource("DensityMap", render_graph.TYPE_IMAGE, density_map.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED })
    g_potA = graph:register_resource("PotA", render_graph.TYPE_IMAGE, pot_a.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED })
    g_potB = graph:register_resource("PotB", render_graph.TYPE_IMAGE, pot_b.handle, { layout = vk.VK_IMAGE_LAYOUT_UNDEFINED })
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end

    for i=0, MAX_FRAMES_IN_FLIGHT-1 do
        frame_fences[i] = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fences[i])
        image_available_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sems[i])
        render_finished_sems[i] = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, render_finished_sems[i])
    end
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), MAX_FRAMES_IN_FLIGHT)
end

local last_ticks = 0
local initialized_grid = false

function M.update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    last_ticks = ticks

    vk.vkWaitForFences(device, 1, frame_fences[current_frame], vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(image_available_sems[current_frame][0])
    if img_idx == nil then return end
    vk.vkResetFences(device, 1, frame_fences[current_frame])
    
    current_time = current_time + dt
    local cb = cbs[current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { dt = dt, time = current_time, width = GRID_SIZE, height = GRID_SIZE, mode = 0 })
    local pSets = ffi.new("VkDescriptorSet[1]", {bindless_set})

    graph:reset()

    if not initialized_grid then
        graph:add_pass("Initialize", function(c)
            local clear_val = ffi.new("VkClearColorValue")
            clear_val.float32[0] = 0.5 
            local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 })
            vk.vkCmdClearColorImage(c, density_map.handle, vk.VK_IMAGE_LAYOUT_GENERAL, clear_val, 1, range)
            clear_val.float32[0] = 0.0
            vk.vkCmdClearColorImage(c, pot_a.handle, vk.VK_IMAGE_LAYOUT_GENERAL, clear_val, 1, range)
            vk.vkCmdClearColorImage(c, pot_b.handle, vk.VK_IMAGE_LAYOUT_GENERAL, clear_val, 1, range)
        end):using(g_density, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(g_potA, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(g_potB, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
        initialized_grid = true
    end
    
    -- Ping-Pong Field Solver (512 iterations per frame)
    graph:add_pass("Field_Solve", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_field)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
        for i=1, 256 do
            -- Step 1: A -> B
            pc.mode = 0; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
            vk.vkCmdDispatch(c, GRID_SIZE / 16, GRID_SIZE / 16, 1)
            local bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, bar, 0, nil, 0, nil)
            
            -- Step 2: B -> A
            pc.mode = 1; vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
            vk.vkCmdDispatch(c, GRID_SIZE / 16, GRID_SIZE / 16, 1)
            vk.vkCmdPipelineBarrier(c, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, bar, 0, nil, 0, nil)
        end
    end):using(g_density, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_potA, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_potB, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)

    if current_time > 2.0 then
        graph:add_pass("Density_Update", function(c)
            vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_update)
            vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSets, 0, nil)
            vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 32, pc)
            vk.vkCmdDispatch(c, GRID_SIZE / 16, GRID_SIZE / 16, 1)
        end):using(g_density, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
           :using(g_potA, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
    end

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
        color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
        color_attach[0].clearValue.color.float32[3] = 1.0

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSets, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, vk.VK_SHADER_STAGE_FRAGMENT_BIT, 0, 32, pc)
        vk.vkCmdDraw(c, 3, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_density, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_potA, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, vk.VK_IMAGE_LAYOUT_GENERAL)
       :using(g_swImages[img_idx], vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("PresentPrep", function(c) end):using(g_swImages[img_idx], 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb); vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = image_available_sems[current_frame], 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = render_finished_sems[current_frame] 
    }), frame_fences[current_frame][0])
    
    sw:present(queue, img_idx, render_finished_sems[current_frame][0])
    current_frame = (current_frame + 1) % MAX_FRAMES_IN_FLIGHT
end

return M
