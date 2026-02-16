local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")

local M = {}
local instance, physical_device, device, queue, graphics_family, sw, cb, pool
local image_available_sem, render_finished_sem

function M.init()
    print("Example 05: Clear Screen (Visuals)")
    
    instance = vulkan.create_instance("MoonCrust_Clear")
    physical_device = vulkan.select_physical_device(instance)
    device, graphics_family = vulkan.create_device(physical_device)
    queue = vulkan.get_queue(device, graphics_family)

    -- Create Swapchain
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    print("Swapchain created with", sw.image_count, "images.")

    -- Create Semaphores
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO
    })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); render_finished_sem = pSem[0]

    pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]
end

local frame_count = 0
function M.update()
    frame_count = frame_count + 1
    
    -- 1. Acquire Image
    local img_idx = sw:acquire_next_image(image_available_sem)
    local img = ffi.cast("VkImage", sw.images[img_idx])

    -- 2. Record Clear Command
    command.begin_one_time(cb)

    -- Transition image to DST_OPTIMAL for clear
    local barrier = ffi.new("VkImageMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        srcAccessMask = 0,
        dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT,
        oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        image = img,
        subresourceRange = {
            aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            baseMipLevel = 0, levelCount = 1,
            baseArrayLayer = 0, layerCount = 1
        }
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 1, barrier)

    -- Clear with a changing color
    local r = (math.sin(frame_count * 0.05) + 1) * 0.5
    local g = (math.cos(frame_count * 0.03) + 1) * 0.5
    local b = (math.sin(frame_count * 0.02) + 1) * 0.5
    
    local clear_color = ffi.new("VkClearColorValue")
    clear_color.float32[0] = r
    clear_color.float32[1] = g
    clear_color.float32[2] = b
    clear_color.float32[3] = 1.0

    local range = ffi.new("VkImageSubresourceRange", {
        aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
        baseMipLevel = 0, levelCount = 1,
        baseArrayLayer = 0, layerCount = 1
    })
    vk.vkCmdClearColorImage(cb, img, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, clear_color, 1, range)

    -- Transition image to PRESENT_SRC for display
    barrier[0].srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
    barrier[0].dstAccessMask = 0
    barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
    barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, barrier)

    vk.vkEndCommandBuffer(cb)

    -- 3. Submit
    local wait_sems = ffi.new("VkSemaphore[1]", {image_available_sem})
    local signal_sems = ffi.new("VkSemaphore[1]", {render_finished_sem})
    local wait_stages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_TRANSFER_BIT})
    
    local submit_info = ffi.new("VkSubmitInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        waitSemaphoreCount = 1,
        pWaitSemaphores = wait_sems,
        pWaitDstStageMask = wait_stages,
        commandBufferCount = 1,
        pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}),
        signalSemaphoreCount = 1,
        pSignalSemaphores = signal_sems
    })
    vk.vkQueueSubmit(queue, 1, submit_info, nil)

    -- 4. Present
    sw:present(queue, img_idx, render_finished_sem)
    
    -- We need to wait for queue to be idle to reuse the command buffer safely
    -- In a real engine, we'd use a per-frame command buffer
    vk.vkQueueWaitIdle(queue)
end

return M
