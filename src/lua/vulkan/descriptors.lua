local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- BINDLESS CONSTANTS
local MAX_BINDLESS_RESOURCES = 100000

function M.create_bindless_layout(device)
    -- We'll create a layout with a single binding that is a massive array
    -- Binding 0: Storage Buffers (Bindless)
    local binding = ffi.new("VkDescriptorSetLayoutBinding", {
        binding = 0,
        descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
        descriptorCount = MAX_BINDLESS_RESOURCES,
        stageFlags = vk.VK_SHADER_STAGE_ALL,
        pImmutableSamplers = nil
    })

    -- Enable Bindless Flags
    local flags = ffi.new("VkDescriptorBindingFlags[1]", {
        bit.bor(
            vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT,
            vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT,
            vk.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT
        )
    })

    local binding_flags = ffi.new("VkDescriptorSetLayoutBindingFlagsCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
        bindingCount = 1,
        pBindingFlags = flags
    })

    local info = ffi.new("VkDescriptorSetLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        pNext = binding_flags,
        flags = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
        bindingCount = 1,
        pBindings = binding
    })

    local pLayout = ffi.new("VkDescriptorSetLayout[1]")
    local result = vk.vkCreateDescriptorSetLayout(device, info, nil, pLayout)
    if result ~= vk.VK_SUCCESS then error("Bindless Layout Failed: " .. result) end
    return pLayout[0]
end

function M.create_bindless_pool(device)
    local size = ffi.new("VkDescriptorPoolSize", {
        type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
        descriptorCount = MAX_BINDLESS_RESOURCES
    })

    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        flags = vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
        maxSets = 1,
        poolSizeCount = 1,
        pPoolSizes = size
    })

    local pPool = ffi.new("VkDescriptorPool[1]")
    local result = vk.vkCreateDescriptorPool(device, info, nil, pPool)
    if result ~= vk.VK_SUCCESS then error("Bindless Pool Failed: " .. result) end
    return pPool[0]
end

-- LEGACY WRAPPERS (for compatibility during transition)
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
    vk.vkCreateDescriptorSetLayout(device, info, nil, pLayout)
    return pLayout[0]
end

function M.create_pool(device, sizes, max_sets)
    local p_sizes = ffi.new("VkDescriptorPoolSize[?]", #sizes)
    for i, s in ipairs(sizes) do
        p_sizes[i-1] = ffi.new("VkDescriptorPoolSize", { type = s.type, descriptorCount = s.count })
    end
    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        poolSizeCount = #sizes,
        pPoolSizes = p_sizes,
        maxSets = max_sets or 1
    })
    local pPool = ffi.new("VkDescriptorPool[1]")
    vk.vkCreateDescriptorPool(device, info, nil, pPool)
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
    vk.vkAllocateDescriptorSets(device, info, pSets)
    local sets = {}
    for i = 0, #layouts - 1 do table.insert(sets, pSets[i]) end
    return sets
end

function M.update_buffer_set(device, set, binding, type, buffer, offset, range, array_element)
    local buffer_info = ffi.new("VkDescriptorBufferInfo", {
        buffer = buffer,
        offset = offset or 0,
        range = range or vk.VK_WHOLE_SIZE
    })
    local write = ffi.new("VkWriteDescriptorSet", {
        sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet = set,
        dstBinding = binding,
        dstArrayElement = array_element or 0,
        descriptorCount = 1,
        descriptorType = type,
        pBufferInfo = buffer_info
    })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

return M
