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
    gui.igText(string.format("Pos: (%.2f, %.2f, %.2f)", playback.robot_pose.x, playback.robot_pose.y, playback.robot_pose.z))
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
    gui.igDragFloat("Lidar Point Size", view3d.p_point_size, 0.5, 0.1, 500.0, "%.1f", 0)
    
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
