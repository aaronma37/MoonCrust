local ffi = require("ffi")
local vk = require("vulkan.ffi")
local memory = require("vulkan.memory")

local M = {}
local Heap = {}
Heap.__index = Heap

function M.new(physical_device, device, memory_type_index, size)
    local self = setmetatable({}, Heap)
    
    self.device = device
    self.size = size
    self.memory_type_index = memory_type_index
    
    local alloc_info = ffi.new("VkMemoryAllocateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        allocationSize = size,
        memoryTypeIndex = memory_type_index
    })
    
    local pMemory = ffi.new("VkDeviceMemory[1]")
    local result = vk.vkAllocateMemory(device, alloc_info, nil, pMemory)
    if result ~= vk.VK_SUCCESS then
        error("Failed to allocate VkDeviceMemory: " .. tostring(result))
    end
    self.handle = pMemory[0]
    
    -- Map memory if it's host visible
    local mem_props = ffi.new("VkPhysicalDeviceMemoryProperties")
    vk.vkGetPhysicalDeviceMemoryProperties(physical_device, mem_props)
    local flags = mem_props.memoryTypes[memory_type_index].propertyFlags
    
    if bit.band(flags, vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) ~= 0 then
        local pData = ffi.new("void*[1]")
        vk.vkMapMemory(device, self.handle, 0, size, 0, pData)
        self.mapped_ptr = ffi.cast("uint8_t*", pData[0])
    end
    
    -- Initialize TLSF to manage this heap
    -- Since TLSF needs a pointer to write its block headers, 
    -- if it's NOT mapped (device local), we'll need a "shadow" buffer 
    -- or just manage offsets. For now, we'll assume we can use a dummy 
    -- pointer for non-mapped memory since TLSF only writes to it if we add_pool.
    self.allocator = memory.new(size)
    if self.mapped_ptr then
        self.allocator:add_pool(self.mapped_ptr, size)
    else
        -- For device local, we'll use a shadow buffer just for the headers
        -- This is a MoonCrust specific trick to keep logic in Lua
        self.shadow_headers = ffi.new("uint8_t[?]", size)
        self.allocator:add_pool(self.shadow_headers, size)
    end
    
    return self
end

function Heap:malloc(size)
    local offset = self.allocator:malloc(size)
    if not offset then return nil end
    
    return {
        memory = self.handle,
        offset = offset,
        size = size,
        ptr = self.mapped_ptr and (self.mapped_ptr + offset) or nil
    }
end

function Heap:free(allocation)
    self.allocator:free(allocation.offset)
end

function M.find_memory_type(physical_device, type_filter, properties)
    local mem_props = ffi.new("VkPhysicalDeviceMemoryProperties")
    vk.vkGetPhysicalDeviceMemoryProperties(physical_device, mem_props)
    
    for i = 0, mem_props.memoryTypeCount - 1 do
        if bit.band(type_filter, bit.lshift(1, i)) ~= 0 and 
           bit.band(mem_props.memoryTypes[i].propertyFlags, properties) == properties then
            return i
        end
    end
    
    error("Failed to find suitable memory type.")
end

return M
