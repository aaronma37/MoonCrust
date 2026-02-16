#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>
#include <luajit-2.1/lua.hpp>
#include <iostream>

// Minimal C++ shell for MoonCrust
// 99% of the engine logic lives in Lua.

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

    // Try creating instance in C++
    uint32_t count;
    const char* const* extensions = SDL_Vulkan_GetInstanceExtensions(&count);
    
    VkApplicationInfo appInfo = {};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "MoonCrust";
    appInfo.apiVersion = VK_API_VERSION_1_3;

    VkInstanceCreateInfo createInfo = {};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo = &appInfo;
    createInfo.enabledExtensionCount = count;
    createInfo.ppEnabledExtensionNames = extensions;

    VkInstance instance;
    VkResult result = vkCreateInstance(&createInfo, nullptr, &instance);
    if (result != VK_SUCCESS) {
        std::cerr << "C++ vkCreateInstance failed: " << result << std::endl;
        return 1;
    }
    std::cout << "C++ Trace: Vulkan Instance created at " << instance << std::endl;

    // Pick physical device
    uint32_t gpuCount = 0;
    vkEnumeratePhysicalDevices(instance, &gpuCount, nullptr);
    VkPhysicalDevice gpus[16];
    vkEnumeratePhysicalDevices(instance, &gpuCount, gpus);
    VkPhysicalDevice physicalDevice = gpus[0];

    // Create logical device
    float queuePriority = 1.0f;
    VkDeviceQueueCreateInfo queueCreateInfo = {};
    queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueCreateInfo.queueFamilyIndex = 0;
    queueCreateInfo.queueCount = 1;
    queueCreateInfo.pQueuePriorities = &queuePriority;

    // Enable features
    VkPhysicalDeviceSynchronization2Features sync2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES };
    sync2.synchronization2 = VK_TRUE;

    VkPhysicalDeviceDynamicRenderingFeatures dynamicRendering = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES };
    dynamicRendering.pNext = &sync2;
    dynamicRendering.dynamicRendering = VK_TRUE;

    const char* deviceExtensions[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };

    VkDeviceCreateInfo deviceCreateInfo = {};
    deviceCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    deviceCreateInfo.pNext = &dynamicRendering;
    deviceCreateInfo.queueCreateInfoCount = 1;
    deviceCreateInfo.pQueueCreateInfos = &queueCreateInfo;
    deviceCreateInfo.enabledExtensionCount = 1;
    deviceCreateInfo.ppEnabledExtensionNames = deviceExtensions;

    VkDevice device;
    vkCreateDevice(physicalDevice, &deviceCreateInfo, nullptr, &device);
    std::cout << "C++ Trace: Vulkan Device created at " << device << std::endl;

    VkQueue queue;
    vkGetDeviceQueue(device, 0, 0, &queue);

    void* get_instance_proc_addr = (void*)SDL_Vulkan_GetVkGetInstanceProcAddr();

    lua_pushlightuserdata(L, window);
    lua_setglobal(L, "_SDL_WINDOW");

    lua_pushlightuserdata(L, instance);
    lua_setglobal(L, "_VK_INSTANCE");

    lua_pushlightuserdata(L, physicalDevice);
    lua_setglobal(L, "_VK_PHYSICAL_DEVICE");

    lua_pushlightuserdata(L, device);
    lua_setglobal(L, "_VK_DEVICE");

    lua_pushlightuserdata(L, queue);
    lua_setglobal(L, "_VK_QUEUE");

    lua_pushinteger(L, 0); // graphics_family
    lua_setglobal(L, "_VK_GRAPHICS_FAMILY");

    lua_pushlightuserdata(L, get_instance_proc_addr);
    lua_setglobal(L, "_VK_GET_INSTANCE_PROC_ADDR");

    std::cout << "C++ Trace: Attempting to load src/lua/init.lua" << std::endl;
    if (luaL_dofile(L, "src/lua/init.lua")) {
        std::cerr << "Lua Error: " << lua_tostring(L, -1) << std::endl;
        return 1;
    }
    std::cout << "C++ Trace: src/lua/init.lua loaded successfully" << std::endl;

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                running = false;
            }
        }

        // Call Lua update
        std::cout << "C++ Trace: Calling mooncrust_update" << std::endl;
        lua_getglobal(L, "mooncrust_update");
        if (lua_isfunction(L, -1)) {
            std::cout << "C++ Trace: Function found, invoking pcall" << std::endl;
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
