local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local bit = require("bit")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")

local v4_val = ffi.new("ImVec4_c", {0.2, 0.8, 1, 1})
local v2_zero = ffi.new("ImVec2_c", {0, 0})
local v2_table = ffi.new("ImVec2_c", {0, 250})
local v2_full = ffi.new("ImVec2_c", {-1, -1})
local plot_spec = ffi.new("ImPlotSpec_c", { Stride = 4 })
local scratch_chars = ffi.new("char[1024]")

-- Helper for selecting a stream
local function open_topic_picker(gui, on_select)
    local items = {}
    for _, ch in ipairs(playback.channels) do
        table.insert(items, { name = ch.topic, data = ch })
    end
    _G._OPEN_PICKER("Select Topic", items, on_select)
end

panels.register("pretty_viewer", "Pretty Message Viewer", function(gui, node_id)
    local p_state = panels.states[node_id] or { selected_ch = nil }
    panels.states[node_id] = p_state
    
    if gui.igButton(p_state.selected_ch and p_state.selected_ch.topic or "Select Pretty View...", ffi.new("ImVec2_c", {-1, 25})) then
        open_topic_picker(gui, function(it) p_state.selected_ch = it.data end)
    end
    
    if p_state.selected_ch then
        local ch = p_state.selected_ch
        local buf = playback.message_buffers[ch.id]
        if buf and buf.size > 0 then
            if gui.igTreeNode_Str("Metadata") then 
                gui.igText("Topic: %s", ch.topic)
                gui.igText("Type: %s", ch.schema)
                gui.igText("Size: %d bytes", buf.size)
                gui.igTreePop() 
            end
            
            if ch.topic == "lidar" then
                if gui.igTreeNode_Str("PointCloud2 Table") then
                    if gui.igBeginTable("PtsTable", 4, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), v2_table, 0) then
                        gui.igTableSetupColumn("Idx", 0, 0, 0)
                        gui.igTableSetupColumn("X", 0, 0, 0)
                        gui.igTableSetupColumn("Y", 0, 0, 0)
                        gui.igTableSetupColumn("Z", 0, 0, 0)
                        gui.igTableHeadersRow()
                        local f = ffi.cast("float*", buf.data)
                        for i=0, 49 do 
                            gui.igTableNextRow(0, 0)
                            gui.igTableNextColumn(); gui.igText("%d", i)
                            gui.igTableNextColumn(); gui.igText("%.3f", f[i*3])
                            gui.igTableNextColumn(); gui.igText("%.3f", f[i*3+1])
                            gui.igTableNextColumn(); gui.igText("%.3f", f[i*3+2])
                        end
                        gui.igEndTable()
                    end
                    gui.igTreePop()
                end
            elseif ch.topic == "pose" then
                local p = ffi.cast("Pose*", buf.data)
                gui.igTextColored(v4_val, "Position: (%.3f, %.3f, %.3f)", p.x, p.y, p.z)
                gui.igTextColored(v4_val, "Orientation (Yaw): %.3f rad", p.yaw)
            elseif buf.size >= 4 then 
                gui.igTextColored(v4_val, "Numeric Value: %.4f", ffi.cast("float*", buf.data)[0]) 
            end
        else 
            gui.igTextDisabled("(No data received yet)") 
        end
    end
end)

panels.register("topics", "Topic List", function(gui, node_id)
    gui.igText("Discovered Topics")
    gui.igSeparator()
    if gui.igBeginTable("TopicTable", 3, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), v2_zero, 0) then
        gui.igTableSetupColumn("Topic", 0, 0, 0)
        gui.igTableSetupColumn("Type", 0, 0, 0)
        gui.igTableSetupColumn("ID", 0, 0, 0)
        gui.igTableHeadersRow()
        for _, ch in ipairs(playback.channels) do
            gui.igTableNextRow(0, 0)
            gui.igTableNextColumn(); gui.igText("%s", ch.topic)
            gui.igTableNextColumn(); gui.igText("%s", ch.schema)
            gui.igTableNextColumn(); gui.igText("%d", ch.id)
        end
        gui.igEndTable()
    end
end)

-- hex_viewer, msg_viewer, plotter etc could be added here as well
