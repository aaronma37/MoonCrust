local ffi = require("ffi")

local M = {}

function M.create_mesh()
    return { vertices = {}, indices = {} }
end

function M.make_cube(w, h, d, r, g, b)
    local hw, hh, hd = w/2, h/2, d/2
    local mesh = M.create_mesh()
    
    local verts = {
        -- Front
        {-hw, -hh,  hd,  0,  0,  1, r, g, b}, { hw, -hh,  hd,  0,  0,  1, r, g, b}, { hw,  hh,  hd,  0,  0,  1, r, g, b}, {-hw,  hh,  hd,  0,  0,  1, r, g, b},
        -- Back
        { hw, -hh, -hd,  0,  0, -1, r, g, b}, {-hw, -hh, -hd,  0,  0, -1, r, g, b}, {-hw,  hh, -hd,  0,  0, -1, r, g, b}, { hw,  hh, -hd,  0,  0, -1, r, g, b},
        -- Left
        {-hw, -hh, -hd, -1,  0,  0, r, g, b}, {-hw, -hh,  hd, -1,  0,  0, r, g, b}, {-hw,  hh,  hd, -1,  0,  0, r, g, b}, {-hw,  hh, -hd, -1,  0,  0, r, g, b},
        -- Right
        { hw, -hh,  hd,  1,  0,  0, r, g, b}, { hw, -hh, -hd,  1,  0,  0, r, g, b}, { hw,  hh, -hd,  1,  0,  0, r, g, b}, { hw,  hh,  hd,  1,  0,  0, r, g, b},
        -- Top
        {-hw,  hh,  hd,  0,  1,  0, r, g, b}, { hw,  hh,  hd,  0,  1,  0, r, g, b}, { hw,  hh, -hd,  0,  1,  0, r, g, b}, {-hw,  hh, -hd,  0,  1,  0, r, g, b},
        -- Bottom
        {-hw, -hh, -hd,  0, -1,  0, r, g, b}, { hw, -hh, -hd,  0, -1,  0, r, g, b}, { hw, -hh,  hd,  0, -1,  0, r, g, b}, {-hw, -hh,  hd,  0, -1,  0, r, g, b},
    }
    
    local indices = {
        0, 1, 2,  2, 3, 0,
        4, 5, 6,  6, 7, 4,
        8, 9, 10, 10, 11, 8,
        12, 13, 14, 14, 15, 12,
        16, 17, 18, 18, 19, 16,
        20, 21, 22, 22, 23, 20
    }
    
    mesh.vertices = verts
    mesh.indices = indices
    return mesh
end

function M.make_pyramid(w, h, d, r, g, b)
    local hw, hh, hd = w/2, h/2, d/2
    local mesh = M.create_mesh()
    
    -- Vertices: Bottom base (4 verts) and Top Tip (1 vert)
    -- But for shading, we need separate vertices for each face to have flat normals
    local verts = {
        -- Base (Facing Down)
        {-hw, -hh,  hd,  0, -1,  0, r, g, b}, { hw, -hh,  hd,  0, -1,  0, r, g, b}, { hw, -hh, -hd,  0, -1,  0, r, g, b}, {-hw, -hh, -hd,  0, -1,  0, r, g, b},
        -- Front Face
        {-hw, -hh,  hd,  0,  0.5, 1, r, g, b}, { hw, -hh,  hd,  0,  0.5, 1, r, g, b}, { 0,  hh,  0,  0,  0.5, 1, r, g, b},
        -- Back Face
        { hw, -hh, -hd,  0,  0.5,-1, r, g, b}, {-hw, -hh, -hd,  0,  0.5,-1, r, g, b}, { 0,  hh,  0,  0,  0.5,-1, r, g, b},
        -- Left Face
        {-hw, -hh, -hd, -1,  0.5, 0, r, g, b}, {-hw, -hh,  hd, -1,  0.5, 0, r, g, b}, { 0,  hh,  0, -1,  0.5, 0, r, g, b},
        -- Right Face
        { hw, -hh,  hd,  1,  0.5, 0, r, g, b}, { hw, -hh, -hd,  1,  0.5, 0, r, g, b}, { 0,  hh,  0,  1,  0.5, 0, r, g, b},
    }
    
    local indices = {
        0, 1, 2,  2, 3, 0, -- Base
        4, 5, 6,           -- Front
        7, 8, 9,           -- Back
        10, 11, 12,        -- Left
        13, 14, 15         -- Right
    }
    
    mesh.vertices = verts
    mesh.indices = indices
    return mesh
end

function M.translate(mesh, x, y, z)
    local res = M.create_mesh()
    for _, v in ipairs(mesh.vertices) do
        table.insert(res.vertices, {v[1]+x, v[2]+y, v[3]+z, v[4], v[5], v[6], v[7], v[8], v[9]})
    end
    for _, i in ipairs(mesh.indices) do
        table.insert(res.indices, i)
    end
    return res
end

function M.scale(mesh, sx, sy, sz)
    local res = M.create_mesh()
    for _, v in ipairs(mesh.vertices) do
        table.insert(res.vertices, {v[1]*sx, v[2]*sy, v[3]*sz, v[4], v[5], v[6], v[7], v[8], v[9]})
    end
    for _, i in ipairs(mesh.indices) do
        table.insert(res.indices, i)
    end
    return res
end

function M.union(m1, m2)
    local res = M.create_mesh()
    for _, v in ipairs(m1.vertices) do
        table.insert(res.vertices, {v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9]})
    end
    local offset = #m1.vertices
    for _, i in ipairs(m1.indices) do
        table.insert(res.indices, i)
    end
    
    for _, v in ipairs(m2.vertices) do
        table.insert(res.vertices, {v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9]})
    end
    for _, i in ipairs(m2.indices) do
        table.insert(res.indices, i + offset)
    end
    
    return res
end

function M.build_buffer(mesh)
    -- Interleaved: px, py, pz, nx, ny, nz, r, g, b
    local v_size = #mesh.vertices * 9 * 4
    local i_size = #mesh.indices * 4
    
    local v_data = ffi.new("float[?]", #mesh.vertices * 9)
    for i, v in ipairs(mesh.vertices) do
        local idx = (i - 1) * 9
        v_data[idx]   = v[1]
        v_data[idx+1] = v[2]
        v_data[idx+2] = v[3]
        v_data[idx+3] = v[4]
        v_data[idx+4] = v[5]
        v_data[idx+5] = v[6]
        v_data[idx+6] = v[7]
        v_data[idx+7] = v[8]
        v_data[idx+8] = v[9]
    end
    
    local i_data = ffi.new("uint32_t[?]", #mesh.indices)
    for i, idx in ipairs(mesh.indices) do
        i_data[i - 1] = idx
    end
    
    return v_data, v_size, i_data, i_size, #mesh.indices
end

return M
