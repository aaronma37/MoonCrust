#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>
#include <luajit-2.1/lua.hpp>
#include <iostream>
#include <vector>
#include <cstring>

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);

    SDL_Window* window = SDL_CreateWindow("MoonCrust", 1280, 720, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
    if (!window) return 1;

    uint32_t sdlExtCount;
    const char* const* sdlExtensions = SDL_Vulkan_GetInstanceExtensions(&sdlExtCount);
    std::vector<const char*> extensions(sdlExtensions, sdlExtensions + sdlExtCount);
    
    VkApplicationInfo appInfo = { VK_STRUCTURE_TYPE_APPLICATION_INFO };
    appInfo.pApplicationName = "MoonCrust";
    appInfo.apiVersion = VK_API_VERSION_1_3;

    VkInstanceCreateInfo createInfo = { VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO };
    createInfo.pApplicationInfo = &appInfo;
    createInfo.enabledExtensionCount = static_cast<uint32_t>(extensions.size());
    createInfo.ppEnabledExtensionNames = extensions.data();

    VkInstance instance;
    if (vkCreateInstance(&createInfo, nullptr, &instance) != VK_SUCCESS) return 1;

    uint32_t gpuCount = 0;
    vkEnumeratePhysicalDevices(instance, &gpuCount, nullptr);
    std::vector<VkPhysicalDevice> gpus(gpuCount);
    vkEnumeratePhysicalDevices(instance, &gpuCount, gpus.data());
    VkPhysicalDevice physicalDevice = gpus[0];

    // Find Graphics Queue Family
    uint32_t queueCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, nullptr);
    std::vector<VkQueueFamilyProperties> queueProps(queueCount);
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, queueProps.data());
    uint32_t graphicsFamily = 0;
    for (uint32_t i = 0; i < queueCount; i++) {
        if (queueProps[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            graphicsFamily = i;
            break;
        }
    }

    VkPhysicalDeviceVulkan13Features features13 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES };
    features13.dynamicRendering = VK_TRUE;
    features13.synchronization2 = VK_TRUE;

    VkPhysicalDeviceDescriptorIndexingFeatures indexing = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES };
    indexing.pNext = &features13;
    indexing.runtimeDescriptorArray = VK_TRUE;
    indexing.descriptorBindingPartiallyBound = VK_TRUE;
    indexing.descriptorBindingStorageBufferUpdateAfterBind = VK_TRUE;
    indexing.descriptorBindingSampledImageUpdateAfterBind = VK_TRUE;

    VkPhysicalDeviceFeatures2 features2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 };
    features2.pNext = &indexing;
    features2.features.vertexPipelineStoresAndAtomics = VK_TRUE;

    float queuePriority = 1.0f;
    VkDeviceQueueCreateInfo qCreateInfo = { VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO };
    qCreateInfo.queueFamilyIndex = graphicsFamily;
    qCreateInfo.queueCount = 1;
    qCreateInfo.pQueuePriorities = &queuePriority;

    const char* devExtensions[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };

    VkDeviceCreateInfo devCreateInfo = { VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO };
    devCreateInfo.pNext = &features2;
    devCreateInfo.queueCreateInfoCount = 1;
    devCreateInfo.pQueueCreateInfos = &qCreateInfo;
    devCreateInfo.enabledExtensionCount = 1;
    devCreateInfo.ppEnabledExtensionNames = devExtensions;

    VkDevice device;
    if (vkCreateDevice(physicalDevice, &devCreateInfo, nullptr, &device) != VK_SUCCESS) return 1;

    VkQueue queue;
    vkGetDeviceQueue(device, graphicsFamily, 0, &queue);

    lua_pushlightuserdata(L, window); lua_setglobal(L, "_SDL_WINDOW");
    lua_pushlightuserdata(L, instance); lua_setglobal(L, "_VK_INSTANCE");
    lua_pushlightuserdata(L, physicalDevice); lua_setglobal(L, "_VK_PHYSICAL_DEVICE");
    lua_pushlightuserdata(L, device); lua_setglobal(L, "_VK_DEVICE");
    lua_pushlightuserdata(L, queue); lua_setglobal(L, "_VK_QUEUE");
    lua_pushinteger(L, graphicsFamily); lua_setglobal(L, "_VK_GRAPHICS_FAMILY");
    lua_pushlightuserdata(L, (void*)SDL_Vulkan_GetVkGetInstanceProcAddr()); lua_setglobal(L, "_VK_GET_INSTANCE_PROC_ADDR");

    if (argc > 1) { lua_pushstring(L, argv[1]); lua_setglobal(L, "_STARTUP_ARG"); }
    if (luaL_dofile(L, "src/lua/init.lua")) return 1;

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) running = false;
            if (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE) running = false;
            if (event.type == SDL_EVENT_MOUSE_MOTION) {
                lua_pushnumber(L, event.motion.x); lua_setglobal(L, "_MOUSE_X");
                lua_pushnumber(L, event.motion.y); lua_setglobal(L, "_MOUSE_Y");
                lua_pushinteger(L, event.motion.windowID); lua_setglobal(L, "_MOUSE_WINDOW");
            }
        }
        lua_getglobal(L, "mooncrust_update");
        if (lua_isfunction(L, -1)) lua_pcall(L, 0, 0, 0);
        else lua_pop(L, 1);
    }

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
