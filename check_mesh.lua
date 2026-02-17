local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")

function M_init()
    local pd = vulkan.get_physical_device()
    local count = ffi.new("uint32_t[1]")
    vk.vkEnumerateDeviceExtensionProperties(pd, nil, count, nil)
    local props = ffi.new("VkExtensionProperties[?]", count[0])
    vk.vkEnumerateDeviceExtensionProperties(pd, nil, count, props)
    
    local found = false
    for i=0, count[0]-1 do
        local name = ffi.string(props[i].extensionName)
        if name == "VK_EXT_mesh_shader" then
            print("FOUND: VK_EXT_mesh_shader revision " .. props[i].specVersion)
            found = true
        end
    end
    if not found then print("NOT FOUND: VK_EXT_mesh_shader") end
    os.exit()
end

M_init()
