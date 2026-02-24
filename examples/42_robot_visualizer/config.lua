-- Robot Visualizer Configuration
local M = {}

-- Facets: Configured versions of panels
M.facets = {
	MarsLidarInspector = {
		panel = "pretty_viewer",
		params = { topic_name = "/livox/lidar" },
	},
	RobotPoseMonitor = {
		panel = "pretty_viewer",
		params = { topic_name = "pose" },
	},
}

M.layout = {
	type = "split",
	direction = "h",
	ratio = 0.8,
	children = {
		{
			type = "split",
			direction = "v",
			ratio = 0.7,
			children = {
				{ type = "view", view_type = "view3d", id = 1, title = "3D Lidar###1" },
				{
					type = "split",
					direction = "h",
					ratio = 0.5,
					children = {
						{ type = "view", facet = "MarsLidarInspector", id = 2, title = "Lidar Inspector###2" },
						{ type = "view", view_type = "plotter", id = 5, title = "Telemetry Plot###5" },
					},
				},
			},
		},
		{
			type = "split",
			direction = "h",
			ratio = 0.6,
			children = {
				{ type = "view", view_type = "telemetry", id = 4, title = "Playback Controls###4" },
				{ type = "view", view_type = "perf", id = 3, title = "Performance###3" },
			},
		},
	},
}

return M
