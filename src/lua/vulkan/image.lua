local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

function M.find_depth_format(physical_device)
    local candidates = {
        vk.VK_FORMAT_D32_SFLOAT,
        vk.VK_FORMAT_D32_SFLOAT_S8_UINT,
        vk.VK_FORMAT_D24_UNORM_S8_UINT
    }
    for _, format in ipairs(candidates) do
        local props = ffi.new("VkFormatProperties")
        vk.vkGetPhysicalDeviceFormatProperties(physical_device, format, props)
        if bit.band(props.optimalTilingFeatures, vk.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) ~= 0 then
            return format
        end
    end
    error("Failed to find supported depth format")
end

function M.create_2d(device, width, height, format, usage, mip_levels)
    local info = ffi.new("VkImageCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        imageType = vk.VK_IMAGE_TYPE_2D,
        format = format,
        extent = { width = width, height = height, depth = 1 },
        mipLevels = mip_levels or 1,
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

function M.create_3d(device, width, height, depth, format, usage)
    local info = ffi.new("VkImageCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        imageType = vk.VK_IMAGE_TYPE_3D,
        format = format,
        extent = { width = width, height = height, depth = depth },
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
    if result ~= vk.VK_SUCCESS then error("vkCreateImage (3D) failed: " .. result) end
    return pImage[0]
end

function M.create_view(device, image, format, aspect, is_3d, mip_levels)
    local info = ffi.new("VkImageViewCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        image = image,
        viewType = is_3d and vk.VK_IMAGE_VIEW_TYPE_3D or vk.VK_IMAGE_VIEW_TYPE_2D,
        format = format,
        components = { r = 0, g = 0, b = 0, a = 0 },
        subresourceRange = {
            aspectMask = aspect or vk.VK_IMAGE_ASPECT_COLOR_BIT,
            baseMipLevel = 0,
            levelCount = mip_levels or 1,
            baseArrayLayer = 0,
            layerCount = 1
        }
    })

    local pView = ffi.new("VkImageView[1]")
    local result = vk.vkCreateImageView(device, info, nil, pView)
    if result ~= vk.VK_SUCCESS then error("vkCreateImageView failed: " .. result) end
    return pView[0]
end

function M.create_sampler(device, filter, address_mode)
    local mode = address_mode or vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
    local info = ffi.new("VkSamplerCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        magFilter = filter or vk.VK_FILTER_LINEAR,
        minFilter = filter or vk.VK_FILTER_LINEAR,
        mipmapMode = vk.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        addressModeU = mode,
        addressModeV = mode,
        addressModeW = mode,
        anisotropyEnable = vk.VK_FALSE,
        maxAnisotropy = 1.0,
        compareEnable = vk.VK_FALSE,
        borderColor = vk.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
        unnormalizedCoordinates = vk.VK_FALSE,
        minLod = 0.0,
        maxLod = 16.0
    })

    local pSampler = ffi.new("VkSampler[1]")
    local result = vk.vkCreateSampler(device, info, nil, pSampler)
    if result ~= vk.VK_SUCCESS then error("vkCreateSampler failed: " .. result) end
    return pSampler[0]
end

return M
