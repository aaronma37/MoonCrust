local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- Resource Types
M.TYPE_BUFFER = 1
M.TYPE_IMAGE  = 2
M.TYPE_VIEW   = 3
M.TYPE_MEM    = 4

-- State
local current_frame = 0
local death_row = {}
local device_handle = nil

function M.init(device)
    device_handle = device
    current_frame = 0
    death_row = {}
end

function M.tick()
    current_frame = current_frame + 1
    
    local kill_list = death_row[current_frame]
    if kill_list then
        for _, res in ipairs(kill_list) do
            -- Safety: Ensure device is still valid
            if device_handle then
                if res.type == M.TYPE_BUFFER then
                    vk.vkDestroyBuffer(device_handle, ffi.cast("VkBuffer", res.handle), nil)
                elseif res.type == M.TYPE_IMAGE then
                    vk.vkDestroyImage(device_handle, ffi.cast("VkImage", res.handle), nil)
                elseif res.type == M.TYPE_VIEW then
                    vk.vkDestroyImageView(device_handle, ffi.cast("VkImageView", res.handle), nil)
                elseif res.type == M.TYPE_MEM then
                    vk.vkFreeMemory(device_handle, ffi.cast("VkDeviceMemory", res.handle), nil)
                end
                -- print("Resource: Safely destroyed " .. tostring(res.handle))
            end
        end
        death_row[current_frame] = nil
    end
end

function M.free(handle, type)
    if not handle then return end
    
    -- Schedule for death in 3 frames (Triple Buffering safety)
    local kill_frame = current_frame + 3
    
    if not death_row[kill_frame] then 
        death_row[kill_frame] = {} 
    end
    
    table.insert(death_row[kill_frame], { handle = handle, type = type })
end

return M
