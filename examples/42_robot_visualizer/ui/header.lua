local ffi = require("ffi")
local imgui = require("imgui")
local icons = require("examples.42_robot_visualizer.ui.icons")
local ui = require("examples.42_robot_visualizer.ui.consts")
local playback = require("examples.42_robot_visualizer.playback")

local M = {
    _v2_pos = ffi.new("ImVec2_c"),
    _v2_size = ffi.new("ImVec2_c"),
}

function M.draw(gui)
    local width = _G._WIN_LW or 1280
    M._v2_pos.x, M._v2_pos.y = 0, 0
    M._v2_size.x, M._v2_size.y = width, 40
    gui.igSetNextWindowPos(M._v2_pos, 0, ui.V2_ZERO)
    gui.igSetNextWindowSize(M._v2_size, 0)
    
    local flags = bit.bor(
        imgui.gui.ImGuiWindowFlags_NoDecoration,
        imgui.gui.ImGuiWindowFlags_NoMove,
        imgui.gui.ImGuiWindowFlags_NoSavedSettings,
        imgui.gui.ImGuiWindowFlags_NoDocking
    )
    
    local small_font = _G.imgui.get_font(1)
    if small_font then gui.igPushFont(small_font) end

    gui.igPushStyleColor_Vec4(2, ui.V4_VOID) -- WindowBg
    if gui.igBegin("##Header", nil, flags) then
        M._v2_pos.x, M._v2_pos.y = 20, 10
        gui.igSetCursorPos(M._v2_pos)
        gui.igText(icons.ROBOT .. "  ROBOT PILOT")
        
        local stats = _G._PERF_STATS
        gui.igSameLine(0, 40)
        gui.igTextDisabled(icons.CHART .. " FPS: ")
        gui.igSameLine(0, 5)
        gui.igText(string.format("%.1f", stats and stats.real_fps or 0))
        
        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.GEAR .. " RAM: ")
        gui.igSameLine(0, 5)
        gui.igText(string.format("%.2f MB", collectgarbage("count") / 1024))

        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.SIGNAL .. " IO: ")
        gui.igSameLine(0, 5)
        gui.igText(string.format("%.1f MB/s", playback.throughput_mbs or 0))

        local right_content_x = width - 250
        M._v2_pos.x, M._v2_pos.y = right_content_x, 10
        gui.igSetCursorPos(M._v2_pos)
        gui.igTextDisabled(icons.FOLDER .. " Session: ")
        gui.igSameLine(0, 5)
        gui.igText(_G._ACTIVE_MCAP or "No File Loaded")
        
        gui.igEnd()
    end
    gui.igPopStyleColor(1)
    if small_font then gui.igPopFont() end
end

return M
