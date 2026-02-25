local ffi = require("ffi")
local imgui = require("imgui")
local icons = require("examples.42_robot_visualizer.ui.icons")
local ui = require("examples.42_robot_visualizer.ui.consts")

local M = {
    _v2_pos = ffi.new("ImVec2_c"),
    _v2_size = ffi.new("ImVec2_c"),
}

function M.draw(gui)
    local width = _G._WIN_LW or 1280
    M._v2_pos.x, M._v2_pos.y = 0, 0
    M._v2_size.x, M._v2_size.y = width, 50
    gui.igSetNextWindowPos(M._v2_pos, 0, ui.V2_ZERO)
    gui.igSetNextWindowSize(M._v2_size, 0)
    
    local flags = bit.bor(
        imgui.gui.ImGuiWindowFlags_NoDecoration,
        imgui.gui.ImGuiWindowFlags_NoMove,
        imgui.gui.ImGuiWindowFlags_NoSavedSettings,
        imgui.gui.ImGuiWindowFlags_NoDocking
    )
    
    gui.igPushStyleColor_Vec4(2, ui.V4_VOID) -- WindowBg
    if gui.igBegin("##Header", nil, flags) then
        M._v2_pos.x, M._v2_pos.y = 20, 12
        gui.igSetCursorPos(M._v2_pos)
        gui.igText(icons.ROBOT .. "  ROBOT PILOT v1.0")
        
        gui.igSameLine(0, 40)
        gui.igTextDisabled(icons.HEARTBEAT .. " Status: ")
        gui.igSameLine(0, 5)
        gui.igTextColored(ui.V4_NOMINAL, "NOMINAL")
        
        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.SIGNAL .. " Ping: ")
        gui.igSameLine(0, 5)
        gui.igText("14ms")
        
        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.BATTERY .. " Power: ")
        gui.igSameLine(0, 5)
        gui.igText("88%")

        local right_content_x = width - 250
        M._v2_pos.x, M._v2_pos.y = right_content_x, 12
        gui.igSetCursorPos(M._v2_pos)
        gui.igTextDisabled(icons.GEAR .. " Session: ")
        gui.igSameLine(0, 5)
        gui.igText(_G._ACTIVE_MCAP or "No File Loaded")
        
        gui.igEnd()
    end
    gui.igPopStyleColor(1)
end

return M
