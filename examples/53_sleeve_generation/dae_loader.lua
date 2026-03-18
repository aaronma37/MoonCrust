local mc = require("mc")
local M = {}

-- Helper to multiply 4x4 Row-Major matrices
local function mat4_mul_row(a, b)
    local c = {}
    for i=0,3 do
        for j=0,3 do
            local sum = 0
            for k=0,3 do sum = sum + a[i*4 + k + 1] * b[k*4 + j + 1] end
            c[i*4 + j + 1] = sum
        end
    end
    return c
end

local function mat4_identity()
    return {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
end

function M.load_skeleton(path)
    local f = io.open(path, "r")
    if not f then error("Could not open DAE: " .. path) end
    local content = f:read("*all")
    f:close()

    local scene_start = content:find("<library_visual_scenes>")
    local scene_end = content:find("</library_visual_scenes>")
    local scene_xml = content:sub(scene_start, scene_end)

    local bones = {}
    local stack = {}
    local pos = 1
    
    while true do
        local node_start = scene_xml:find("<node", pos)
        local node_end_tag = scene_xml:find("</node>", pos)
        if not node_start and not node_end_tag then break end
        
        if node_start and (not node_end_tag or node_start < node_end_tag) then
            local tag_end = scene_xml:find(">", node_start)
            local tag_content = scene_xml:sub(node_start, tag_end)
            local name = tag_content:match('name="([^"]+)"') or tag_content:match('id="([^"]+)"')
            local type = tag_content:match('type="([^"]+)"')
            
            local parent_id = #stack > 0 and stack[#stack].id or 0
            
            local next_node = scene_xml:find("<node", tag_end + 1) or #scene_xml
            local mat_tag = scene_xml:find("<matrix", tag_end + 1)
            local local_mat = mat4_identity()
            
            if mat_tag and mat_tag < next_node then
                local m_end = scene_xml:find("</matrix>", mat_tag)
                local m_str = scene_xml:sub(mat_tag, m_end):match(">(.-)<")
                local vals = {}
                for v in m_str:gmatch("[^%s]+") do table.insert(vals, tonumber(v)) end
                if #vals == 16 then local_mat = vals end
            end
            
            local global_mat = #stack > 0 and mat4_mul_row(stack[#stack].global_mat, local_mat) or local_mat
            
            -- Row-Major Matrix: Translation is 4, 8, 12
            local gpos = {global_mat[4], global_mat[8], global_mat[12]}
            
            local b = {
                name = name,
                id = #bones + 1,
                parent_id = parent_id,
                global_mat = global_mat, -- Still Row-Major here
                pos = gpos
            }
            
            if type == "JOINT" then table.insert(bones, b) end
            table.insert(stack, b)
            pos = tag_end + 1
        else
            table.remove(stack)
            pos = node_end_tag + 7
        end
    end

    return bones
end

return M
