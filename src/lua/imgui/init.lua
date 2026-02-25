local ffi = require("ffi")
local ffi_lib = require("imgui.ffi")
local renderer = require("imgui.renderer")
local vulkan = require("vulkan")
local gpu = require("mc.gpu")
local vk = require("vulkan.ffi")
local input = require("mc.input")

local M = {
    -- Persistent storage to prevent GC of pointers passed to C
    _persistence = {}
}

-- ImGui Key Enum (Partial)
local ImGuiKey = {
    Tab = 512, LeftArrow = 513, RightArrow = 514, UpArrow = 515, DownArrow = 516,
    PageUp = 517, PageDown = 518, Home = 519, End = 520,
    Insert = 521, Delete = 522, Backspace = 523, Space = 524,
    Enter = 525, Escape = 526,
    LeftCtrl = 527, LeftShift = 528, LeftAlt = 529, LeftSuper = 530,
    RightCtrl = 531, RightShift = 532, RightAlt = 533, RightSuper = 534,
    _0 = 536, _1 = 537, _2 = 538, _3 = 539, _4 = 540,
    _5 = 541, _6 = 542, _7 = 543, _8 = 544, _9 = 545,
    A = 546, B = 547, C = 548, D = 549, E = 550, F = 551, G = 552,
    H = 553, I = 554, J = 555, K = 556, L = 557, M = 558, N = 559,
    O = 560, P = 561, Q = 562, R = 563, S = 564, T = 565, U = 566,
    V = 567, W = 568, X = 569, Y = 570, Z = 571
}

local key_map = {
    [4]=ImGuiKey.A, [5]=ImGuiKey.B, [6]=ImGuiKey.C, [7]=ImGuiKey.D, [8]=ImGuiKey.E, [9]=ImGuiKey.F, [10]=ImGuiKey.G, [11]=ImGuiKey.H,
    [12]=ImGuiKey.I, [13]=ImGuiKey.J, [14]=ImGuiKey.K, [15]=ImGuiKey.L, [16]=ImGuiKey.M, [17]=ImGuiKey.N, [18]=ImGuiKey.O, [19]=ImGuiKey.P,
    [20]=ImGuiKey.Q, [21]=ImGuiKey.R, [22]=ImGuiKey.S, [23]=ImGuiKey.T, [24]=ImGuiKey.U, [25]=ImGuiKey.V, [26]=ImGuiKey.W, [27]=ImGuiKey.X,
    [28]=ImGuiKey.Y, [29]=ImGuiKey.Z, [30]=ImGuiKey._1, [31]=ImGuiKey._2, [32]=ImGuiKey._3, [33]=ImGuiKey._4, [34]=ImGuiKey._5, [35]=ImGuiKey._6,
    [36]=ImGuiKey._7, [37]=ImGuiKey._8, [38]=ImGuiKey._9, [39]=ImGuiKey._0,
    [40]=ImGuiKey.Enter, [41]=ImGuiKey.Escape, [42]=ImGuiKey.Backspace, [43]=ImGuiKey.Tab, [44]=ImGuiKey.Space,
    [79]=ImGuiKey.RightArrow, [80]=ImGuiKey.LeftArrow, [81]=ImGuiKey.DownArrow, [82]=ImGuiKey.UpArrow,
    [224]=ImGuiKey.LeftCtrl, [225]=ImGuiKey.LeftShift, [226]=ImGuiKey.LeftAlt, [227]=ImGuiKey.LeftSuper,
    [228]=ImGuiKey.RightCtrl, [229]=ImGuiKey.RightShift, [230]=ImGuiKey.RightAlt, [231]=ImGuiKey.RightSuper
}

local char_map = {
    [4]=97, [5]=98, [6]=99, [7]=100, [8]=101, [9]=102, [10]=103, [11]=104, [12]=105, [13]=106, [14]=107, [15]=108, [16]=109, [17]=110, [18]=111, [19]=112,
    [20]=113, [21]=114, [22]=115, [23]=116, [24]=117, [25]=118, [26]=119, [27]=120, [28]=121, [29]=122, [30]=49, [31]=50, [32]=51, [33]=52, [34]=53, [35]=54,
    [36]=55, [37]=56, [38]=57, [39]=48, [44]=32
}

function M.get_glyph_ranges_default()
    return ffi_lib.ImFontAtlas_GetGlyphRangesDefault(ffi_lib.igGetIO_Nil().Fonts)
end

function M.build_and_upload_fonts()
    local io = ffi_lib.igGetIO_Nil()
    
    ffi_lib.igImFontAtlasBuildMain(io.Fonts)
    local tex_data = io.Fonts.TexData
    local w, h, pixels = tex_data.Width, tex_data.Height, tex_data.Pixels
    
    print(string.format("[ImGui] Building Font Atlas: %dx%d", w, h))
    
    local img = gpu.image(w, h, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
    local pd, d, q, family = vulkan.get_physical_device(), vulkan.get_device(), vulkan.get_queue()
    local staging = require("vulkan.staging")
    local size = w * h * 4
    local st = staging.new(pd, d, gpu.heaps.host, size + 1024)
    st:upload_image(img.handle, w, h, pixels, q, family, size)
    
    local descriptors = require("vulkan.descriptors")
    descriptors.update_image_set(d, gpu.get_bindless_set(), 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, img.view, gpu.sampler(), vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)
    
    ffi_lib.ImTextureData_SetTexID(io.Fonts.TexData, ffi.cast("ImTextureID", 0))
    M.font_image = img
    renderer.white_uv = {io.Fonts.TexUvWhitePixel.x, io.Fonts.TexUvWhitePixel.y}
end

function M.add_font(path, size, merge, glyph_ranges)
    local io = ffi_lib.igGetIO_Nil()
    
    local config = ffi_lib.ImFontConfig_ImFontConfig()
    config.MergeMode = merge == true
    config.PixelSnapH = true
    config.RasterizerMultiply = 1.0
    config.RasterizerDensity = 1.0
    
    if glyph_ranges then
        config.GlyphRanges = glyph_ranges
    end
    
    -- Store reference to prevent GC
    table.insert(M._persistence, { config = config, ranges = glyph_ranges })
    
    print(string.format("[ImGui] Loading Font: %s (%.1fpx) merge=%s", path, size, tostring(merge)))
    local font = ffi_lib.ImFontAtlas_AddFontFromFileTTF(io.Fonts, path, size, config, glyph_ranges)
    if font == nil then
        print("[ImGui] ERROR: Failed to load font: " .. path)
        return nil
    end
    return font
end

function M.init()
    M.ctx = ffi_lib.igCreateContext(nil)
    M.plot_ctx = ffi_lib.ImPlot_CreateContext()
    M.plot3d_ctx = ffi_lib.ImPlot3D_CreateContext()
    local io = ffi_lib.igGetIO_Nil()
    io.DisplaySize.x, io.DisplaySize.y = 1280, 720
    renderer.init()
end

function M.new_frame()
    local io = ffi_lib.igGetIO_Nil()
    io.DeltaTime = 1.0 / 60.0
    local lw, lh = _G._WIN_LW or 1280, _G._WIN_LH or 720
    local pw, ph = _G._WIN_PW or lw, _G._WIN_PH or lh
    io.DisplaySize.x, io.DisplaySize.y = lw, lh
    io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y = pw / lw, ph / lh
    
    -- STABLE INPUT FEEDING (Modern Event API)
    local mx, my = input.mouse_pos()
    ffi_lib.ImGuiIO_AddMousePosEvent(io, mx, my)
    ffi_lib.ImGuiIO_AddMouseButtonEvent(io, 0, _G._MOUSE_L == true)
    ffi_lib.ImGuiIO_AddMouseButtonEvent(io, 1, _G._MOUSE_R == true)
    ffi_lib.ImGuiIO_AddMouseButtonEvent(io, 2, _G._MOUSE_M == true)
    ffi_lib.ImGuiIO_AddMouseWheelEvent(io, 0, _G._MOUSE_WHEEL or 0)
    _G._MOUSE_WHEEL = 0

    local shift = input.key_down(225) or input.key_down(229)
    for scancode, im_key in pairs(key_map) do
        if input.key_pressed(scancode) then
            ffi_lib.ImGuiIO_AddKeyEvent(io, im_key, true)
            if char_map[scancode] then
                local c = char_map[scancode]
                if shift and c >= 97 and c <= 122 then c = c - 32 end
                ffi_lib.ImGuiIO_AddInputCharacter(io, c)
            end
        elseif input.key_released(scancode) then
            ffi_lib.ImGuiIO_AddKeyEvent(io, im_key, false)
        end
    end
    
    ffi_lib.igNewFrame()
end

function M.render(cb)
    ffi_lib.igRender()
    local draw_data = ffi_lib.igGetDrawData()
    renderer.on_callback = M.on_callback
    renderer.render(cb, draw_data)
end

M.gui = setmetatable({}, { __index = ffi_lib })
return M
