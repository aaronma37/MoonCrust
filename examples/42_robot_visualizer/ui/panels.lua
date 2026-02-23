local bit = require("bit")

local M = {
    list = {},
    states = {},
    focused_id = nil,
    
    -- Common Flags
    Flags = { 
        NoDecoration = 43, 
        AlwaysAutoResize = 64, 
        AlwaysOnTop = 262144, 
        TableBorders = 3, 
        TableResizable = 16 
    },
    ImPlotFlags = { 
        CanvasOnly = 127 
    },
    ImPlotAxisFlags = { 
        NoGridLines = 4, 
        NoTickMarks = 8, 
        NoTickLabels = 16, 
        NoLabel = 1 
    },
}

function M.register(id, name, render_func)
    M.list[id] = { id = id, name = name, render = render_func }
end

return M
