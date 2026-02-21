local ffi = require("ffi")
local vk = require("vulkan.ffi")
local sdl = require("vulkan.sdl")

local M = {}
local Swapchain = {}
Swapchain.__index = Swapchain

function M.new(instance, physical_device, device, window)
    local self = setmetatable({}, Swapchain)
    
    -- 1. Create Surface
    local pSurface = ffi.new("void*[1]")
    if not sdl.SDL_Vulkan_CreateSurface(window, instance, nil, pSurface) then
        error("Failed to create SDL Vulkan Surface: " .. ffi.string(sdl.SDL_GetError()))
    end
    self.surface = pSurface[0]
    self.device = device

    -- 2. Get Window Size
    local pw = ffi.new("int[1]")
    local ph = ffi.new("int[1]")
    sdl.SDL_GetWindowSizeInPixels(window, pw, ph)
    local width, height = pw[0], ph[0]

    -- 3. Get Present Modes and choose best
    local mode_count = ffi.new("uint32_t[1]")
    vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, self.surface, mode_count, nil)
    local modes = ffi.new("VkPresentModeKHR[?]", mode_count[0])
    vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, self.surface, mode_count, modes)
    
    local present_mode = vk.VK_PRESENT_MODE_FIFO_KHR
    for i=0, mode_count[0]-1 do
        if modes[i] == vk.VK_PRESENT_MODE_MAILBOX_KHR then
            present_mode = vk.VK_PRESENT_MODE_MAILBOX_KHR
            break
        elseif modes[i] == vk.VK_PRESENT_MODE_IMMEDIATE_KHR then
            present_mode = vk.VK_PRESENT_MODE_IMMEDIATE_KHR
        end
    end
    print("Swapchain: Using Present Mode: " .. present_mode)

    -- 4. Create Swapchain
    local swap_info = ffi.new("VkSwapchainCreateInfoKHR", {
        sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        surface = ffi.cast("VkSurfaceKHR", self.surface),
        minImageCount = 3,
        imageFormat = vk.VK_FORMAT_B8G8R8A8_SRGB,
        imageColorSpace = vk.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
        imageExtent = { width = width, height = height },
        imageArrayLayers = 1,
        imageUsage = bit.bor(vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT),
        imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        preTransform = vk.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
        compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        presentMode = present_mode,
        clipped = vk.VK_TRUE
    })

    local pSwapchain = ffi.new("VkSwapchainKHR[1]")
    local result = vk.vkCreateSwapchainKHR(device, swap_info, nil, pSwapchain)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Swapchain: " .. tostring(result))
    end
    self.handle = pSwapchain[0]

    -- 4. Get Images and Create Views
    local count = ffi.new("uint32_t[1]")
    vk.vkGetSwapchainImagesKHR(device, self.handle, count, nil)
    
    -- HARDENING: Store images and views in persistent FFI arrays
    self.image_count = count[0]
    self.images = ffi.new("uint64_t[?]", self.image_count)
    self.views = ffi.new("uint64_t[?]", self.image_count)
    self.semaphores = ffi.new("VkSemaphore[?]", self.image_count)
    
    local pImgs = ffi.new("VkImage[?]", self.image_count)
    vk.vkGetSwapchainImagesKHR(device, self.handle, count, pImgs)
    
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })

    for i=0, self.image_count-1 do
        self.images[i] = ffi.cast("uint64_t", pImgs[i])
        
        local view_info = ffi.new("VkImageViewCreateInfo", {
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            image = pImgs[i],
            viewType = vk.VK_IMAGE_VIEW_TYPE_2D,
            format = vk.VK_FORMAT_B8G8R8A8_SRGB,
            subresourceRange = {
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
                baseMipLevel = 0, levelCount = 1,
                baseArrayLayer = 0, layerCount = 1
            }
        })
        local pView = ffi.new("VkImageView[1]")
        vk.vkCreateImageView(device, view_info, nil, pView)
        self.views[i] = ffi.cast("uint64_t", pView[0])

        local pSem = ffi.new("VkSemaphore[1]")
        vk.vkCreateSemaphore(device, sem_info, nil, pSem)
        self.semaphores[i] = pSem[0]
    end
    
    self.extent = { width = width, height = height }
    
    return self
end

function Swapchain:acquire_next_image(semaphore)
    local pIndex = ffi.new("uint32_t[1]")
    local result = vk.vkAcquireNextImageKHR(self.device, self.handle, 0xFFFFFFFFFFFFFFFFULL, semaphore, nil, pIndex)
    if result ~= vk.VK_SUCCESS then return nil end
    return pIndex[0] -- 0-based for FFI array access
end

function Swapchain:present(queue, image_index, wait_semaphore)
    local pIndex = ffi.new("uint32_t[1]", {image_index})
    local pSwaps = ffi.new("VkSwapchainKHR[1]", {self.handle})
    local pSems = wait_semaphore and ffi.new("VkSemaphore[1]", {wait_semaphore}) or nil
    
    local present_info = ffi.new("VkPresentInfoKHR", {
        sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        waitSemaphoreCount = wait_semaphore and 1 or 0,
        pWaitSemaphores = pSems,
        swapchainCount = 1,
        pSwapchains = pSwaps,
        pImageIndices = pIndex
    })
    vk.vkQueuePresentKHR(queue, present_info)
end

return M
