local ffi = require("ffi")
local imgui = require("imgui")
local icons = require("examples.42_robot_visualizer.ui.icons")

local M = {}

function M.draw(gui)
    local width = _G._WIN_LW or 1280
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {0, 0}), 0, ffi.new("ImVec2_c", {0,0}))
    gui.igSetNextWindowSize(ffi.new("ImVec2_c", {width, 50}), 0)
    
    local flags = bit.bor(
        imgui.gui.ImGuiWindowFlags_NoDecoration,
        imgui.gui.ImGuiWindowFlags_NoMove,
        imgui.gui.ImGuiWindowFlags_NoSavedSettings,
        imgui.gui.ImGuiWindowFlags_NoDocking
    )
    
    gui.igPushStyleColor_Vec4(2, ffi.new("ImVec4_c", {0.05, 0.05, 0.07, 0.85})) -- WindowBg
    if gui.igBegin("##Header", nil, flags) then
        gui.igSetCursorPos(ffi.new("ImVec2_c", {20, 12}))
        gui.igText(icons.ROBOT .. "  ROBOT PILOT v1.0")
        
        gui.igSameLine(0, 40)
        gui.igTextDisabled(icons.HEARTBEAT .. " Status: ")
        gui.igSameLine(0, 5)
        gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0.2, 1}), "NOMINAL")
        
        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.SIGNAL .. " Ping: ")
        gui.igSameLine(0, 5)
        gui.igText("14ms")
        
        gui.igSameLine(0, 30)
        gui.igTextDisabled(icons.BATTERY .. " Power: ")
        gui.igSameLine(0, 5)
        gui.igText("88%")

        -- Right side
        local right_content_x = width - 250
        gui.igSetCursorPos(ffi.new("ImVec2_c", {right_content_x, 12}))
        gui.igTextDisabled(icons.GEAR .. " Session: ")
        gui.igSameLine(0, 5)
        gui.igText(_G._ACTIVE_MCAP or "No File Loaded")
        
        gui.igEnd()
    end
    gui.igPopStyleColor(1)
end

return M
