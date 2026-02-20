local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- BINDLESS CONSTANTS
local MAX_BINDLESS_RESOURCES = 1000

function M.create_layout(device, bindings_data)
    local count = #bindings_data
    local bindings = ffi.new("VkDescriptorSetLayoutBinding[?]", count)
    for i=0, count-1 do
        bindings[i].binding = bindings_data[i+1].binding
        bindings[i].descriptorType = bindings_data[i+1].type
        bindings[i].descriptorCount = bindings_data[i+1].count or 1
        bindings[i].stageFlags = bindings_data[i+1].stages
    end

    local info = ffi.new("VkDescriptorSetLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        bindingCount = count,
        pBindings = bindings
    })

    local pLayout = ffi.new("VkDescriptorSetLayout[1]")
    local result = vk.vkCreateDescriptorSetLayout(device, info, nil, pLayout)
    if result ~= vk.VK_SUCCESS then error("vkCreateDescriptorSetLayout failed: " .. result) end
    return pLayout[0]
end

function M.create_pool(device, sizes_data)
    local count = #sizes_data
    local sizes = ffi.new("VkDescriptorPoolSize[?]", count)
    for i=0, count-1 do
        sizes[i].type = sizes_data[i+1].type
        sizes[i].descriptorCount = sizes_data[i+1].count
    end

    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        maxSets = 100, -- Default
        poolSizeCount = count,
        pPoolSizes = sizes
    })

    local pPool = ffi.new("VkDescriptorPool[1]")
    local result = vk.vkCreateDescriptorPool(device, info, nil, pPool)
    if result ~= vk.VK_SUCCESS then error("vkCreateDescriptorPool failed: " .. result) end
    return pPool[0]
end

function M.create_bindless_layout(device)
    local count = 6
    local bindings = ffi.new("VkDescriptorSetLayoutBinding[6]")
    local stages = bit.bor(vk.VK_SHADER_STAGE_ALL_GRAPHICS, vk.VK_SHADER_STAGE_COMPUTE_BIT)

    for i=0,5 do
        bindings[i].binding = i
        bindings[i].descriptorCount = (i < 2) and MAX_BINDLESS_RESOURCES or 1
        bindings[i].stageFlags = stages
        if i == 0 then bindings[i].descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
        elseif i == 1 then bindings[i].descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
        else bindings[i].descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE end
    end

    local bindless_flags = bit.bor(
        vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT,
        vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT,
        vk.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT
    )
    
    local flags = ffi.new("VkDescriptorBindingFlags[6]")
    for i=0,1 do flags[i] = bindless_flags end
    for i=2,5 do flags[i] = 0 end

    local binding_flags = ffi.new("VkDescriptorSetLayoutBindingFlagsCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
        bindingCount = 6,
        pBindingFlags = flags
    })

    local info = ffi.new("VkDescriptorSetLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        pNext = binding_flags,
        flags = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
        bindingCount = 6,
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
    sizes[2].descriptorCount = 10 

    local info = ffi.new("VkDescriptorPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        flags = vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
        maxSets = 10,
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
    local buffer_info = ffi.new("VkDescriptorBufferInfo", { buffer = buffer, offset = offset or 0, range = range or vk.VK_WHOLE_SIZE })
    local write = ffi.new("VkWriteDescriptorSet", { sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = set, dstBinding = binding, dstArrayElement = array_element or 0, descriptorCount = 1, descriptorType = type, pBufferInfo = buffer_info })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

function M.update_image_set(device, set, binding, type, view, sampler, layout, array_element)
    local image_info = ffi.new("VkDescriptorImageInfo", { sampler = sampler, imageView = view, imageLayout = layout or vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL })
    local write = ffi.new("VkWriteDescriptorSet", { sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = set, dstBinding = binding, dstArrayElement = array_element or 0, descriptorCount = 1, descriptorType = type, pImageInfo = image_info })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

function M.update_storage_image_set(device, set, binding, type, view, layout, array_element)
    local image_info = ffi.new("VkDescriptorImageInfo", { imageView = view, imageLayout = layout or vk.VK_IMAGE_LAYOUT_GENERAL })
    local write = ffi.new("VkWriteDescriptorSet", { sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = set, dstBinding = binding, dstArrayElement = array_element or 0, descriptorCount = 1, descriptorType = type, pImageInfo = image_info })
    vk.vkUpdateDescriptorSets(device, 1, write, 0, nil)
end

return M
