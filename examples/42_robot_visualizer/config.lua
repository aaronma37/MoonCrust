-- Robot Visualizer Configuration: MARS AIRPORT EDITION
local M = {}

-- Facets: Tuned for the Mars DJI/Livox hardware
M.facets = {
    MarsLidar3D = {
        panel = "view3d",
        params = { 
            topic_name = "/livox/lidar", 
            pose_topic = "/dji_osdk_ros/local_position",
            point_size = 2.0,
            follow = true,
            attach = true
        }
    },
    MarsTelemetryInspector = {
        panel = "pretty_viewer",
        params = { topic_name = "/dji_osdk_ros/battery_state" }
    },
    MarsIMUPlot = {
        panel = "plotter",
        params = { 
            topic_name = "/livox/imu",
            field_name = "angular_velocity.x" 
        }
    },
    MarsFlightStatus = {
        panel = "pretty_viewer",
        params = { topic_name = "/dji_osdk_ros/flight_status" }
    }
}

-- Layout: h = top/bottom split, v = left/right split
M.layout = { 
    type = "split", direction = "h", ratio = 0.85,
    children = {
        { -- Top Region
            type = "split", direction = "v", ratio = 0.7,
            children = {
                -- Left: 3D View (Main)
                { type = "view", facet = "MarsLidar3D", id = 1, title = "Mars Surface (Livox)###1" },
                
                -- Right: 3-Panel Stack
                {
                    type = "split", direction = "h", ratio = 0.33,
                    children = {
                        { type = "view", facet = "MarsTelemetryInspector", id = 2, title = "Battery/Power###2" },
                        {
                            type = "split", direction = "h", ratio = 0.5,
                            children = {
                                { type = "view", facet = "MarsFlightStatus", id = 3, title = "Flight Status###3" },
                                { type = "view", facet = "MarsIMUPlot", id = 5, title = "IMU Realtime###5" }
                            }
                        }
                    }
                }
            }
        },
        -- Bottom: Playback (Full Width)
        { type = "view", view_type = "telemetry", id = 4, title = "Mars Playback###4" }
    }
}

return M
