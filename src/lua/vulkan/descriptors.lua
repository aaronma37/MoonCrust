local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

function M.create_layout(device, bindings)
    local b_array = ffi.new("VkDescriptorSetLayoutBinding[?]", #bindings)
    for i, b in ipairs(bindings) do
        b_array[i-1] = ffi.new("VkDescriptorSetLayoutBinding", {
            binding = b.binding,
            descriptorType = b.type,
            descriptorCount = b.count or 1,
            stageFlags = b.stages,
            pImmutableSamplers = nil
        })
    end
    
    local info = ffi.new("VkDescriptorSetLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        bindingCount = #bindings,
        pBindings = b_array
    })
    
    local pLayout = ffi.new("VkDescriptorSetLayout[1]")
    local result = vk.vkCreateDescriptorSetLayout(device, info, nil, pLayout)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Descriptor Set Layout: " .. tostring(result))
    end
    return pLayout[0]
end

function M.create_pool(device, sizes, max_sets)
    local p_sizes = ffi.new("VkDescriptorPoolSize[?]", #sizes)
    for i, s in ipairs(sizes) do
        p_sizes[i-1] = ffi.new("VkDescriptorPoolSize", {
            type = s.type,
            descriptorCount = s.count
        })
    end
    
    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        poolSizeCount = #sizes,
        pPoolSizes = p_sizes,
        maxSets = max_sets or 1
    })
    
    local pPool = ffi.new("VkDescriptorPool[1]")
    local result = vk.vkCreateDescriptorPool(device, info, nil, pPool)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Descriptor Pool: " .. tostring(result))
    end
    return pPool[0]
end

function M.allocate_sets(device, pool, layouts)
    local info = ffi.new("VkDescriptorSetAllocateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        descriptorPool = pool,
        descriptorSetCount = #layouts,
        pSetLayouts = ffi.new("VkDescriptorSetLayout[?]", #layouts, layouts)
    })
    
    local pSets = ffi.new("VkDescriptorSet[?]", #layouts)
    local result = vk.vkAllocateDescriptorSets(device, info, pSets)
    if result ~= vk.VK_SUCCESS then
        error("Failed to allocate Descriptor Sets: " .. tostring(result))
    end
    
    local sets = {}
    for i = 0, #layouts - 1 do
        table.insert(sets, pSets[i])
    end
    return sets
end

function M.update_buffer_set(device, set, binding, type, buffer, offset, range)
    local buffer_info = ffi.new("VkDescriptorBufferInfo", {
        buffer = buffer,
        offset = offset or 0,
        range = range or vk.VK_WHOLE_SIZE
    })
    
    local write = ffi.new("VkWriteDescriptorSet", {
        sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet = set,
        dstBinding = binding,
        descriptorCount = 1,
        descriptorType = type,
        pBufferInfo = buffer_info
    })
    
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

return M
