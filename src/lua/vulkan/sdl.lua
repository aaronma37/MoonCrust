local ffi = require("ffi")

-- Use ffi.C since mooncrust is already linked with SDL3
local sdl = ffi.C

ffi.cdef[[
    typedef uint64_t SDL_WindowFlags;
    enum {
        SDL_WINDOW_VULKAN = 0x0000000000000002,
        SDL_WINDOW_RESIZABLE = 0x0000000000000020
    };

    void* SDL_CreateWindow(const char* title, int w, int h, SDL_WindowFlags flags);
    char* const* SDL_Vulkan_GetInstanceExtensions(uint32_t* count);
    bool SDL_Vulkan_CreateSurface(void* window, void* instance, void* allocator, void** surface);
    bool SDL_GetWindowSizeInPixels(void* window, int* w, int* h);
    uint64_t SDL_GetTicks(void);
    void SDL_Delay(uint32_t ms);
    uint32_t SDL_GetWindowID(void* window);
]]

return sdl
