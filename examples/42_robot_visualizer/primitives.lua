local ffi = require("ffi")

local M = {}

-- Create a standard RGB Axis (TF) primitive
-- Size: length of the axes
function M.create_axes(size)
    local s = size or 1.0
    return {
        -- X Axis (RED)
        { x=0, y=0, z=0, r=1, g=0, b=0, a=1 },
        { x=s, y=0, z=0, r=1, g=0, b=0, a=1 },
        -- Y Axis (GREEN)
        { x=0, y=0, z=0, r=0, g=1, b=0, a=1 },
        { x=0, y=s, z=0, r=0, g=1, b=0, a=1 },
        -- Z Axis (BLUE)
        { x=0, y=0, z=0, r=0, g=0, b=1, a=1 },
        { x=0, y=0, z=s, r=0, g=0, b=1, a=1 },
    }
end

-- Create a simple wireframe box
function M.create_box(w, h, d, r, g, b, a)
    local x, y, z = w/2, h/2, d/2
    local verts = {}
    local function add_line(x1,y1,z1, x2,y2,z2)
        table.insert(verts, {x=x1, y=y1, z=z1, r=r, g=g, b=b, a=a})
        table.insert(verts, {x=x2, y=y2, z=z2, r=r, g=g, b=b, a=a})
    end
    
    -- Bottom
    add_line(-x, -y, 0,  x, -y, 0)
    add_line( x, -y, 0,  x,  y, 0)
    add_line( x,  y, 0, -x,  y, 0)
    add_line(-x,  y, 0, -x, -y, 0)
    -- Top
    add_line(-x, -y, d,  x, -y, d)
    add_line( x, -y, d,  x,  y, d)
    add_line( x,  y, d, -x,  y, d)
    add_line(-x,  y, d, -x, -y, d)
    -- Sides
    add_line(-x, -y, 0, -x, -y, d)
    add_line( x, -y, 0,  x, -y, d)
    add_line( x,  y, 0,  x,  y, d)
    add_line(-x,  y, 0, -x,  y, d)
    
    return verts
end

-- Transform primitive vertices by a pose (x, y, z, yaw)
function M.transform(verts, px, py, pz, yaw)
    local s, c = math.sin(yaw or 0), math.cos(yaw or 0)
    local out = {}
    for i, v in ipairs(verts) do
        local rx = v.x * c - v.y * s
        local ry = v.x * s + v.y * c
        table.insert(out, {
            x = px + rx,
            y = py + ry,
            z = pz + v.z,
            r = v.r, g = v.g, b = v.b, a = v.a
        })
    end
    return out
end

return M
