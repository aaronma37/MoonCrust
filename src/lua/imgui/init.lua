local ffi = require("ffi")
local ffi_lib = require("imgui.ffi")
local renderer = require("imgui.renderer")
local vulkan = require("vulkan")
local gpu = require("mc.gpu")
local vk = require("vulkan.ffi")
local input = require("mc.input")

local M = {}

function M.init()
    M.ctx = ffi_lib.igCreateContext(nil)
    M.plot_ctx = ffi_lib.ImPlot_CreateContext()
    M.plot3d_ctx = ffi_lib.ImPlot3D_CreateContext()
    
    local io = ffi_lib.igGetIO_Nil()
    io.DisplaySize.x = 1280
    io.DisplaySize.y = 720
    
    renderer.init()
    
    -- Setup Font Texture
    if not io.Fonts.TexIsBuilt then
        ffi_lib.igImFontAtlasBuildMain(io.Fonts)
    end
    
    local tex_data = io.Fonts.TexData
    
    local w = tex_data.Width
    local h = tex_data.Height
    local pixels = tex_data.Pixels
    
    local img = gpu.image(w, h, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
    
    -- Upload Font
    local pd = vulkan.get_physical_device()
    local d = vulkan.get_device()
    local q, family = vulkan.get_queue()
    local staging = require("vulkan.staging")
    local size = w * h * 4
    local st = staging.new(pd, d, gpu.heaps.host, size + 1024)
    st:upload_image(img.handle, w, h, pixels, q, family, size)
    
    -- Register to Bindless Set (using index 0 for font)
    local descriptors = require("vulkan.descriptors")
    local sampler = gpu.sampler()
    descriptors.update_image_set(d, gpu.get_bindless_set(), 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)
    
    ffi_lib.ImTextureData_SetTexID(io.Fonts.TexData, ffi.cast("ImTextureID", 0))
    M.font_image = img
end

function M.new_frame()
    local io = ffi_lib.igGetIO_Nil()
    io.DeltaTime = 1.0 / 60.0 -- TODO: Proper delta
    
    -- Hallmark #6: Use the C++ source of truth for resolution
    local lw = _G._WIN_LW or 1280
    local lh = _G._WIN_LH or 720
    local pw = _G._WIN_PW or lw
    local ph = _G._WIN_PH or lh

    io.DisplaySize.x = lw
    io.DisplaySize.y = lh
    io.DisplayFramebufferScale.x = pw / lw
    io.DisplayFramebufferScale.y = ph / lh
    
    io.MousePos.x, io.MousePos.y = input.mouse_pos()
    io.MouseDown[0] = _G._MOUSE_L == true
    io.MouseDown[1] = _G._MOUSE_R == true
    io.MouseDown[2] = _G._MOUSE_M == true
    
    io.MouseWheel = _G._MOUSE_WHEEL or 0
    _G._MOUSE_WHEEL = 0 -- Reset after consumption
    
    ffi_lib.igNewFrame()
end

function M.render(cb)
    ffi_lib.igRender()
    local draw_data = ffi_lib.igGetDrawData()
    renderer.on_callback = M.on_callback
    renderer.render(cb, draw_data)
end

-- Expose ImGui functions as a table
M.gui = ffi_lib

return M
