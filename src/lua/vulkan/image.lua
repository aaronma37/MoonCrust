local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

function M.create_2d(device, width, height, format, usage)
    local info = ffi.new("VkImageCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        imageType = vk.VK_IMAGE_TYPE_2D,
        format = format,
        extent = { width = width, height = height, depth = 1 },
        mipLevels = 1,
        arrayLayers = 1,
        samples = vk.VK_SAMPLE_COUNT_1_BIT,
        tiling = vk.VK_IMAGE_TILING_OPTIMAL,
        usage = usage,
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        initialLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED
    })

    local pImage = ffi.new("VkImage[1]")
    local result = vk.vkCreateImage(device, info, nil, pImage)
    if result ~= vk.VK_SUCCESS then error("vkCreateImage failed: " .. result) end
    return pImage[0]
end

function M.create_view(device, image, format, aspect)
    local info = ffi.new("VkImageViewCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        image = image,
        viewType = vk.VK_IMAGE_VIEW_TYPE_2D,
        format = format,
        components = { r = 0, g = 0, b = 0, a = 0 },
        subresourceRange = {
            aspectMask = aspect or vk.VK_IMAGE_ASPECT_COLOR_BIT,
            baseMipLevel = 0,
            levelCount = 1,
            baseArrayLayer = 0,
            layerCount = 1
        }
    })

    local pView = ffi.new("VkImageView[1]")
    local result = vk.vkCreateImageView(device, info, nil, pView)
    if result ~= vk.VK_SUCCESS then error("vkCreateImageView failed: " .. result) end
    return pView[0]
end

function M.create_sampler(device, filter)
    local info = ffi.new("VkSamplerCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        magFilter = filter or vk.VK_FILTER_LINEAR,
        minFilter = filter or vk.VK_FILTER_LINEAR,
        mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        addressModeU = vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        addressModeV = vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        addressModeW = vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        anisotropyEnable = vk.VK_FALSE,
        maxAnisotropy = 1.0,
        compareEnable = vk.VK_FALSE,
        borderColor = vk.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
        unnormalizedCoordinates = vk.VK_FALSE
    })

    local pSampler = ffi.new("VkSampler[1]")
    local result = vk.vkCreateSampler(device, info, nil, pSampler)
    if result ~= vk.VK_SUCCESS then error("vkCreateSampler failed: " .. result) end
    return pSampler[0]
end

return M
