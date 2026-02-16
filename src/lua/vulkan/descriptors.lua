local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- BINDLESS CONSTANTS
local MAX_BINDLESS_RESOURCES = 1000

function M.create_bindless_layout(device)
    -- Binding 0: Storage Buffers (Bindless)
    -- Binding 1: Combined Image Samplers (Bindless) - Reading
    -- Binding 2: Storage Images (Bindless) - Writing
    local bindings = ffi.new("VkDescriptorSetLayoutBinding[3]")
    
    -- 0: Buffers
    bindings[0].binding = 0
    bindings[0].descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
    bindings[0].descriptorCount = MAX_BINDLESS_RESOURCES
    bindings[0].stageFlags = vk.VK_SHADER_STAGE_ALL
    
    -- 1: Sampled Images (Textures)
    bindings[1].binding = 1
    bindings[1].descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
    bindings[1].descriptorCount = MAX_BINDLESS_RESOURCES
    bindings[1].stageFlags = vk.VK_SHADER_STAGE_ALL

    -- 2: Storage Images (Writable)
    bindings[2].binding = 2
    bindings[2].descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE
    bindings[2].descriptorCount = MAX_BINDLESS_RESOURCES
    bindings[2].stageFlags = vk.VK_SHADER_STAGE_ALL

    -- Enable Bindless Flags for all
    local bindless_flags = bit.bor(vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT, vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT, vk.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT)
    
    local flags = ffi.new("VkDescriptorBindingFlags[3]", { bindless_flags, bindless_flags, bindless_flags })

    local binding_flags = ffi.new("VkDescriptorSetLayoutBindingFlagsCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
        bindingCount = 3,
        pBindingFlags = flags
    })

    local info = ffi.new("VkDescriptorSetLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        pNext = binding_flags,
        flags = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
        bindingCount = 3,
        pBindings = bindings
    })

    local pLayout = ffi.new("VkDescriptorSetLayout[1]")
    local result = vk.vkCreateDescriptorSetLayout(device, info, nil, pLayout)
    if result ~= vk.VK_SUCCESS then error("Bindless Layout Failed: " .. result) end
    return pLayout[0]
end

function M.create_bindless_pool(device)
    local sizes = ffi.new("VkDescriptorPoolSize[3]")
    sizes[0].type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
    sizes[0].descriptorCount = MAX_BINDLESS_RESOURCES
    sizes[1].type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
    sizes[1].descriptorCount = MAX_BINDLESS_RESOURCES
    sizes[2].type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE
    sizes[2].descriptorCount = MAX_BINDLESS_RESOURCES

    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        flags = vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
        maxSets = MAX_BINDLESS_RESOURCES,
        poolSizeCount = 3,
        pPoolSizes = sizes
    })

    local pPool = ffi.new("VkDescriptorPool[1]")
    local result = vk.vkCreateDescriptorPool(device, info, nil, pPool)
    if result ~= vk.VK_SUCCESS then error("Bindless Pool Failed: " .. result) end
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
    if result ~= vk.VK_SUCCESS then error("vkAllocateDescriptorSets failed: " .. result) end
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

function M.update_image_set(device, set, binding, type, view, sampler, layout, array_element)
    local image_info = ffi.new("VkDescriptorImageInfo", {
        sampler = sampler,
        imageView = view,
        imageLayout = layout or vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
    })
    local write = ffi.new("VkWriteDescriptorSet", {
        sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet = set,
        dstBinding = binding,
        dstArrayElement = array_element or 0,
        descriptorCount = 1,
        descriptorType = type,
        pImageInfo = image_info
    })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

function M.update_storage_image_set(device, set, binding, type, view, layout, array_element)
    local image_info = ffi.new("VkDescriptorImageInfo", {
        imageView = view,
        imageLayout = layout or vk.VK_IMAGE_LAYOUT_GENERAL
    })
    local write = ffi.new("VkWriteDescriptorSet", {
        sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        dstSet = set,
        dstBinding = binding,
        dstArrayElement = array_element or 0,
        descriptorCount = 1,
        descriptorType = type,
        pImageInfo = image_info
    })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

return M
