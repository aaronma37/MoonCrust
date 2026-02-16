#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>
#include <luajit-2.1/lua.hpp>
#include <iostream>
#include <vector>

// MoonCrust Universal Bootstrapper
// This file handles the 1% of engine logic that is too fragile for LuaJIT FFI.

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);

    SDL_Window* window = SDL_CreateWindow("MoonCrust", 1280, 720, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
    if (!window) {
        std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    // 1. Instance Creation (Universal Extensions)
    uint32_t sdlExtCount;
    const char* const* sdlExtensions = SDL_Vulkan_GetInstanceExtensions(&sdlExtCount);
    
    std::vector<const char*> extensions(sdlExtensions, sdlExtensions + sdlExtCount);
    
    // Check if portability enumeration is supported (Required for some drivers like MoltenVK/Mesa)
    uint32_t propCount;
    vkEnumerateInstanceExtensionProperties(nullptr, &propCount, nullptr);
    std::vector<VkExtensionProperties> props(propCount);
    vkEnumerateInstanceExtensionProperties(nullptr, &propCount, props.data());
    
    bool usePortability = false;
    for (const auto& p : props) {
        if (strcmp(p.extensionName, "VK_KHR_portability_enumeration") == 0) {
            extensions.push_back("VK_KHR_portability_enumeration");
            usePortability = true;
            break;
        }
    }

    VkApplicationInfo appInfo = {};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "MoonCrust";
    appInfo.apiVersion = VK_API_VERSION_1_3;

    VkInstanceCreateInfo createInfo = {};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo = &appInfo;
    createInfo.enabledExtensionCount = static_cast<uint32_t>(extensions.size());
    createInfo.ppEnabledExtensionNames = extensions.data();
    if (usePortability) createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;

    VkInstance instance;
    if (vkCreateInstance(&createInfo, nullptr, &instance) != VK_SUCCESS) {
        std::cerr << "Universal vkCreateInstance failed." << std::endl;
        return 1;
    }

    // 2. Physical Device selection
    uint32_t gpuCount = 0;
    vkEnumeratePhysicalDevices(instance, &gpuCount, nullptr);
    std::vector<VkPhysicalDevice> gpus(gpuCount);
    vkEnumeratePhysicalDevices(instance, &gpuCount, gpus.data());
    VkPhysicalDevice physicalDevice = gpus[0]; 

    // 3. Find Graphics Queue Family Dynamically
    uint32_t queueCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, nullptr);
    std::vector<VkQueueFamilyProperties> queueProps(queueCount);
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, queueProps.data());

    int graphicsFamily = -1;
    for (uint32_t i = 0; i < queueCount; i++) {
        if (queueProps[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            graphicsFamily = i;
            break;
        }
    }

    if (graphicsFamily == -1) {
        std::cerr << "No graphics queue found." << std::endl;
        return 1;
    }

    // 4. Logical Device with required 1.3 features
    float queuePriority = 1.0f;
    VkDeviceQueueCreateInfo qCreateInfo = {};
    qCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    qCreateInfo.queueFamilyIndex = graphicsFamily;
    qCreateInfo.queueCount = 1;
    qCreateInfo.pQueuePriorities = &queuePriority;

    VkPhysicalDeviceSynchronization2Features sync2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES };
    sync2.synchronization2 = VK_TRUE;

    VkPhysicalDeviceDynamicRenderingFeatures dynRender = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES };
    dynRender.pNext = &sync2;
    dynRender.dynamicRendering = VK_TRUE;

    VkPhysicalDeviceDescriptorIndexingFeatures indexing = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES };
    indexing.pNext = &dynRender;
    indexing.descriptorBindingPartiallyBound = VK_TRUE;
    indexing.descriptorBindingStorageBufferUpdateAfterBind = VK_TRUE;
    indexing.descriptorBindingSampledImageUpdateAfterBind = VK_TRUE; // Added for textures
    indexing.runtimeDescriptorArray = VK_TRUE;
    indexing.descriptorBindingVariableDescriptorCount = VK_TRUE;

    VkPhysicalDeviceFeatures2 deviceFeatures = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 };
    deviceFeatures.pNext = &indexing;
    deviceFeatures.features.vertexPipelineStoresAndAtomics = VK_TRUE;

    const char* devExtensions[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };

    VkDeviceCreateInfo devCreateInfo = {};
    devCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    devCreateInfo.pNext = &deviceFeatures;
    devCreateInfo.queueCreateInfoCount = 1;
    devCreateInfo.pQueueCreateInfos = &qCreateInfo;
    devCreateInfo.enabledExtensionCount = 1;
    devCreateInfo.ppEnabledExtensionNames = devExtensions;

    VkDevice device;
    if (vkCreateDevice(physicalDevice, &devCreateInfo, nullptr, &device) != VK_SUCCESS) {
        std::cerr << "vkCreateDevice failed." << std::endl;
        return 1;
    }

    VkQueue queue;
    vkGetDeviceQueue(device, graphicsFamily, 0, &queue);

    // Hand off handles to Lua
    lua_pushlightuserdata(L, window); lua_setglobal(L, "_SDL_WINDOW");
    lua_pushlightuserdata(L, instance); lua_setglobal(L, "_VK_INSTANCE");
    lua_pushlightuserdata(L, physicalDevice); lua_setglobal(L, "_VK_PHYSICAL_DEVICE");
    lua_pushlightuserdata(L, device); lua_setglobal(L, "_VK_DEVICE");
    lua_pushlightuserdata(L, queue); lua_setglobal(L, "_VK_QUEUE");
    lua_pushinteger(L, graphicsFamily); lua_setglobal(L, "_VK_GRAPHICS_FAMILY");
    lua_pushlightuserdata(L, (void*)SDL_Vulkan_GetVkGetInstanceProcAddr()); lua_setglobal(L, "_VK_GET_INSTANCE_PROC_ADDR");

    if (luaL_dofile(L, "src/lua/init.lua")) {
        std::cerr << "Lua Error: " << lua_tostring(L, -1) << std::endl;
        return 1;
    }

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) running = false;
        }

        lua_getglobal(L, "mooncrust_update");
        if (lua_isfunction(L, -1)) {
            if (lua_pcall(L, 0, 0, 0) != 0) {
                std::cerr << "Lua Update Error: " << lua_tostring(L, -1) << std::endl;
                running = false;
            }
        } else {
            lua_pop(L, 1);
        }
    }

    lua_close(L);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
