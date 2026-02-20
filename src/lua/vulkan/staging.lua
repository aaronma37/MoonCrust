local ffi = require("ffi")
local vk = require("vulkan.ffi")
local command = require("vulkan.command")

local M = {}
local Staging = {}
Staging.__index = Staging

function M.new(physical_device, device, heap_manager, size)
    local self = setmetatable({}, Staging)
    
    self.device = device
    self.heap = heap_manager
    self.size = size
    
    local buffer_info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = size,
        usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, buffer_info, nil, pBuffer)
    self.buffer = pBuffer[0]
    
    local alloc = self.heap:malloc(size)
    if not alloc then error("Failed to allocate staging memory.") end
    self.alloc = alloc
    vk.vkBindBufferMemory(device, self.buffer, alloc.memory, alloc.offset)
    
    return self
end

function Staging:upload_buffer(dst_buffer, src_data, dst_offset, queue, queue_family, explicit_size)
    local size = explicit_size or ffi.sizeof(src_data)
    if size > self.size then error("Staging buffer too small for upload.") end
    
    ffi.copy(self.alloc.ptr, src_data, size)
    
    local pool = command.create_pool(self.device, queue_family)
    local buffers = command.allocate_buffers(self.device, pool, 1)
    local cb = buffers[1]
    
    command.encode(cb, function(cmd)
        local copy_region = ffi.new("VkBufferCopy", {
            srcOffset = 0,
            dstOffset = dst_offset,
            size = size
        })
        vk.vkCmdCopyBuffer(cmd.buffer, self.buffer, dst_buffer, 1, copy_region)
    end)
    
    command.end_and_submit(cb, queue, self.device)
    vk.vkDestroyCommandPool(self.device, pool, nil)
end

function Staging:upload_image(dst_image, width, height, src_data, queue, queue_family, explicit_size, mip_levels)
    local size = explicit_size or ffi.sizeof(src_data)
    if size > self.size then error("Staging buffer too small for image upload.") end
    
    ffi.copy(self.alloc.ptr, src_data, size)
    
    local pool = command.create_pool(self.device, queue_family)
    local buffers = command.allocate_buffers(self.device, pool, 1)
    local cb = buffers[1]
    
    command.encode(cb, function(cmd)
        -- Transition level 0 to DST
        local barrier = ffi.new("VkImageMemoryBarrier[1]")
        barrier[0].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
        barrier[0].dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
        barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED
        barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
        barrier[0].image = dst_image
        barrier[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = mip_levels or 1, baseArrayLayer = 0, layerCount = 1 }
        vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 1, barrier)

        local region = ffi.new("VkBufferImageCopy", {
            bufferOffset = 0,
            bufferRowLength = 0,
            bufferImageHeight = 0,
            imageSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 },
            imageOffset = {0, 0, 0},
            imageExtent = { width = width, height = height, depth = 1 }
        })
        vk.vkCmdCopyBufferToImage(cmd.buffer, self.buffer, dst_image, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region)

        if mip_levels and mip_levels > 1 then
            self:generate_mipmaps_inline(cmd.buffer, dst_image, width, height, mip_levels)
        else
            -- Transition to Shader Read
            barrier[0].srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
            barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
            barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
            barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
            vk.vkCmdPipelineBarrier(cmd.buffer, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, 0, 0, nil, 0, nil, 1, barrier)
        end
    end)

    command.end_and_submit(cb, queue, self.device)
    vk.vkDestroyCommandPool(self.device, pool, nil)
end

function Staging:generate_mipmaps_inline(cb, image, width, height, mip_levels)
    local barrier = ffi.new("VkImageMemoryBarrier[1]")
    barrier[0].sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
    barrier[0].image = image
    barrier[0].srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED
    barrier[0].dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED
    barrier[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }

    local mipW, mipH = width, height

    for i = 1, mip_levels - 1 do
        barrier[0].subresourceRange.baseMipLevel = i - 1
        barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
        barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
        barrier[0].srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
        barrier[0].dstAccessMask = vk.VK_ACCESS_TRANSFER_READ_BIT
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 1, barrier)

        local blit = ffi.new("VkImageBlit[1]")
        blit[0].srcOffsets[0] = {0, 0, 0}
        blit[0].srcOffsets[1] = {mipW, mipH, 1}
        blit[0].srcSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = i - 1, baseArrayLayer = 0, layerCount = 1 }
        blit[0].dstOffsets[0] = {0, 0, 0}
        blit[0].dstOffsets[1] = {mipW > 1 and math.floor(mipW / 2) or 1, mipH > 1 and math.floor(mipH / 2) or 1, 1}
        blit[0].dstSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = i, baseArrayLayer = 0, layerCount = 1 }
        vk.vkCmdBlitImage(cb, image, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, image, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, blit, vk.VK_FILTER_LINEAR)

        barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
        barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
        barrier[0].srcAccessMask = vk.VK_ACCESS_TRANSFER_READ_BIT
        barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, barrier)

        if mipW > 1 then mipW = math.floor(mipW / 2) end
        if mipH > 1 then mipH = math.floor(mipH / 2) end
    end

    barrier[0].subresourceRange.baseMipLevel = mip_levels - 1
    barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
    barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
    barrier[0].srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT
    barrier[0].dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, barrier)
end

return M
