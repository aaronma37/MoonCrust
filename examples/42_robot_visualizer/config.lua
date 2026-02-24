-- Robot Visualizer Configuration
local M = {}

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
						{ type = "view", view_type = "pretty_viewer", id = 2, title = "Message Inspector###2" },
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
