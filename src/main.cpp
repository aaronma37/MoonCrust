#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>
#include <luajit-2.1/lua.hpp>
#include <iostream>

// Minimal C++ shell for MoonCrust
// 99% of the engine logic lives in Lua.

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("MoonCrust", 1280, 720, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
    if (!window) {
        std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);

    // Expose SDL_Window and GetInstanceProcAddr to Lua
    lua_pushlightuserdata(L, window);
    lua_setglobal(L, "_SDL_WINDOW");

    lua_pushlightuserdata(L, (void*)SDL_Vulkan_GetVkGetInstanceProcAddr());
    lua_setglobal(L, "_VK_GET_INSTANCE_PROC_ADDR");

    if (luaL_dofile(L, "src/lua/init.lua")) {
        std::cerr << "Lua Error: " << lua_tostring(L, -1) << std::endl;
        return 1;
    }

    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                running = false;
            }
        }

        // Call Lua update
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
