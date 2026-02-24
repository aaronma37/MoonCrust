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
    
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FrameRounding = 4.0
    style.PopupRounding = 10.0
    style.GrabRounding = 12.0
    style.ScrollbarRounding = 12.0
    style.TabRounding = 6.0
    
    style.WindowPadding = ffi.new("ImVec2_c", {20, 20})
    style.FramePadding = ffi.new("ImVec2_c", {10, 6})
    style.ItemSpacing = ffi.new("ImVec2_c", {12, 12})
    style.ItemInnerSpacing = ffi.new("ImVec2_c", {8, 6})
    
    style.WindowBorderSize = 1.0
    style.ChildBorderSize = 0.0
    style.FrameBorderSize = 0.0
    style.PopupBorderSize = 1.0
    
    local colors = style.Colors
    local function set_col(idx, r, g, b, a)
        colors[idx].x, colors[idx].y, colors[idx].z, colors[idx].w = r, g, b, a or 1.0
    end

    local void_black = {0.05, 0.05, 0.07} 
    local deep_navy  = {0.08, 0.08, 0.12}
    local slate_grey = {0.15, 0.15, 0.20}
    
    local star_white = {1.00, 1.00, 1.00}
    local electric_blue = {0.00, 0.60, 1.00}
    local deep_glow  = {0.10, 0.30, 0.50}

    -- Text must be SOLID (1.0 alpha) to avoid colliding with Glassmorphism heuristic
    set_col(Col.Text,         star_white[1], star_white[2], star_white[3], 1.00)
    set_col(Col.TextDisabled, 0.40, 0.42, 0.50, 1.00)
    
    set_col(Col.WindowBg, void_black[1], void_black[2], void_black[3], 0.70)
    set_col(Col.ChildBg,  0, 0, 0, 0)
    set_col(Col.PopupBg,  void_black[1], void_black[2], void_black[3], 0.85)
    
    set_col(Col.Border, 0.20, 0.20, 0.25, 0.50)
    set_col(Col.BorderShadow, 0, 0, 0, 0)
    
    set_col(Col.FrameBg,        deep_navy[1], deep_navy[2], deep_navy[3], 1.00)
    set_col(Col.FrameBgHovered, slate_grey[1], slate_grey[2], slate_grey[3], 1.00)
    set_col(Col.FrameBgActive,  electric_blue[1], electric_blue[2], electric_blue[3], 0.30)
    
    set_col(Col.TitleBg,          void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TitleBgActive,    deep_navy[1], deep_navy[2], deep_navy[3], 1.00)
    set_col(Col.TitleBgCollapsed, void_black[1], void_black[2], void_black[3], 0.60)
    
    set_col(Col.CheckMark,        electric_blue[1], electric_blue[2], electric_blue[3], 1.00)
    set_col(Col.SliderGrab,       electric_blue[1], electric_blue[2], electric_blue[3], 0.80)
    set_col(Col.SliderGrabActive, electric_blue[1], electric_blue[2], electric_blue[3], 1.00)
    
    set_col(Col.Button,           deep_navy[1], deep_navy[2], deep_navy[3], 1.00)
    set_col(Col.ButtonHovered,    deep_glow[1], deep_glow[2], deep_glow[3], 1.00)
    set_col(Col.ButtonActive,     electric_blue[1], electric_blue[2], electric_blue[3], 1.00)
    
    set_col(Col.Header,           deep_navy[1], deep_navy[2], deep_navy[3], 0.60)
    set_col(Col.HeaderHovered,    deep_glow[1], deep_glow[2], deep_glow[3], 0.80)
    set_col(Col.HeaderActive,     electric_blue[1], electric_blue[2], electric_blue[3], 1.00)
    
    set_col(Col.Separator,        0.15, 0.15, 0.20, 1.00)
    
    set_col(Col.Tab,                void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TabHovered,         deep_glow[1], deep_glow[2], deep_glow[3], 1.00)
    set_col(Col.TabActive,          electric_blue[1], electric_blue[2], electric_blue[3], 0.80)
    set_col(Col.TabUnfocused,       void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TabUnfocusedActive, deep_navy[1], deep_navy[2], deep_navy[3], 1.00)
    
    set_col(Col.PlotLines, electric_blue[1], electric_blue[2], electric_blue[3], 1.00)
    set_col(Col.PlotLinesHovered, star_white[1], star_white[2], star_white[3], 1.00)
    
    set_col(Col.TableHeaderBg,    void_black[1], void_black[2], void_black[3], 1.00)
    set_col(Col.TableBorderStrong, 0.20, 0.20, 0.25, 1.00)
    set_col(Col.TableBorderLight,  0.15, 0.15, 0.20, 1.00)
    set_col(Col.TableRowBg,       0, 0, 0, 0)
    set_col(Col.TableRowBgAlt,    1.0, 1.0, 1.0, 0.03)
end

return M
