local ffi = require("ffi")
require("examples.42_robot_visualizer.types")

local M = {}

-- Zero-allocation primitive generation
-- Directly writes into a LineVertex* buffer

function M.write_axes(ptr, offset, px, py, pz, yaw, size)
    local s = size or 1.0
    local p = ptr + offset
    local sin_y, cos_y = math.sin(yaw or 0), math.cos(yaw or 0)
    
    local function set(idx, x, y, z, r, g, b)
        local rx = x * cos_y - y * sin_y
        local ry = x * sin_y + y * cos_y
        p[idx].x, p[idx].y, p[idx].z = px + rx, py + ry, pz + z
        p[idx].r, p[idx].g, p[idx].b, p[idx].a = r, g, b, 1.0
    end

    -- X Axis (RED)
    set(0, 0, 0, 0, 1, 0, 0); set(1, s, 0, 0, 1, 0, 0)
    -- Y Axis (GREEN)
    set(2, 0, 0, 0, 0, 1, 0); set(3, 0, s, 0, 0, 1, 0)
    -- Z Axis (BLUE)
    set(4, 0, 0, 0, 0, 0, 1); set(5, 0, 0, s, 0, 0, 1)
    
    return 6
end

function M.write_box(ptr, offset, px, py, pz, yaw, w, h, d, r, g, b, a)
    local p = ptr + offset
    local x, y = w/2, h/2
    local sin_y, cos_y = math.sin(yaw or 0), math.cos(yaw or 0)
    
    local idx = 0
    local function add_line(x1,y1,z1, x2,y2,z2)
        local rx1, ry1 = x1 * cos_y - y1 * sin_y, x1 * sin_y + y1 * cos_y
        local rx2, ry2 = x2 * cos_y - y2 * sin_y, x2 * sin_y + y2 * cos_y
        p[idx].x, p[idx].y, p[idx].z = px + rx1, py + ry1, pz + z1
        p[idx + 1].x, p[idx + 1].y, p[idx + 1].z = px + rx2, py + ry2, pz + z2
        p[idx].r, p[idx].g, p[idx].b, p[idx].a = r, g, b, a
        p[idx + 1].r, p[idx + 1].g, p[idx + 1].b, p[idx + 1].a = r, g, b, a
        idx = idx + 2
    end

    -- Bottom
    add_line(-x, -y, 0,  x, -y, 0); add_line( x, -y, 0,  x,  y, 0)
    add_line( x,  y, 0, -x,  y, 0); add_line(-x,  y, 0, -x, -y, 0)
    -- Top
    add_line(-x, -y, d,  x, -y, d); add_line( x, -y, d,  x,  y, d)
    add_line( x,  y, d, -x,  y, d); add_line(-x,  y, d, -x, -y, d)
    -- Sides
    add_line(-x, -y, 0, -x, -y, d); add_line( x, -y, 0,  x, -y, d)
    add_line( x,  y, 0,  x,  y, d); add_line(-x,  y, 0, -x,  y, d)
    
    return idx
end

return M
