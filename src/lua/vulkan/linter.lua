local vk = require("vulkan.ffi")
local ffi = require("ffi")

local M = {}

local stype_map = {
    VkBufferCreateInfo = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
    VkImageCreateInfo = vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
    VkMemoryBarrier = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
    VkGraphicsPipelineCreateInfo = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
    VkComputePipelineCreateInfo = vk.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
    VkSubmitInfo = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
    VkCommandBufferBeginInfo = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    VkRenderPassBeginInfo = vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
    VkPipelineLayoutCreateInfo = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
    VkDescriptorSetLayoutCreateInfo = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
    VkImageMemoryBarrier = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
    VkBufferMemoryBarrier = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
    VkImageViewCreateInfo = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
    VkSamplerCreateInfo = vk.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
    VkDescriptorPoolCreateInfo = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
    VkDescriptorSetAllocateInfo = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
    VkWriteDescriptorSet = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
    VkRenderingInfo = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
    VkRenderingAttachmentInfo = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
    VkSemaphoreCreateInfo = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    VkFenceCreateInfo = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
    VkCommandPoolCreateInfo = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
}

function M.check(struct_type, data)
    local expected_stype = stype_map[struct_type]
    if not expected_stype then return true end
    
    if data.sType ~= expected_stype then
        print(string.format("[VULKAN LINTER] Error in %s: sType mismatch. Expected %d, got %d", struct_type, expected_stype, data.sType))
        return false
    end
    return true
end

function M.lint_file(path)
    local f = io.open(path, "r")
    if not f then return end
    local content = f.read(f, "*all")
    f:close()

    -- Iterate through all ffi.new calls
    local offset = 1
    while true do
        local s, e, struct = content:find('ffi%.new%s*%(%s*["\'](Vk[A-Za-z0-9]+)[^"\']*["\']', offset)
        if not s then break end
        
        if stype_map[struct] then
            -- Find the initialization block or assignments following this ffi.new
            -- We search the next 200 characters for 'sType'
            local chunk = content:sub(e + 1, e + 300)
            if not chunk:find("sType") then
                -- Double check: maybe it's assigned to a variable and sType is set later?
                -- Find the variable name before 'ffi.new'
                local line_start = content:reverse():find("\n", content:len() - s + 1)
                if line_start then
                    line_start = content:len() - line_start + 1
                else
                    line_start = 1
                end
                local line = content:sub(line_start, e)
                local varname = line:match("local%s+([A-Za-z0-9_]+)%s*=")
                
                if varname then
                    -- Search rest of file for varname.sType
                    local rest = content:sub(e + 1)
                    if not rest:find(varname .. "%.sType") and not rest:find(varname .. "%[.*%]%.sType") then
                        print(string.format("[VULKAN LINTER] WARNING in %s: %s (via %s) missing 'sType' assignment.", path, struct, varname))
                    end
                else
                    -- No variable name, must be an inline table or literal
                    print(string.format("[VULKAN LINTER] WARNING in %s: ffi.new(\"%s\", ...) likely missing 'sType'.", path, struct))
                end
            end
        end
        offset = e + 1
    end
end

return M
