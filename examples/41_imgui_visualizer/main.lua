local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local input = require("mc.input")
local mc = require("mc")
local imgui = require("imgui")

local M = { 
    counter = 0,
    plot_data = {},
    plot_3d = {},
    show_demo = true,
    
    -- Optimized buffers
    p_plot_data = ffi.new("float[100]"),
    p_plot_3d_x = ffi.new("float[100]"),
    p_plot_3d_y = ffi.new("float[100]"),
    p_plot_3d_z = ffi.new("float[100]"),
    p_plot_spec = ffi.new("ImPlotSpec_c"),
    p_plot3d_spec = ffi.new("ImPlot3DSpec_c"),
}

local device, queue, graphics_family, sw, graph
local bindless_set, image_available_sem, frame_fence, cb

local function sync_buffers()
    for i = 1, 100 do
        M.p_plot_data[i-1] = M.plot_data[i]
        M.p_plot_3d_x[i-1] = M.plot_3d[i][1]
        M.p_plot_3d_y[i-1] = M.plot_3d[i][2]
        M.p_plot_3d_z[i-1] = M.plot_3d[i][3]
    end
end

function M.init()
    print("Example 41: ImGui + ImPlot + ImPlot3D integration")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    
    -- 1. Initialize ImGui
    imgui.init()
    
    -- 2. Setup Data
    for i = 1, 100 do
        table.insert(M.plot_data, math.sin(i * 0.1))
        table.insert(M.plot_3d, { math.cos(i * 0.1), math.sin(i * 0.1), i * 0.01 })
    end
    
    M.p_plot_spec.Stride = 4
    M.p_plot3d_spec.Stride = 4
    sync_buffers()
    
    -- 3. Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    -- ImGui Logic
    imgui.new_frame()
    local gui = imgui.gui
    
    if M.show_demo then
        local p_open = ffi.new("bool[1]", true)
        gui.igShowDemoWindow(p_open)
        M.show_demo = p_open[0]
    end
    
    if gui.igBegin("MoonCrust Control Panel", nil, 0) then
        gui.igText("Kernel: MoonCrust 1.4")
        gui.igText("FPS: %.1f", gui.igGetIO_Nil().Framerate)
        
        if gui.igButton("Reset Plot", ffi.new("ImVec2_c", {0, 0})) then
            M.plot_data = {}
            for i = 1, 100 do table.insert(M.plot_data, math.sin(i * 0.1 + gui.igGetIO_Nil().DeltaTime)) end
            sync_buffers()
        end
        
        -- ImPlot
        if gui.ImPlot_BeginPlot("Sine Wave", ffi.new("ImVec2_c", {-1, 150}), 0) then
            gui.ImPlot_PlotLine_FloatPtrInt("sin(x)", M.p_plot_data, 100, 1.0, 0, M.p_plot_spec)
            gui.ImPlot_EndPlot()
        end
        
        -- ImPlot3D
        if gui.ImPlot3D_BeginPlot("3D Spiral", ffi.new("ImVec2_c", {-1, 300}), 0) then
            gui.ImPlot3D_PlotLine_FloatPtr("spiral", M.p_plot_3d_x, M.p_plot_3d_y, M.p_plot_3d_z, 100, M.p_plot3d_spec)
            gui.ImPlot3D_EndPlot()
        end
        gui.igEnd()
    end

    -- Command Recording
    vk.vkResetCommandBuffer(cb, 0)
    vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local range = ffi.new("VkImageSubresourceRange", { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 })
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ 
        sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, 
        oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, 
        newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 
        image=ffi.cast("VkImage", sw.images[img_idx]), 
        subresourceRange=range, 
        dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT 
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx])
    color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color.float32 = {0.1, 0.1, 0.1, 1.0}
    
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { 
        sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, 
        renderArea={extent=sw.extent}, 
        layerCount=1, 
        colorAttachmentCount=1, 
        pColorAttachments=color_attach 
    }))
    
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    
    -- IMGUI RENDER
    imgui.render(cb)

    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    local render_finished_sem = sw.semaphores[img_idx]
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount=1, 
        pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), 
        pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount=1, 
        pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount=1, 
        pSignalSemaphores=ffi.new("VkSemaphore[1]", {render_finished_sem}) 
    }), frame_fence)
    
    sw:present(queue, img_idx, render_finished_sem)
end

return M
