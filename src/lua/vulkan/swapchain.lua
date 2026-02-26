local ffi = require("ffi")
local vk = require("vulkan.ffi")
local resource = require("vulkan.resource")

local M = {}
M.__index = M

-- Pre-allocate presentation structures to avoid hot-loop churn
local static = {
    present_info = ffi.new("VkPresentInfoKHR", { sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR }),
    image_indices = ffi.new("uint32_t[1]"),
    swapchains = ffi.new("VkSwapchainKHR[1]"),
    semaphores = ffi.new("VkSemaphore[1]"),
}

function M.new(instance, physical_device, device, window, old_swapchain, use_srgb)
    local self = setmetatable({}, M)
    self.device = device

    local surface_ptr = ffi.new("void*[1]")
    if not ffi.C.SDL_Vulkan_CreateSurface(window, instance, nil, surface_ptr) then
        error("Failed to create surface: " .. ffi.string(ffi.C.SDL_GetError()))
    end
    self.surface = surface_ptr[0]

    -- Query support
    local caps = ffi.new("VkSurfaceCapabilitiesKHR")
    vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, self.surface, caps)
    
    self.extent = { width = caps.currentExtent.width, height = caps.currentExtent.height }
    
    local format_count = ffi.new("uint32_t[1]")
    vk.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, self.surface, format_count, nil)
    local formats = ffi.new("VkSurfaceFormatKHR[?]", format_count[0])
    vk.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, self.surface, format_count, formats)
    
    self.format = formats[0].format
    for i=0, format_count[0]-1 do
        if not use_srgb and formats[i].format == vk.VK_FORMAT_B8G8R8A8_UNORM then self.format = formats[i].format break end
        if use_srgb and formats[i].format == vk.VK_FORMAT_B8G8R8A8_SRGB then self.format = formats[i].format break end
    end

    -- Pick Present Mode: Prefer Mailbox (unlocked/low-latency) over FIFO
    local mode_count = ffi.new("uint32_t[1]")
    vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, self.surface, mode_count, nil)
    local modes = ffi.new("VkPresentModeKHR[?]", mode_count[0])
    vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, self.surface, mode_count, modes)
    
    local present_mode = vk.VK_PRESENT_MODE_FIFO_KHR
    for i=0, mode_count[0]-1 do
        if modes[i] == vk.VK_PRESENT_MODE_MAILBOX_KHR then present_mode = modes[i] break end
    end

    local createInfo = ffi.new("VkSwapchainCreateInfoKHR", {
        sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        surface = self.surface,
        minImageCount = math.max(caps.minImageCount + 1, 3), 
        imageFormat = self.format,
        imageColorSpace = formats[0].colorSpace,
        imageExtent = caps.currentExtent,
        imageArrayLayers = 1,
        imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        preTransform = caps.currentTransform,
        compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        presentMode = present_mode, 
        clipped = vk.VK_TRUE,
        oldSwapchain = old_swapchain or nil
    })

    local pSwapchain = ffi.new("VkSwapchainKHR[1]")
    local res = vk.vkCreateSwapchainKHR(device, createInfo, nil, pSwapchain)
    if res ~= vk.VK_SUCCESS then error("vkCreateSwapchainKHR failed: " .. res) end
    self.handle = pSwapchain[0]

    -- Images
    local count = ffi.new("uint32_t[1]")
    vk.vkGetSwapchainImagesKHR(device, self.handle, count, nil)
    self.image_count = count[0]
    self.images = ffi.new("VkImage[?]", self.image_count)
    vk.vkGetSwapchainImagesKHR(device, self.handle, count, self.images)

    -- Views
    self.views = ffi.new("VkImageView[?]", self.image_count)
    self.semaphores = ffi.new("VkSemaphore[?]", self.image_count)
    for i = 0, self.image_count - 1 do
        local viewInfo = ffi.new("VkImageViewCreateInfo", {
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            image = self.images[i],
            viewType = vk.VK_IMAGE_VIEW_TYPE_2D,
            format = self.format,
            subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
        })
        local pView = ffi.new("VkImageView[1]")
        vk.vkCreateImageView(device, viewInfo, nil, pView)
        self.views[i] = pView[0]

        local semInfo = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
        local pSem = ffi.new("VkSemaphore[1]")
        vk.vkCreateSemaphore(device, semInfo, nil, pSem)
        self.semaphores[i] = pSem[0]
    end

    return self
end

function M:acquire_next_image(semaphore, fence)
    local pIndex = ffi.new("uint32_t[1]")
    local res = vk.vkAcquireNextImageKHR(self.device, self.handle, 0xFFFFFFFFFFFFFFFFULL, semaphore, fence or nil, pIndex)
    if res == vk.VK_SUCCESS or res == vk.VK_SUBOPTIMAL_KHR then
        return pIndex[0], res
    end
    return nil, res
end

function M:present(queue, image_index, wait_semaphore)
    static.image_indices[0] = image_index
    static.swapchains[0] = self.handle
    static.semaphores[0] = wait_semaphore
    
    static.present_info.waitSemaphoreCount = 1
    static.present_info.pWaitSemaphores = static.semaphores
    static.present_info.swapchainCount = 1
    static.present_info.pSwapchains = static.swapchains
    static.present_info.pImageIndices = static.image_indices
    
    return vk.vkQueuePresentKHR(queue, static.present_info)
end

function M:cleanup()
    if not self.handle then return end
    -- CRITICAL: Ensure GPU is IDLE before destroying views/swapchain
    vk.vkDeviceWaitIdle(self.device)
    
    for i = 0, self.image_count - 1 do
        if self.views[i] ~= nil then
            vk.vkDestroyImageView(self.device, self.views[i], nil)
        end
        if self.semaphores[i] ~= nil then
            vk.vkDestroySemaphore(self.device, self.semaphores[i], nil)
        end
    end
    -- We do NOT use resource.free here for the swapchain handle itself 
    -- to avoid the death-row race condition during recreation.
    vk.vkDestroySwapchainKHR(self.device, self.handle, nil)
    self.handle = nil
end

return M
