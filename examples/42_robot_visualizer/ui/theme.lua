local ffi = require("ffi")

local M = {}

-- ImGuiCol enum values
local Col = {
    Text = 0, TextDisabled = 1, WindowBg = 2, ChildBg = 3, PopupBg = 4,
    Border = 5, BorderShadow = 6, FrameBg = 7, FrameBgHovered = 8, FrameBgActive = 9,
    TitleBg = 10, TitleBgActive = 11, TitleBgCollapsed = 12, MenuBarBg = 13,
    ScrollbarBg = 14, ScrollbarGrab = 15, ScrollbarGrabHovered = 16, ScrollbarGrabActive = 17,
    CheckMark = 18, SliderGrab = 19, SliderGrabActive = 20, Button = 21,
    ButtonHovered = 22, ButtonActive = 23, Header = 24, HeaderHovered = 25,
    HeaderActive = 26, Separator = 27, SeparatorHovered = 28, SeparatorActive = 29,
    ResizeGrip = 30, ResizeGripHovered = 31, ResizeGripActive = 32,
    Tab = 33, TabHovered = 34, TabActive = 35, TabUnfocused = 36, TabUnfocusedActive = 37,
    PlotLines = 38, PlotLinesHovered = 39, PlotHistogram = 40, PlotHistogramHovered = 41,
    TableHeaderBg = 42, TableBorderStrong = 43, TableBorderLight = 44,
    TableRowBg = 45, TableRowBgAlt = 46, TextSelectedBg = 47,
}

function M.apply(gui)
    local style = gui.igGetStyle()
    
    -- "Luna" Geometric Profile: Deeply rounded, smooth arcs
    style.WindowRounding = 12.0
    style.ChildRounding = 8.0
    style.FrameRounding = 6.0
    style.PopupRounding = 12.0
    style.GrabRounding = 20.0 -- Perfect circles
    style.ScrollbarRounding = 20.0
    
    style.WindowPadding = ffi.new("ImVec2_c", {15, 15})
    style.FramePadding = ffi.new("ImVec2_c", {8, 5})
    style.ItemSpacing = ffi.new("ImVec2_c", {12, 10})
    
    style.WindowBorderSize = 1.0
    style.ChildBorderSize = 0.0
    style.FrameBorderSize = 1.0 -- Suble outline for controls
    
    -- "Luna Eclipse" Palette: The Void & The Starlight
    local colors = style.Colors
    local function set_col(idx, r, g, b, a)
        colors[idx].x, colors[idx].y, colors[idx].z, colors[idx].w = r, g, b, a or 1.0
    end

    -- Core Void (Near Black but with a cold blue tint)
    local void_black = {0.04, 0.04, 0.06} 
    local moon_grey  = {0.12, 0.12, 0.16}
    local dust_grey  = {0.20, 0.20, 0.25}
    
    -- Accents (The "Lunar Glow")
    local star_white = {0.95, 0.96, 1.00}
    local cyan_glow  = {0.30, 0.80, 1.00} -- Soft cyan
    local deep_glow  = {0.15, 0.40, 0.60} -- Darker version for states

    set_col(Col.WindowBg, void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.ChildBg,  0, 0, 0, 0)
    set_col(Col.PopupBg,  void_black[1], void_black[2], void_black[3], 1.00)
    
    set_col(Col.Border, 0.25, 0.25, 0.30, 0.40)
    
    -- Text (Crisp Starlight)
    set_col(Col.Text,         star_white[1], star_white[2], star_white[3], 1.00)
    set_col(Col.TextDisabled, 0.40, 0.40, 0.45, 1.00)
    
    -- Interactive Elements (Glowing Cyan)
    set_col(Col.FrameBg,        0.08, 0.08, 0.10, 1.00)
    set_col(Col.FrameBgHovered, moon_grey[1], moon_grey[2], moon_grey[3], 1.00)
    set_col(Col.FrameBgActive,  cyan_glow[1], cyan_glow[2], cyan_glow[3], 0.20)
    
    set_col(Col.TitleBg,          void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TitleBgActive,    void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TitleBgCollapsed, void_black[1], void_black[2], void_black[3], 0.50)
    
    set_col(Col.CheckMark,        cyan_glow[1], cyan_glow[2], cyan_glow[3], 1.00)
    set_col(Col.SliderGrab,       cyan_glow[1], cyan_glow[2], cyan_glow[3], 0.70)
    set_col(Col.SliderGrabActive, cyan_glow[1], cyan_glow[2], cyan_glow[3], 1.00)
    
    set_col(Col.Button,           moon_grey[1], moon_grey[2], moon_grey[3], 1.00)
    set_col(Col.ButtonHovered,    deep_glow[1], deep_glow[2], deep_glow[3], 1.00)
    set_col(Col.ButtonActive,     cyan_glow[1], cyan_glow[2], cyan_glow[3], 1.00)
    
    set_col(Col.Header,           moon_grey[1], moon_grey[2], moon_grey[3], 0.80)
    set_col(Col.HeaderHovered,    deep_glow[1], deep_glow[2], deep_glow[3], 0.60)
    set_col(Col.HeaderActive,     cyan_glow[1], cyan_glow[2], cyan_glow[3], 0.80)
    
    set_col(Col.Separator,        0.15, 0.15, 0.20, 1.00)
    
    set_col(Col.Tab,                void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TabHovered,         moon_grey[1], moon_grey[2], moon_grey[3], 1.00)
    set_col(Col.TabActive,          deep_glow[1], deep_glow[2], deep_glow[3], 1.00)
    set_col(Col.TabUnfocused,       void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TabUnfocusedActive, moon_grey[1], moon_grey[2], moon_grey[3], 1.00)
    
    set_col(Col.PlotLines, cyan_glow[1], cyan_glow[2], cyan_glow[3], 1.00)
    set_col(Col.TableRowBg, void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TableRowBgAlt, moon_grey[1], moon_grey[2], moon_grey[3], 0.30)
end

return M
