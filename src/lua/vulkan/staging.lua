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
    
    -- Allocate the physical staging buffer
    local buffer_info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = size,
        usage = vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, buffer_info, nil, pBuffer)
    self.buffer = pBuffer[0]
    
    -- Bind it to host-visible memory
    local alloc = self.heap:malloc(size)
    if not alloc then error("Failed to allocate staging memory.") end
    self.alloc = alloc
    vk.vkBindBufferMemory(device, self.buffer, alloc.memory, alloc.offset)
    
    return self
end

function Staging:upload_buffer(dst_buffer, src_data, dst_offset, queue, queue_family)
    local size = ffi.sizeof(src_data)
    if size > self.size then error("Staging buffer too small for upload.") end
    
    -- 1. Write data to mapped memory
    ffi.copy(self.alloc.ptr, src_data, size)
    
    -- 2. Record and submit copy command
    local pool = command.create_pool(self.device, queue_family)
    local buffers = command.allocate_buffers(self.device, pool, 1)
    local cb = buffers[1]
    
    command.begin_one_time(cb)
    
    local copy_region = ffi.new("VkBufferCopy", {
        srcOffset = 0,
        dstOffset = dst_offset,
        size = size
    })
    
    vk.vkCmdCopyBuffer(cb, self.buffer, dst_buffer, 1, copy_region)
    
    command.end_and_submit(cb, queue, self.device)
    
    -- Cleanup temporary command pool
    vk.vkDestroyCommandPool(self.device, pool, nil)
    
    print("Staging: Uploaded", size, "bytes to GPU.")
end

return M
