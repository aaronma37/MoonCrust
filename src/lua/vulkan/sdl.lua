local ffi = require("ffi")

-- Use ffi.C since mooncrust is already linked with SDL3
local sdl = ffi.C

ffi.cdef[[
    const char* const* SDL_Vulkan_GetInstanceExtensions(uint32_t* count);
    bool SDL_Vulkan_CreateSurface(void* window, void* instance, void* allocator, void** surface);
    bool SDL_GetWindowSizeInPixels(void* window, int* w, int* h);
]]

return sdl
