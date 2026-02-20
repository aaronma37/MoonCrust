local ffi = require("ffi")
local bit = require("bit")

local M = {}

local function get_natural_color(name)
    name = name:lower()
    if name:match("curtain") or name:match("fabric") or name:match("banner") then
        if name:match("blue") then return {0.1, 0.2, 0.6} end
        if name:match("green") then return {0.1, 0.4, 0.2} end
        return {0.6, 0.1, 0.1} -- Default red curtain
    end
    if name:match("stone") or name:match("arch") or name:match("column") or name:match("brick") then
        return {0.7, 0.65, 0.55} -- Warm beige stone
    end
    if name:match("floor") then
        return {0.5, 0.5, 0.5} -- Grey stone floor
    end
    if name:match("lion") or name:match("vase") then
        return {0.8, 0.7, 0.4} -- Bronze/Gold leaf
    end
    if name:match("roof") or name:match("ceiling") then
        return {0.3, 0.3, 0.35} -- Dark roof
    end
    if name:match("leaf") or name:match("plant") then
        return {0.2, 0.5, 0.1}
    end
    return {0.6, 0.6, 0.6} -- Default grey
end

local function parse_mtl(path)
    local materials = {}
    local current_mtl = nil
    local f = io.open(path, "r")
    if not f then return materials end
    for line in f:lines() do
        local parts = {}
        for part in line:gmatch("%S+") do table.insert(parts, part) end
        if parts[1] == "newmtl" then
            current_mtl = parts[2]
            materials[current_mtl] = get_natural_color(current_mtl)
        end
    end
    f:close()
    return materials
end

function M.load(path)
    print("OBJ Loader: Loading " .. path)
    local base_dir = path:match("(.*[/\\])") or ""
    local f = io.open(path, "r")
    if not f then error("Could not open file: " .. path) end

    local positions = {}
    local normals = {}
    local vertices = {} 
    local materials = {}
    local current_mtl_col = {0.7, 0.7, 0.7}
    
    for line in f:lines() do
        if not line:match("^#") then
            local parts = {}
            for part in line:gmatch("%S+") do table.insert(parts, part) end
            
            if parts[1] == "mtllib" then
                materials = parse_mtl(base_dir .. parts[2])
            elseif parts[1] == "usemtl" then
                current_mtl_col = materials[parts[2]] or {0.7, 0.7, 0.7}
            elseif parts[1] == "v" then
                table.insert(positions, {tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])})
            elseif parts[1] == "vn" then
                table.insert(normals, {tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])})
            elseif parts[1] == "f" then
                local face_data = {}
                for i = 2, #parts do
                    local v, vt, vn = parts[i]:match("([^/]*)/?([^/]*)/?([^/]*)")
                    table.insert(face_data, {tonumber(v), tonumber(vt), tonumber(vn)})
                end
                for i = 2, #face_data - 1 do
                    local tri_indices = {1, i, i + 1}
                    for _, tidx in ipairs(tri_indices) do
                        local indices = face_data[tidx]
                        local p = positions[indices[1]] or {0,0,0}
                        local n = (indices[3] and normals[indices[3]]) or {0,1,0}
                        table.insert(vertices, p[1]); table.insert(vertices, p[2]); table.insert(vertices, p[3])
                        table.insert(vertices, n[1]); table.insert(vertices, n[2]); table.insert(vertices, n[3])
                        table.insert(vertices, current_mtl_col[1]); table.insert(vertices, current_mtl_col[2]); table.insert(vertices, current_mtl_col[3])
                    end
                end
            end
        end
    end
    f:close()
    local data = ffi.new("float[?]", #vertices)
    for i=1, #vertices do data[i-1] = vertices[i] end
    return data, #vertices / 9
end

return M
