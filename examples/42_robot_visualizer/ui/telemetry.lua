local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local bit = require("bit")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")
local icons = require("examples.42_robot_visualizer.ui.icons")
local ui = require("examples.42_robot_visualizer.ui.consts")

local function format_ts(ns, start_ns)
    local d = tonumber(ns - (start_ns or 0)) / 1e9
    local m = math.floor(d / 60)
    local s = d % 60
    return string.format("%02d:%05.2f", m, s)
end

panels.register("telemetry", "Playback Controls", function(gui, node_id)
    local total_ns = playback.end_time - playback.start_time
    
    gui.igTextColored(playback.paused and ui.V4_PAUSED or ui.V4_LIVE, playback.paused and (icons.PAUSE .. " PAUSED") or (icons.PLAY .. " LIVE"))
    gui.igSameLine(0, -1)
    gui.igText(string.format(" | %s / %s", format_ts(playback.current_time_ns, playback.start_time), format_ts(playback.end_time, playback.start_time)))
    
    local progress = (total_ns > 0) and tonumber(playback.current_time_ns - playback.start_time) / tonumber(total_ns) or 0
    local p_ptr = ffi.new("float[1]", progress)
    gui.igSetNextItemWidth(-1)
    if gui.igSliderFloat("##Timeline", p_ptr, 0.0, 1.0, "", 0) then
        playback.seek_to = playback.start_time + ffi.cast("uint64_t", p_ptr[0] * tonumber(total_ns))
    end
    
    if gui.igButton(playback.paused and icons.PLAY .. " Resume" or icons.PAUSE .. " Pause", ui.V2_BTN_MED) then playback.paused = not playback.paused end
    gui.igSameLine(0, 10)
    if gui.igButton(icons.BACKWARD .. " Rewind", ui.V2_BTN_MED) then playback.seek_to = playback.start_time end
    
    gui.igSameLine(0, 30)
    gui.igTextDisabled(icons.GEAR .. " Speed: ")
    gui.igSameLine(0, 5)
    gui.igText(string.format("%.1fx", playback.speed))
    gui.igSameLine(0, 10)
    for _, s in ipairs({0.5, 1, 2, 5, 10, 100}) do
        if gui.igButton(tostring(s).."x", ui.V2_BTN_TINY) then playback.speed = s end
        gui.igSameLine(0, 2)
    end
end)
