local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")

local function format_ts(ns, start_ns)
    local d = tonumber(ns - (start_ns or 0)) / 1e9
    local m = math.floor(d / 60)
    local s = d % 60
    return string.format("%02d:%05.2f", m, s)
end

local v4_live = ffi.new("ImVec4_c", {0, 1, 0, 1})
local v4_paused = ffi.new("ImVec4_c", {1, 0, 0, 1})

panels.register("telemetry", "Playback Controls", function(gui, node_id)
    local total_ns = playback.end_time - playback.start_time
    gui.igTextColored(playback.paused and v4_paused or v4_live, playback.paused and "PAUSED" or "LIVE")
    gui.igSameLine(0, -1)
    gui.igText(string.format(" | %s / %s", format_ts(playback.current_time_ns, playback.start_time), format_ts(playback.end_time, playback.start_time)))
    
    local progress = (total_ns > 0) and tonumber(playback.current_time_ns - playback.start_time) / tonumber(total_ns) or 0
    local p_ptr = ffi.new("float[1]", progress)
    gui.igSetNextItemWidth(-1)
    if gui.igSliderFloat("##Timeline", p_ptr, 0.0, 1.0, "", 0) then
        playback.seek_to = playback.start_time + ffi.cast("uint64_t", p_ptr[0] * tonumber(total_ns))
    end
    
    if gui.igButton(playback.paused and "Resume" or "Pause", ffi.new("ImVec2_c", {100, 0})) then playback.paused = not playback.paused end
    gui.igSameLine(0, -1)
    if gui.igButton("Rewind", ffi.new("ImVec2_c", {100, 0})) then playback.seek_to = playback.start_time end
    gui.igSameLine(0, 10)
    gui.igText(string.format("Speed: %.1fx", playback.speed))
    gui.igSameLine(0, -1)
    for _, s in ipairs({0.5, 1, 2, 5, 10}) do
        if gui.igButton(tostring(s).."x", ffi.new("ImVec2_c", {40, 0})) then playback.speed = s end
        gui.igSameLine(0, -1)
    end
end)
