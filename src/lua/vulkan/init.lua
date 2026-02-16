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

function M.create_instance(app_name)
    local get_proc = ffi.cast("PFN_vkGetInstanceProcAddr", _VK_GET_INSTANCE_PROC_ADDR)
    local vkCreateInstance_ptr = get_proc(nil, "vkCreateInstance")
    local vkCreateInstance = ffi.cast("PFN_vkCreateInstance", vkCreateInstance_ptr)

    local app_info = ffi.new("VkApplicationInfo", {
        sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        pApplicationName = app_name,
        applicationVersion = 1,
        pEngineName = "MoonCrust",
        engineVersion = 1,
        apiVersion = vk.VK_API_VERSION_1_3
    })

    local sdl_exts = ffi.new("const char*[2]", {"VK_KHR_surface", "VK_KHR_xlib_surface"})
    local layers = ffi.new("const char*[1]", {"VK_LAYER_KHRONOS_validation"})

    local inst_info = ffi.new("VkInstanceCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pApplicationInfo = app_info,
        enabledExtensionCount = 2,
        ppEnabledExtensionNames = sdl_exts,
        enabledLayerCount = 1,
        ppEnabledLayerNames = layers
    })

    local pInstance = ffi.new("VkInstance[1]")
    local result = vkCreateInstance(inst_info, nil, pInstance)
    
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Vulkan Instance: " .. tostring(result))
    end

    return pInstance[0]
end

function M.select_physical_device(instance)
    local pCount = ffi.new("uint32_t[1]")
    vk.vkEnumeratePhysicalDevices(instance, pCount, nil)
    
    if pCount[0] == 0 then
        error("No Vulkan-compatible GPUs found.")
    end

    local pDevices = ffi.new("VkPhysicalDevice[?]", pCount[0])
    vk.vkEnumeratePhysicalDevices(instance, pCount, pDevices)

    -- Simple selection: just take the first one for now
    -- In a real kernel, we'd score them based on VRAM and features
    local device = pDevices[0]
    
    local props = ffi.new("VkPhysicalDeviceProperties")
    vk.vkGetPhysicalDeviceProperties(device, props)
    print("Selected GPU:", ffi.string(props.deviceName))

    return device
end

function M.create_device(physical_device)
    -- Find a queue family that supports graphics
    local qCount = ffi.new("uint32_t[1]")
    vk.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, qCount, nil)
    local qProps = ffi.new("VkQueueFamilyProperties[?]", qCount[0])
    vk.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, qCount, qProps)

    local graphics_family = -1
    for i = 0, qCount[0] - 1 do
        if bit.band(qProps[i].queueFlags, vk.VK_QUEUE_GRAPHICS_BIT) ~= 0 then
            graphics_family = i
            break
        end
    end

    if graphics_family == -1 then
        error("No graphics queue family found.")
    end

    local priorities = ffi.new("float[1]", {1.0})
    local q_info = ffi.new("VkDeviceQueueCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        queueFamilyIndex = graphics_family,
        queueCount = 1,
        pQueuePriorities = priorities
    })

    local sync2_features = ffi.new("VkPhysicalDeviceSynchronization2Features", {
        sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
        synchronization2 = vk.VK_TRUE
    })

    local dynamic_rendering_features = ffi.new("VkPhysicalDeviceDynamicRenderingFeatures", {
        sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
        pNext = sync2_features,
        dynamicRendering = vk.VK_TRUE
    })

    local shader_features = ffi.new("VkPhysicalDeviceShaderSubgroupExtendedTypesFeatures", {
        sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES,
        pNext = dynamic_rendering_features,
        shaderSubgroupExtendedTypes = vk.VK_TRUE
    })

    -- We need this for buffer reading in vertex shader
    local extra_features = ffi.new("VkPhysicalDeviceFeatures2", {
        sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
        pNext = shader_features,
        features = { vertexPipelineStoresAndAtomics = vk.VK_TRUE }
    })

    local extensions = ffi.new("const char*[1]", {"VK_KHR_swapchain"})
    local dev_info = ffi.new("VkDeviceCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        pNext = extra_features,
        queueCreateInfoCount = 1,
        pQueueCreateInfos = q_info,
        enabledExtensionCount = 1,
        ppEnabledExtensionNames = extensions
    })

    local pDevice = ffi.new("VkDevice[1]")
    local result = vk.vkCreateDevice(physical_device, dev_info, nil, pDevice)
    
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Vulkan Device: " .. tostring(result))
    end

    return pDevice[0], graphics_family
end

function M.get_queue(device, queue_family_index, queue_index)
    local pQueue = ffi.new("VkQueue[1]")
    vk.vkGetDeviceQueue(device, queue_family_index, queue_index or 0, pQueue)
    return pQueue[0]
end

return M
