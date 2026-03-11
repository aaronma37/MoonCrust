#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <volk.h>
#include <lua.hpp>
#include <iostream>
#include <vector>
#include <cstring>
#include <set>
#include <string>
#include "embedded_lua.h"

static int load_embedded_lua(lua_State *L) {
    const char *module_name = luaL_checkstring(L, 1);
    std::string key = module_name;
    
    // Convert Lua module name to our map key (e.g. "vulkan.ffi" -> "vulkan/ffi")
    for (char &c : key) {
        if (c == '.') c = '/';
    }
    
    // Try both exact match (.lua) and directory index (/init.lua)
    std::string file_key = key + ".lua";
    std::string init_key = key + "/init.lua";
    
    auto it = embedded_lua_files.find(file_key);
    if (it == embedded_lua_files.end()) {
        it = embedded_lua_files.find(init_key);
    }
    
    if (it != embedded_lua_files.end()) {
        const auto& data = it->second;
        if (luaL_loadbuffer(L, (const char*)data.first, data.second, it->first.c_str()) == 0) {
            return 1;
        } else {
            return luaL_error(L, "error loading embedded module %s: %s", module_name, lua_tostring(L, -1));
        }
    }
    
    // Let it fall back to standard loaders
    lua_pushstring(L, "\n\tno embedded file '");
    lua_pushstring(L, file_key.c_str());
    lua_pushstring(L, "' or '");
    lua_pushstring(L, init_key.c_str());
    lua_pushstring(L, "'");
    lua_concat(L, 5);
    return 1;
}

static void setup_embedded_loader(lua_State *L) {
    lua_getglobal(L, "package");
    // LuaJIT 2.1 uses 'loaders' instead of 'searchers' (which is Lua 5.2+)
    lua_getfield(L, -1, "loaders");
    if (lua_istable(L, -1)) {
        int num_loaders = lua_objlen(L, -1);
        
        // Push our loader function
        lua_pushcfunction(L, load_embedded_lua);
        
        // Shift existing loaders down
        for (int i = num_loaders; i >= 1; i--) {
            lua_rawgeti(L, -2, i);
            lua_rawseti(L, -3, i + 1);
        }
        
        // Insert our loader at index 2 (after preload)
        lua_rawseti(L, -2, 2);
    }
    lua_pop(L, 2);
}

int main(int argc, char* argv[]) {
    if (volkInitialize() != VK_SUCCESS) {
        std::cerr << "Failed to initialize volk!" << std::endl;
        return 1;
    }

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_AUDIO)) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    if (!SDL_Vulkan_LoadLibrary(nullptr)) {
        std::cerr << "SDL_Vulkan_LoadLibrary failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    setup_embedded_loader(L);

    SDL_Window* window = SDL_CreateWindow("MoonCrust", 1280, 720, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
    if (!window) {
        std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
        return 1;
    }

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
    VkResult res = vkCreateInstance(&createInfo, nullptr, &instance);
    if (res != VK_SUCCESS) {
        std::cerr << "vkCreateInstance failed: " << res << std::endl;
        return 1;
    }
    volkLoadInstance(instance);

    uint32_t gpuCount = 0;
    vkEnumeratePhysicalDevices(instance, &gpuCount, nullptr);
    if (gpuCount == 0) {
        std::cerr << "No GPUs with Vulkan support found" << std::endl;
        return 1;
    }
    std::vector<VkPhysicalDevice> gpus(gpuCount);
    vkEnumeratePhysicalDevices(instance, &gpuCount, gpus.data());
    
    // Select a GPU that supports our required extensions
    VkPhysicalDevice physicalDevice = VK_NULL_HANDLE;
    bool meshShaderSupported = false;

    for (const auto& gpu : gpus) {
        uint32_t extensionCount;
        vkEnumerateDeviceExtensionProperties(gpu, nullptr, &extensionCount, nullptr);
        std::vector<VkExtensionProperties> availableExtensions(extensionCount);
        vkEnumerateDeviceExtensionProperties(gpu, nullptr, &extensionCount, availableExtensions.data());

        bool hasSwapchain = false;
        bool hasMesh = false;
        for (const auto& ext : availableExtensions) {
            if (strcmp(ext.extensionName, VK_KHR_SWAPCHAIN_EXTENSION_NAME) == 0) hasSwapchain = true;
            if (strcmp(ext.extensionName, VK_EXT_MESH_SHADER_EXTENSION_NAME) == 0) hasMesh = true;
        }

        if (hasSwapchain) {
            physicalDevice = gpu;
            meshShaderSupported = hasMesh;
            if (hasMesh) break; // Prefer GPU with mesh shader
        }
    }

    if (physicalDevice == VK_NULL_HANDLE) {
        std::cerr << "No suitable GPU found" << std::endl;
        return 1;
    }

    // Find Graphics Queue Family
    uint32_t queueCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, nullptr);
    std::vector<VkQueueFamilyProperties> queueProps(queueCount);
    vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, queueProps.data());
    uint32_t graphicsFamily = 0;
    bool found = false;
    for (uint32_t i = 0; i < queueCount; i++) {
        if (queueProps[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            graphicsFamily = i;
            found = true;
            break;
        }
    }
    if (!found) {
        std::cerr << "No graphics queue family found" << std::endl;
        return 1;
    }

    VkPhysicalDeviceVulkan13Features features13 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES };
    features13.dynamicRendering = VK_TRUE;
    features13.synchronization2 = VK_TRUE;

    VkPhysicalDeviceDescriptorIndexingFeatures indexing = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES };
    indexing.pNext = &features13;
    indexing.shaderStorageBufferArrayNonUniformIndexing = VK_TRUE;
    indexing.shaderSampledImageArrayNonUniformIndexing = VK_TRUE;
    indexing.shaderStorageImageArrayNonUniformIndexing = VK_TRUE;
    indexing.descriptorBindingPartiallyBound = VK_TRUE;
    indexing.descriptorBindingStorageBufferUpdateAfterBind = VK_TRUE;
    indexing.descriptorBindingSampledImageUpdateAfterBind = VK_TRUE;
    indexing.descriptorBindingStorageImageUpdateAfterBind = VK_TRUE;
    indexing.descriptorBindingUpdateUnusedWhilePending = VK_TRUE;
    indexing.runtimeDescriptorArray = VK_TRUE;

    VkPhysicalDeviceMeshShaderFeaturesEXT meshFeatures = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_EXT };
    meshFeatures.pNext = &indexing;
    meshFeatures.meshShader = meshShaderSupported ? VK_TRUE : VK_FALSE;
    meshFeatures.taskShader = meshShaderSupported ? VK_TRUE : VK_FALSE;

    VkPhysicalDeviceFeatures2 features2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 };
    features2.pNext = &meshFeatures;
    features2.features.vertexPipelineStoresAndAtomics = VK_TRUE;
    features2.features.largePoints = VK_TRUE;
    features2.features.wideLines = VK_TRUE;
    features2.features.shaderStorageImageArrayDynamicIndexing = VK_TRUE;
    features2.features.shaderStorageBufferArrayDynamicIndexing = VK_TRUE;
    features2.features.shaderSampledImageArrayDynamicIndexing = VK_TRUE;
    features2.features.shaderStorageImageReadWithoutFormat = VK_TRUE;
    features2.features.shaderStorageImageWriteWithoutFormat = VK_TRUE;

    float queuePriority = 1.0f;
    VkDeviceQueueCreateInfo qCreateInfo = { VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO };
    qCreateInfo.queueFamilyIndex = graphicsFamily;
    qCreateInfo.queueCount = 1;
    qCreateInfo.pQueuePriorities = &queuePriority;

    std::vector<const char*> devExtensions = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };
    if (meshShaderSupported) {
        devExtensions.push_back(VK_EXT_MESH_SHADER_EXTENSION_NAME);
        std::cout << "Mesh Shader supported and enabled." << std::endl;
    } else {
        std::cout << "Mesh Shader NOT supported by selected GPU." << std::endl;
    }

    VkDeviceCreateInfo devCreateInfo = { VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO };
    devCreateInfo.pNext = &features2;
    devCreateInfo.queueCreateInfoCount = 1;
    devCreateInfo.pQueueCreateInfos = &qCreateInfo;
    devCreateInfo.enabledExtensionCount = static_cast<uint32_t>(devExtensions.size());
    devCreateInfo.ppEnabledExtensionNames = devExtensions.data();

    VkDevice device;
    res = vkCreateDevice(physicalDevice, &devCreateInfo, nullptr, &device);
    if (res != VK_SUCCESS) {
        std::cerr << "vkCreateDevice failed: " << res << std::endl;
        return 1;
    }
    volkLoadDevice(device);

    VkQueue queue;
    vkGetDeviceQueue(device, graphicsFamily, 0, &queue);

    lua_pushlightuserdata(L, window); lua_setglobal(L, "_SDL_WINDOW");
    lua_pushinteger(L, SDL_WINDOW_VULKAN); lua_setglobal(L, "_SDL_WINDOW_VULKAN");
    lua_pushinteger(L, SDL_WINDOW_RESIZABLE); lua_setglobal(L, "_SDL_WINDOW_RESIZABLE");
    lua_pushlightuserdata(L, instance); lua_setglobal(L, "_VK_INSTANCE");
    lua_pushlightuserdata(L, physicalDevice); lua_setglobal(L, "_VK_PHYSICAL_DEVICE");
    lua_pushlightuserdata(L, device); lua_setglobal(L, "_VK_DEVICE");
    lua_pushlightuserdata(L, queue); lua_setglobal(L, "_VK_QUEUE");
    lua_pushinteger(L, graphicsFamily); lua_setglobal(L, "_VK_GRAPHICS_FAMILY");
    lua_pushlightuserdata(L, (void*)SDL_Vulkan_GetVkGetInstanceProcAddr()); lua_setglobal(L, "_VK_GET_INSTANCE_PROC_ADDR");

    // Push all CLI args into a global _ARGS table
    lua_newtable(L);
    for (int i = 0; i < argc; ++i) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i); // Using 0-based indexing to match argv
    }
    lua_setglobal(L, "_ARGS");

    std::string startup_script;
    if (argc > 1) {
        lua_pushstring(L, argv[1]); lua_setglobal(L, "_STARTUP_ARG");
        // If the argument is a directory, append /main.lua
        std::string arg1 = argv[1];
        std::string base_dir;
        
        if (arg1.find(".lua") == std::string::npos) {
            if (arg1.back() != '/' && arg1.back() != '\\') {
                arg1 += "/";
            }
            startup_script = arg1 + "main.lua";
            base_dir = arg1;
        } else {
            startup_script = arg1;
            size_t last_slash = arg1.find_last_of("/\\");
            if (last_slash != std::string::npos) {
                base_dir = arg1.substr(0, last_slash + 1);
            } else {
                base_dir = "./";
            }
        }
        
        // Add the base_dir to package.path
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "path");
        std::string current_path = lua_tostring(L, -1);
        lua_pop(L, 1);
        std::string new_path = base_dir + "?.lua;" + base_dir + "?/init.lua;" + current_path;
        lua_pushstring(L, new_path.c_str());
        lua_setfield(L, -2, "path");
        lua_pop(L, 1);
        
        // Inject globals that normally `src/lua/init.lua` injects so standalone runs match expected environment.
        luaL_dostring(L, "local vulkan = require('vulkan')\n_G.vulkan = vulkan\n_G.mc = require('mc')");
        
    } else {
        // Fallback to embedded init.lua if no arguments are passed
        startup_script = "embedded_init";
    }

    if (startup_script == "embedded_init") {
        if (luaL_dostring(L, "require('init')")) {
            std::cerr << "Lua Error: " << lua_tostring(L, -1) << std::endl;
            return 1;
        }
    } else {
        if (luaL_dofile(L, startup_script.c_str())) {
            std::cerr << "Lua Error: " << lua_tostring(L, -1) << std::endl;
            return 1;
        }
        
        // If the script returned a module table, call init() and setup update()
        if (lua_istable(L, -1)) {
            // Check for init
            lua_getfield(L, -1, "init");
            if (lua_isfunction(L, -1)) {
                if (lua_pcall(L, 0, 0, 0) != 0) {
                    std::cerr << "Init Error: " << lua_tostring(L, -1) << std::endl;
                    lua_pop(L, 1);
                }
            } else {
                lua_pop(L, 1); // pop non-function
            }
            
            // Check for update
            lua_getfield(L, -1, "update");
            if (lua_isfunction(L, -1)) {
                lua_setglobal(L, "_USER_UPDATE");
                luaL_dostring(L, 
                    "function mooncrust_update()\n"
                    "    if mc and mc.tick then mc.tick() end\n"
                    "    _USER_UPDATE()\n"
                    "end"
                );
            } else {
                lua_pop(L, 1); // pop non-function
            }
        }
    }

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) running = false;
            if (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE) running = false;
            
            if (event.type == SDL_EVENT_MOUSE_MOTION) {
                lua_pushnumber(L, event.motion.x); lua_setglobal(L, "_MOUSE_X");
                lua_pushnumber(L, event.motion.y); lua_setglobal(L, "_MOUSE_Y");
            }
            if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN || event.type == SDL_EVENT_MOUSE_BUTTON_UP) {
                bool down = (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN);
                if (event.button.button == SDL_BUTTON_LEFT) { lua_pushboolean(L, down); lua_setglobal(L, "_MOUSE_L"); }
                if (event.button.button == SDL_BUTTON_RIGHT) { lua_pushboolean(L, down); lua_setglobal(L, "_MOUSE_R"); }
                if (event.button.button == SDL_BUTTON_MIDDLE) { lua_pushboolean(L, down); lua_setglobal(L, "_MOUSE_M"); }
                lua_pushnumber(L, event.button.x); lua_setglobal(L, "_MOUSE_X");
                lua_pushnumber(L, event.button.y); lua_setglobal(L, "_MOUSE_Y");
            }
            if (event.type == SDL_EVENT_MOUSE_WHEEL) {
                lua_pushnumber(L, event.wheel.y); lua_setglobal(L, "_MOUSE_WHEEL");
            }
        }
        
        // Push physical resolution as the source of truth every frame
        int pw, ph;
        SDL_GetWindowSizeInPixels(window, &pw, &ph);
        lua_pushinteger(L, pw); lua_setglobal(L, "_WIN_PW");
        lua_pushinteger(L, ph); lua_setglobal(L, "_WIN_PH");
        int lw, lh;
        SDL_GetWindowSize(window, &lw, &lh);
        lua_pushinteger(L, lw); lua_setglobal(L, "_WIN_LW");
        lua_pushinteger(L, lh); lua_setglobal(L, "_WIN_LH");

        lua_getglobal(L, "mooncrust_update");
        if (lua_isfunction(L, -1)) {
            if (lua_pcall(L, 0, 0, 0) != 0) {
                std::cerr << "Update Error: " << lua_tostring(L, -1) << std::endl;
                lua_pop(L, 1);
            }
        } else {
            lua_pop(L, 1);
        }
    }

    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
