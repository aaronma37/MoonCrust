local ffi = require("ffi")
require("examples.42_robot_visualizer.types")

local M = {}

-- Zero-allocation primitive generation
-- Directly writes into a LineVertex* buffer

function M.write_axes(ptr, offset, px, py, pz, q, size)
    local s = size or 1.0
    local p = ptr + offset
    q = q or {0,0,0,1}
    
    local function transform(x, y, z)
        local qx, qy, qz, qw = q[1], q[2], q[3], q[4]
        local x2, y2, z2 = qx + qx, qy + qy, qz + qz
        local xx, xy, xz = qx * x2, qx * y2, qx * z2
        local yy, yz, zz = qy * y2, qy * z2, qz * z2
        local wx, wy, wz = qw * x2, qw * y2, qw * z2
        
        local rx = (1.0 - (yy + zz)) * x + (xy - wz) * y + (xz + wy) * z
        local ry = (xy + wz) * x + (1.0 - (xx + zz)) * y + (yz - wx) * z
        local rz = (xz - wy) * x + (yz + wx) * y + (1.0 - (xx + yy)) * z
        return px + rx, py + ry, pz + rz
    end

    local function set(idx, x, y, z, r, g, b)
        local rx, ry, rz = transform(x, y, z)
        p[idx].x, p[idx].y, p[idx].z = rx, ry, rz
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

function M.write_box(ptr, offset, px, py, pz, q, w, h, d, r, g, b, a)
    local p = ptr + offset
    local x, y = w/2, h/2
    q = q or {0,0,0,1}
    
    local function transform(x, y, z)
        local qx, qy, qz, qw = q[1], q[2], q[3], q[4]
        local x2, y2, z2 = qx + qx, qy + qy, qz + qz
        local xx, xy, xz = qx * x2, qx * y2, qx * z2
        local yy, yz, zz = qy * y2, qy * z2, qz * z2
        local wx, wy, wz = qw * x2, qw * y2, qw * z2
        
        local rx = (1.0 - (yy + zz)) * x + (xy - wz) * y + (xz + wy) * z
        local ry = (xy + wz) * x + (1.0 - (xx + zz)) * y + (yz - wx) * z
        local rz = (xz - wy) * x + (yz + wx) * y + (1.0 - (xx + yy)) * z
        return px + rx, py + ry, pz + rz
    end

    local idx = 0
    local function add_line(x1,y1,z1, x2,y2,z2)
        local rx1, ry1, rz1 = transform(x1, y1, z1)
        local rx2, ry2, rz2 = transform(x2, y2, z2)
        p[idx].x, p[idx].y, p[idx].z = rx1, ry1, rz1
        p[idx + 1].x, p[idx + 1].y, p[idx + 1].z = rx2, ry2, rz2
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
