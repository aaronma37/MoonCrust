local ffi = require("ffi")

-- Use ffi.C since mooncrust is already linked with SDL3.
-- Do NOT use ffi.load("SDL3") as it creates a second, uninitialized instance of SDL.
local sdl_ffi = ffi.C

-- Note: SDL3 uses different types than SDL2.
-- We only declare what we strictly need for the Lua side.
ffi.cdef[[
    typedef uint64_t SDL_WindowFlags;

    void* SDL_CreateWindow(const char* title, int w, int h, SDL_WindowFlags flags);
    void SDL_DestroyWindow(void* window);
    uint32_t SDL_GetWindowID(void* window);
    bool SDL_Vulkan_CreateSurface(void* window, void* instance, void* allocator, void** surface);
    bool SDL_GetWindowSize(void* window, int* w, int* h);
    bool SDL_GetWindowSizeInPixels(void* window, int* w, int* h);
    bool SDL_MaximizeWindow(void* window);
    bool SDL_SetWindowFullscreen(void* window, bool fullscreen);
    
    uint32_t SDL_GetMouseState(float* x, float* y);
    uint32_t SDL_GetRelativeMouseState(float* x, float* y);
    const uint8_t* SDL_GetKeyboardState(int* numkeys);
    
    uint64_t SDL_GetTicks(void);
    uint64_t SDL_GetPerformanceCounter(void);
    uint64_t SDL_GetPerformanceFrequency(void);
    void SDL_Delay(uint32_t ms);
    
    const char* SDL_GetError(void);

    typedef uint32_t SDL_AudioDeviceID;
    typedef uint32_t SDL_AudioFormat;
    
    typedef struct SDL_AudioSpec {
        SDL_AudioFormat format;
        int channels;
        int freq;
    } SDL_AudioSpec;

    void* SDL_OpenAudioDeviceStream(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec, void* callback, void *userdata);
    bool SDL_ResumeAudioStreamDevice(void *stream);
    bool SDL_PutAudioStreamData(void *stream, const void *data, int len);
    int SDL_GetAudioStreamQueued(void *stream);
    void SDL_DestroyAudioStream(void *stream);
]]

local M = {
    -- Pull actual values from C++ bootstrapper
    SDL_WINDOW_VULKAN = _G._SDL_WINDOW_VULKAN,
    SDL_WINDOW_RESIZABLE = _G._SDL_WINDOW_RESIZABLE,
    SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK = 0xFFFFFFFF,
    SDL_AUDIO_F32 = 0x8120,
    SDL_SCANCODE_SPACE = 44,
    SDL_SCANCODE_A = 4,
}

setmetatable(M, {
    __index = function(t, k)
        local ok, val = pcall(function() return sdl_ffi[k] end)
        if ok then return val end
        error("SDL symbol not found: " .. tostring(k))
    end
})

return M
