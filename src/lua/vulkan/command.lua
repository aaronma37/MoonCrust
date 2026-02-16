local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}
local CommandBuffer = {}
CommandBuffer.__index = CommandBuffer

function M.create_pool(device, queue_family_index)
    local pool_info = ffi.new("VkCommandPoolCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        queueFamilyIndex = queue_family_index,
        flags = vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT
    })
    
    local pPool = ffi.new("VkCommandPool[1]")
    local result = vk.vkCreateCommandPool(device, pool_info, nil, pPool)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Command Pool: " .. tostring(result))
    end
    return pPool[0]
end

function M.allocate_buffers(device, pool, count)
    local alloc_info = ffi.new("VkCommandBufferAllocateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        commandPool = pool,
        level = vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        commandBufferCount = count
    })
    
    local pBuffers = ffi.new("VkCommandBuffer[?]", count)
    local result = vk.vkAllocateCommandBuffers(device, alloc_info, pBuffers)
    if result ~= vk.VK_SUCCESS then
        error("Failed to allocate Command Buffers: " .. tostring(result))
    end
    
    local buffers = {}
    for i = 0, count - 1 do
        table.insert(buffers, pBuffers[i])
    end
    return buffers
end

function M.begin_one_time(buffer)
    local begin_info = ffi.new("VkCommandBufferBeginInfo", {
        sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
    })
    local result = vk.vkBeginCommandBuffer(buffer, begin_info)
    if result ~= vk.VK_SUCCESS then
        error("Failed to begin Command Buffer: " .. tostring(result))
    end
end

function M.end_and_submit(buffer, queue, device)
    local result = vk.vkEndCommandBuffer(buffer)
    if result ~= vk.VK_SUCCESS then
        error("Failed to end Command Buffer: " .. tostring(result))
    end
    
    local submit_info = ffi.new("VkSubmitInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        commandBufferCount = 1,
        pCommandBuffers = ffi.new("VkCommandBuffer[1]", {buffer})
    })
    
    -- Using a fence for simple sync for now
    local fence_info = ffi.new("VkFenceCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO
    })
    local pFence = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, fence_info, nil, pFence)
    
    result = vk.vkQueueSubmit(queue, 1, submit_info, pFence[0])
    if result ~= vk.VK_SUCCESS then
        error("Failed to submit Queue: " .. tostring(result))
    end

    result = vk.vkWaitForFences(device, 1, pFence, vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    if result ~= vk.VK_SUCCESS then
        error("Failed to wait for Fences: " .. tostring(result))
    end
    
    vk.vkDestroyFence(device, pFence[0], nil)
end

function M.bind_pipeline(buffer, bind_point, pipeline)
    vk.vkCmdBindPipeline(buffer, bind_point, pipeline)
end

function M.bind_descriptor_sets(buffer, bind_point, layout, first_set, sets)
    local pSets = ffi.new("VkDescriptorSet[?]", #sets)
    for i, s in ipairs(sets) do
        pSets[i-1] = s
    end
    vk.vkCmdBindDescriptorSets(buffer, bind_point, layout, first_set, #sets, pSets, 0, nil)
end

function M.pipeline_barrier(buffer, src_stages, dst_stages, memory_barriers, buffer_barriers, image_barriers)
    local function ensure_ptr(val, type_name)
        if not val then return 0, nil end
        if type(val) == "cdata" then
            -- If it's already a pointer or array, use it directly
            return 1, ffi.cast("const " .. type_name .. "*", val)
        end
        return #val, ffi.new(type_name .. "[?]", #val, val)
    end

    local mem_count, mem_ptr = ensure_ptr(memory_barriers, "VkMemoryBarrier")
    local buf_count, buf_ptr = ensure_ptr(buffer_barriers, "VkBufferMemoryBarrier")
    local img_count, img_ptr = ensure_ptr(image_barriers, "VkImageMemoryBarrier")

    vk.vkCmdPipelineBarrier(
        buffer,
        src_stages,
        dst_stages,
        0,
        mem_count, mem_ptr,
        buf_count, buf_ptr,
        img_count, img_ptr
    )
end

function M.dispatch(buffer, x, y, z)
    vk.vkCmdDispatch(buffer, x, y, z)
end

function M.begin_rendering(buffer, width, height, image_view, image)
    local clear_color = ffi.new("VkClearColorValue")
    clear_color.float32[0] = 0.1
    clear_color.float32[1] = 0.1
    clear_color.float32[2] = 0.1
    clear_color.float32[3] = 1.0

    local range = ffi.new("VkImageSubresourceRange", {
        aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
        baseMipLevel = 0, levelCount = 1,
        baseArrayLayer = 0, layerCount = 1
    })
    
    vk.vkCmdClearColorImage(buffer, image, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, clear_color, 1, range)
end

function M.end_rendering(buffer)
    vk.vkCmdEndRendering(buffer)
end

function M.set_viewport(buffer, width, height)
    local vp = ffi.new("VkViewport", {
        x = 0, y = 0, width = width, height = height, minDepth = 0, maxDepth = 1
    })
    vk.vkCmdSetViewport(buffer, 0, 1, vp)
end

function M.set_scissor(buffer, width, height)
    local sc = ffi.new("VkRect2D", {
        offset = {0, 0}, extent = {width = width, height = height}
    })
    vk.vkCmdSetScissor(buffer, 0, 1, sc)
end

function M.draw(buffer, vertex_count, instance_count, first_vertex, first_instance)
    vk.vkCmdDraw(buffer, vertex_count, instance_count or 1, first_vertex or 0, first_instance or 0)
end

-- Fluent Encoder API
local Encoder = {}
Encoder.__index = Encoder

function Encoder.new(buffer)
    return setmetatable({ buffer = buffer }, Encoder)
end

function Encoder:bind_pipeline(bind_point, pipeline)
    M.bind_pipeline(self.buffer, bind_point, pipeline)
    return self
end

function Encoder:bind_descriptor_sets(bind_point, layout, first_set, sets)
    M.bind_descriptor_sets(self.buffer, bind_point, layout, first_set, sets)
    return self
end

function Encoder:dispatch(x, y, z)
    M.dispatch(self.buffer, x, y, z)
    return self
end

function Encoder:begin_rendering(width, height, image_view)
    M.begin_rendering(self.buffer, width, height, image_view)
    return self
end

function Encoder:end_rendering()
    M.end_rendering(self.buffer)
    return self
end

function Encoder:set_viewport(width, height)
    M.set_viewport(self.buffer, width, height)
    return self
end

function Encoder:set_scissor(width, height)
    M.set_scissor(self.buffer, width, height)
    return self
end

function Encoder:draw(vertex_count, instance_count, first_vertex, first_instance)
    M.draw(self.buffer, vertex_count, instance_count, first_vertex, first_instance)
    return self
end

function Encoder:pipeline_barrier(src_stages, dst_stages, memory_barriers, buffer_barriers, image_barriers)
    M.pipeline_barrier(self.buffer, src_stages, dst_stages, memory_barriers, buffer_barriers, image_barriers)
    return self
end

function M.encode(buffer, callback, ...)
    local enc = Encoder.new(buffer)
    M.begin_one_time(buffer)
    callback(enc, ...)
    local result = vk.vkEndCommandBuffer(buffer)
    if result ~= vk.VK_SUCCESS then
        error("Failed to end Command Buffer in encode(): " .. tostring(result))
    end
end

return M
