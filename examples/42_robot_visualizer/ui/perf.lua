local ffi = require("ffi")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")

panels.register("perf", "Performance Stats", function(gui, node_id)
    gui.igText("System Status")
    gui.igSeparator()
    local stats = _G._PERF_STATS
    gui.igText(string.format("FPS (ImGui): %.1f", gui.igGetIO_Nil().Framerate))
    gui.igText(string.format("FPS (Raw): %.1f", stats and stats.real_fps or 0))
    gui.igText(string.format("Frame Time: %.3f ms", 1000.0 / gui.igGetIO_Nil().Framerate))
    gui.igSeparator()
    gui.igText("Robot Pose")
    local ch_pose = playback.channels_by_id[playback.pose_ch_id]
    gui.igSetNextItemWidth(-1)
    if gui.igBeginCombo("##PoseTopic", "Pose: " .. (ch_pose and ch_pose.topic or "Select..."), 0) then
        for _, ch in ipairs(playback.channels) do
            if gui.igSelectable_Bool(ch.topic, playback.pose_ch_id == ch.id, 0, ffi.new("ImVec2_c")) then
                playback.pose_ch_id = ch.id
            end
        end
        gui.igEndCombo()
    end
    gui.igText(string.format("Pos: (%.2f, %.2f, %.2f)", playback.robot_pose.x, playback.robot_pose.y, playback.robot_pose.z))
    gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, 1}), string.format("Pulse: (%.4f, %.4f, %.4f)", playback._last_pose_vals[1], playback._last_pose_vals[2], playback._last_pose_vals[3]))
    gui.igText(string.format("Yaw: %.2f", playback.robot_pose.yaw))
    gui.igSeparator()
    gui.igText(string.format("Lua Heap: %.2f MB", collectgarbage("count") / 1024))
    gui.igText(string.format("Active Streams: %d", #playback.channels))
    gui.igSeparator()
    gui.igText("Telemetry Stream")
    gui.igText(string.format("Lidar Pts: %d", playback.last_lidar_points or 0))
    gui.igText(string.format("Time: %s", tostring(playback.current_time_ns)))
    
    local view3d = require("examples.42_robot_visualizer.view_3d")
    gui.igSeparator()
    gui.igText("Visualization Settings")
    
    gui.igSetNextItemWidth(-1)
    gui.igDragFloat("Point Size", view3d.p_point_size, 0.5, 0.1, 500.0, "Point Size: %.1f", 0)
    
    gui.igSeparatorText("Lidar Alignment")
    local l_off = ffi.new("int[1]", playback.lidar_offset or 0)
    gui.igSetNextItemWidth(-1)
    if gui.igDragInt("##LidarOff", l_off, 1.0, 0, 1024, "Lidar Offset: %d bytes", 0) then playback.lidar_offset = l_off[0] end
    
    local l_str = ffi.new("int[1]", playback.lidar_stride or 12)
    gui.igSetNextItemWidth(-1)
    if gui.igDragInt("##LidarStr", l_str, 1.0, 4, 128, "Lidar Stride: %d bytes", 0) then playback.lidar_stride = l_str[0] end
    gui.igTextDisabled("(Shift+Arrows: Offset, Alt+Arrows: Stride)")
    
    gui.igCheckbox("Transform Lidar", view3d.p_lidar_transform)
    gui.igSameLine(0, 10)
    if gui.igButton("Reset Axes", ffi.new("ImVec2_c")) then view3d.axis_map = {1, 2, 3, 0} end
    
    gui.igText("Axis Map: [" .. view3d.axis_map[1] .. "," .. view3d.axis_map[2] .. "," .. view3d.axis_map[3] .. "]")
    if gui.igButton("Swap Y/Z", ffi.new("ImVec2_c", {-1, 25})) then
        local old_y = view3d.axis_map[2]
        view3d.axis_map[2] = view3d.axis_map[3]
        view3d.axis_map[3] = old_y
    end
    if gui.igButton("Invert Z", ffi.new("ImVec2_c", {-1, 25})) then
        view3d.axis_map[3] = -view3d.axis_map[3]
    end
    
    if not panels.states[node_id] then
        panels.states[node_id] = {
            p_off = ffi.new("int[1]", playback.pose_offset),
            p_double = ffi.new("bool[1]", playback.pose_is_double)
        }
    end
    local p_state = panels.states[node_id]
    p_state.p_off[0] = playback.pose_offset -- Force sync with global hotkeys
    
    gui.igSetNextItemWidth(-1)
    if gui.igDragInt("Pose Offset", p_state.p_off, 1.0, 0, 512, "Pose Offset: %d bytes", 0) then
        playback.pose_offset = p_state.p_off[0]
    end
    
    if gui.igButton("AUTO-FIND ROBOT POSE", ffi.new("ImVec2_c", {-1, 35})) then
        playback.auto_scan_pose()
        p_state.p_off[0] = playback.pose_offset
        p_state.p_double[0] = playback.pose_is_double
    end
    
    if gui.igCheckbox("Use Double Precision", p_state.p_double) then
        playback.pose_is_double = p_state.p_double[0]
    end
    
    local ch = playback.channels_by_id[playback.pose_ch_id]
    if ch then
        local buf = playback.get_msg_buffer(ch.id)
        if buf and buf.size > 0 then
            gui.igSeparatorText("Forensic Debug (Double vs Float)")
            if gui.igBeginTable("DebugTable", 2, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), ffi.new("ImVec2_c"), 0) then
                gui.igTableSetupColumn("Offset + Double", 0, 0, 0)
                gui.igTableSetupColumn("Offset + Float", 0, 0, 0)
                gui.igTableHeadersRow()
                
                local d_ptr = ffi.cast("double*", buf.data + playback.pose_offset)
                local f_ptr = ffi.cast("float*", buf.data + playback.pose_offset)
                
                for i=0, 7 do
                    gui.igTableNextRow(0, 0)
                    gui.igTableNextColumn()
                    local d_off = playback.pose_offset + (i * 8)
                    local d_val = d_ptr[i]
                    gui.igText(string.format("@%d (D): %s", d_off, (d_val > 1e10 or d_val < -1e10) and "???" or string.format("%.4f", d_val)))
                    
                    gui.igTableNextColumn()
                    local f_off = playback.pose_offset + (i * 4)
                    local f_val = f_ptr[i]
                    gui.igText(string.format("@%d (F): %s", f_off, (f_val > 1e10 or f_val < -1e10) and "???" or string.format("%.4f", f_val)))
                end
                gui.igEndTable()
            end
            
            if gui.igButton("Snap to 4-Byte Alignment", ffi.new("ImVec2_c", {-1, 25})) then
                playback.pose_offset = math.floor(playback.pose_offset / 4) * 4
                p_state.p_off[0] = playback.pose_offset
            end
        end
    end
    
    gui.igSeparator()
    gui.igText("3D Scene Status")
    if view3d.current_pose then
        gui.igText(string.format("Robot XYZ: %.1f, %.1f, %.1f", view3d.current_pose.x, view3d.current_pose.y, view3d.current_pose.z))
        if gui.igButton("Snap Cam to Drone", ffi.new("ImVec2_c", {-1, 25})) then
            view3d.cam.target[1] = view3d.current_pose.x
            view3d.cam.target[2] = view3d.current_pose.y
            view3d.cam.target[3] = view3d.current_pose.z
            view3d.cam.dist = 20.0 -- Zoom in slightly
        end
    else
        gui.igText("Robot Pose: (No Data)")
    end
end)
