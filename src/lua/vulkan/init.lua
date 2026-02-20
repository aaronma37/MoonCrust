local ffi = require("ffi")
local vk = require("vulkan.ffi")
local sdl = require("vulkan.sdl")

local M = {}

ffi.cdef[[
    typedef void (*PFN_vkVoidFunction)(void);
    typedef PFN_vkVoidFunction (*PFN_vkGetInstanceProcAddr)(void* instance, const char* pName);
    typedef int (*PFN_vkCreateInstance)(const void* pCreateInfo, const void* pAllocator, void* pInstance);
]]

M.sdl = sdl

function M.get_instance()
    return ffi.cast("VkInstance", _VK_INSTANCE)
end

function M.get_physical_device()
    return ffi.cast("VkPhysicalDevice", _VK_PHYSICAL_DEVICE)
end

function M.get_device()
    return ffi.cast("VkDevice", _VK_DEVICE)
end

function M.get_queue()
    return ffi.cast("VkQueue", _VK_QUEUE), _VK_GRAPHICS_FAMILY
end

return M
