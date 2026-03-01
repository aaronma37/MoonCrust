local ffi = require("ffi")
local ffi_loader = require("imgui.ffi")
local renderer = require("imgui.renderer")
local vulkan = require("vulkan")
local gpu = require("mc.gpu")
local vk = require("vulkan.ffi")
local input = require("mc.input")

-- USE GLOBAL STATE TO PREVENT DOUBLE-INIT ACROSS REQUIRES
_G._IMGUI_STATE = _G._IMGUI_STATE or {
    ctx = nil,
    plot_ctx = nil,
    plot3d_ctx = nil,
    ffi_lib = nil,
    persistence = {}
}
local S = _G._IMGUI_STATE

local M = {
    _persistence = S.persistence,
    _S = S
}

-- ImGui StyleVar Enum
M.StyleVar = {
    Alpha = 0, DisabledAlpha = 1, WindowPadding = 2, WindowRounding = 3, WindowBorderSize = 4,
    WindowMinSize = 5, WindowTitleAlign = 6, ChildRounding = 7, ChildBorderSize = 8,
    PopupRounding = 9, PopupBorderSize = 10, FramePadding = 11, FrameRounding = 12,
    FrameBorderSize = 13, ItemSpacing = 14, ItemInnerSpacing = 15, IndentSpacing = 16,
    CellPadding = 17, ScrollbarSize = 18, ScrollbarRounding = 19, GrabMinSize = 20,
    GrabRounding = 21, TabRounding = 22, ButtonTextAlign = 23, SelectableTextAlign = 24
}

-- ImGui Window Flags
M.WindowFlags = {
    None = 0, NoTitleBar = 1, NoResize = 2, NoMove = 4, NoScrollbar = 8,
    NoScrollWithMouse = 16, NoCollapse = 32, AlwaysAutoResize = 64, NoBackground = 128,
    NoSavedSettings = 256, NoMouseInputs = 512, MenuBar = 1024, HorizontalScrollbar = 2048,
    NoFocusOnAppearing = 4096, NoBringToFrontOnFocus = 8192, AlwaysVerticalScrollbar = 16384,
    AlwaysHorizontalScrollbar = 32768, NoNavInputs = 65536, NoNavFocus = 131072,
    UnsavedDocument = 262144, NoDocking = 524288, NoNav = 196608, NoDecoration = 43,
    NoInputs = 197120, DockNodeHost = 8388608
}

-- ImGui Key Enum (Corrected to match imgui.h)
local ImGuiKey = {
    Tab = 512, LeftArrow = 513, RightArrow = 514, UpArrow = 515, DownArrow = 516,
    PageUp = 517, PageDown = 518, Home = 519, End = 520,
    Insert = 521, Delete = 522, Backspace = 523, Space = 524,
    Enter = 525, Escape = 526,
    LeftCtrl = 527, LeftShift = 528, LeftAlt = 529, LeftSuper = 530,
    RightCtrl = 531, RightShift = 532, RightAlt = 533, RightSuper = 534,
    Menu = 535,
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
    [45]=552, -- Minus
    [46]=553, -- Equals
    [47]=554, -- LeftBracket
    [48]=555, -- RightBracket
    [49]=556, -- Backslash
    [51]=558, -- Semicolon
    [52]=559, -- Apostrophe
    [53]=560, -- Grave
    [54]=561, -- Comma
    [55]=562, -- Period
    [56]=563, -- Slash
    [76]=ImGuiKey.Delete,
    [79]=ImGuiKey.RightArrow, [80]=ImGuiKey.LeftArrow, [81]=ImGuiKey.DownArrow, [82]=ImGuiKey.UpArrow,
    [224]=ImGuiKey.LeftCtrl, [225]=ImGuiKey.LeftShift, [226]=ImGuiKey.LeftAlt, [227]=ImGuiKey.LeftSuper,
    [228]=ImGuiKey.RightCtrl, [229]=ImGuiKey.RightShift, [230]=ImGuiKey.RightAlt, [231]=ImGuiKey.RightSuper
}

local char_map = {
    [4]=97, [5]=98, [6]=99, [7]=100, [8]=101, [9]=102, [10]=103, [11]=104, [12]=105, [13]=106, [14]=107, [15]=108, [16]=109, [17]=110, [18]=111, [19]=112,
    [20]=113, [21]=114, [22]=115, [23]=116, [24]=117, [25]=118, [26]=119, [27]=120, [28]=121, [29]=122, [30]=49, [31]=50, [32]=51, [33]=52, [34]=53, [35]=54,
    [36]=55, [37]=56, [38]=57, [39]=48, [44]=32,
    [45]=45, [46]=61, [47]=91, [48]=93, [49]=92, [51]=59, [52]=39, [53]=96, [54]=44, [55]=46, [56]=47
}

local shift_char_map = {
    [30]=33, [31]=64, [32]=35, [33]=36, [34]=37, [35]=94, [36]=38, [37]=42, [38]=40, [39]=41,
    [45]=95, [46]=43, [47]=123, [48]=125, [49]=124, [51]=58, [52]=34, [53]=126, [54]=60, [55]=62, [56]=63
}

function M.get_glyph_ranges_default()
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    return S.ffi_lib.ImFontAtlas_GetGlyphRangesDefault(S.ffi_lib.igGetIO_Nil().Fonts)
end

function M.get_font(index)
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    local io = S.ffi_lib.igGetIO_Nil()
    local fonts = io.Fonts.Fonts
    if index >= 0 and index < fonts.Size then
        local data = ffi.cast("void**", fonts.Data)
        return data[index]
    end
    return nil
end

function M.build_and_upload_fonts()
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    local io = S.ffi_lib.igGetIO_Nil()
    io.Fonts.TexMaxWidth = 4096
    io.Fonts.TexMaxHeight = 4096
    
    S.ffi_lib.igImFontAtlasBuildMain(io.Fonts)
    local tex_data = io.Fonts.TexData
    local w, h, pixels = tex_data.Width, tex_data.Height, tex_data.Pixels
    
    print(string.format("[ImGui] Building Font Atlas: %dx%d", w, h))
    
    local img = gpu.image(w, h, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled_attachment")
    local pd, d, q, family = vulkan.get_physical_device(), vulkan.get_device(), vulkan.get_queue()
    local staging = require("vulkan.staging")
    local size = w * h * 4
    local st = staging.new(pd, d, gpu.heaps.host, size + 1024 * 1024)
    st:upload_image(img.handle, w, h, pixels, q, family, size)
    
    local descriptors = require("vulkan.descriptors")
    local sharp_sampler = gpu.sampler(vk.VK_FILTER_NEAREST)
    descriptors.update_image_set(d, gpu.get_bindless_set(), 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, img.view, sharp_sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)
    
    S.ffi_lib.ImTextureData_SetTexID(io.Fonts.TexData, ffi.cast("ImTextureID", 0))
    M.font_image = img
    renderer.white_uv = {io.Fonts.TexUvWhitePixel.x, io.Fonts.TexUvWhitePixel.y}
end

function M.add_font(path, size, merge, glyph_ranges)
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    local io = S.ffi_lib.igGetIO_Nil()
    
    local config = S.ffi_lib.ImFontConfig_ImFontConfig()
    config.MergeMode = merge == true
    config.PixelSnapH = true
    config.RasterizerMultiply = 1.0
    config.RasterizerDensity = 1.0
    
    if glyph_ranges then config.GlyphRanges = glyph_ranges end
    table.insert(S.persistence, { config = config, ranges = glyph_ranges })
    
    print(string.format("[ImGui] Loading Font: %s (%.1fpx) merge=%s", path, size, tostring(merge)))
    local font = S.ffi_lib.ImFontAtlas_AddFontFromFileTTF(io.Fonts, path, size, config, glyph_ranges)
    if font == nil then
        print("[ImGui] ERROR: Failed to load font: " .. path)
        return nil
    end
    return font
end

function M.init()
    if S.ctx then return end
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    S.ctx = S.ffi_lib.igCreateContext(nil)
    S.plot_ctx = S.ffi_lib.ImPlot_CreateContext()
    S.plot3d_ctx = S.ffi_lib.ImPlot3D_CreateContext()
    local io = S.ffi_lib.igGetIO_Nil()
    io.DisplaySize.x, io.DisplaySize.y = 1280, 720
    io.ConfigFlags = bit.bor(io.ConfigFlags, 1) -- ImGuiConfigFlags_NavEnableKeyboard
    
    -- ENABLE ANTI-ALIASING
    local style = S.ffi_lib.igGetStyle()
    style.AntiAliasedLines = true
    style.AntiAliasedFill = true
    style.AntiAliasedLinesUseTex = true
    
    M.build_and_upload_fonts()
    renderer.init()
end

function M.new_frame()
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    local io = S.ffi_lib.igGetIO_Nil()
    io.DeltaTime = 1.0 / 60.0
    local lw, lh = _G._WIN_LW or 1280, _G._WIN_LH or 720
    local pw, ph = _G._WIN_PW or lw, _G._WIN_PH or lh
    io.DisplaySize.x, io.DisplaySize.y = lw, lh
    io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y = pw / lw, ph / lh
    
    local mx, my = input.mouse_pos()
    S.ffi_lib.ImGuiIO_AddMousePosEvent(io, mx, my)
    
    -- Sync mouse buttons: Transition events + Current state fallback
    for i=1, 3 do
        local im_btn = (i == 1) and 0 or (i == 3 and 1 or 2)
        local is_down = input.mouse_down(i)
        if input.mouse_pressed(i) then
            S.ffi_lib.ImGuiIO_AddMouseButtonEvent(io, im_btn, true)
        elseif input.mouse_released(i) then
            S.ffi_lib.ImGuiIO_AddMouseButtonEvent(io, im_btn, false)
        else
            -- Ensure state is correct even if transitions were messy
            S.ffi_lib.ImGuiIO_AddMouseButtonEvent(io, im_btn, is_down)
        end
    end
    
    S.ffi_lib.ImGuiIO_AddMouseWheelEvent(io, 0, _G._MOUSE_WHEEL or 0)
    _G._MOUSE_WHEEL = 0

    local shift = input.key_down(225) or input.key_down(229)
    local ctrl = input.key_down(224) or input.key_down(228)

    if shift and ctrl and input.mouse_pressed(1) then
        print(string.format("[IMGUI DEBUG] MousePos=(%.1f, %.1f) WantCaptureMouse=%s", mx, my, tostring(io.WantCaptureMouse)))
    end
    for scancode, im_key in pairs(key_map) do
        if input.key_pressed(scancode) then
            S.ffi_lib.ImGuiIO_AddKeyEvent(io, im_key, true)
            if char_map[scancode] then
                local c = char_map[scancode]
                if shift then
                    if shift_char_map[scancode] then c = shift_char_map[scancode]
                    elseif c >= 97 and c <= 122 then c = c - 32 end
                end
                S.ffi_lib.ImGuiIO_AddInputCharacter(io, c)
            end
        elseif input.key_released(scancode) then
            S.ffi_lib.ImGuiIO_AddKeyEvent(io, im_key, false)
        end
    end
    
    S.ffi_lib.igNewFrame()
end

function M.render(cb)
    if not S.ffi_lib then S.ffi_lib = ffi_loader() end
    S.ffi_lib.igRender()
    local draw_data = S.ffi_lib.igGetDrawData()
    renderer.on_callback = M.on_callback
    renderer.render(cb, draw_data)
end

M.gui = setmetatable({}, { 
    __index = function(t, k)
        if M[k] ~= nil then return M[k] end
        if not S.ffi_lib then S.ffi_lib = ffi_loader() end
        if k:find("ImGuiStyleVar_") == 1 then return M.StyleVar[k:sub(15)] end
        if k:find("ImGuiWindowFlags_") == 1 then return M.WindowFlags[k:sub(18)] end
        return S.ffi_lib[k]
    end
})
return M
