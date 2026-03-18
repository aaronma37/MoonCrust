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
                if m_str then for v in m_str:gmatch("[^%s]+") do table.insert(vals, tonumber(v)) end end
                if #vals == 16 then local_mat = vals end
            end
            
            local global_mat = #stack > 0 and mat4_mul_row(stack[#stack].global_mat, local_mat) or local_mat
            local gpos = {global_mat[4], global_mat[8], global_mat[12]}
            
            local b = {
                name = name,
                id = #bones + 1,
                parent_id = parent_id,
                local_matrix = local_mat,
                global_mat = global_mat,
                pos = gpos
            }
            if type == "JOINT" then table.insert(bones, b) end
            table.insert(stack, b)
            pos = tag_end + 1
        else
            table.remove(stack)
            pos = (node_end_tag or pos) + 7
        end
    end
    return bones
end

function M.load_animations(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()

    local anim_start = content:find("<library_animations>")
    local anim_end = content:find("</library_animations>")
    if not anim_start then return nil end
    local anim_xml = content:sub(anim_start, anim_end)

    -- LuaJIT patterns: "." doesn't match newlines. Use "[^%z]" for any character including newlines.
    -- Actually "%s*" handles whitespaces/newlines between tags.

    -- 1. Index ALL sources.
    local sources = {}
    for id, node in anim_xml:gmatch('<source id="([^"]+)"[^>]*>(.-)</source>') do
        local data = node:match('<float_array[^>]*>(.-)</float_array>')
        if data then sources[id] = data end
    end
    -- If gmatch failed due to inner newlines, we need a different approach.
    -- Standard Lua pattern approach for multi-line:
    local function get_all_sources(xml)
        local src = {}
        local p = 1
        while true do
            local s, e = xml:find("<source", p)
            if not s then break end
            local id = xml:match('id="([^"]+)"', s)
            local send = xml:find("</source>", e)
            if id and send then
                local node = xml:sub(s, send)
                local ds, de = node:find("<float_array")
                local dend = node:find("</float_array>")
                if ds and dend then
                    local dstart = node:find(">", de)
                    src[id] = node:sub(dstart + 1, dend - 1)
                end
            end
            p = (send or e) + 9
        end
        return src
    end
    sources = get_all_sources(anim_xml)

    -- 2. Index ALL samplers
    local samplers = {}
    local p = 1
    while true do
        local s, e = anim_xml:find("<sampler", p)
        if not s then break end
        local id = anim_xml:match('id="([^"]+)"', s)
        local send = anim_xml:find("</sampler>", e)
        if id and send then
            local node = anim_xml:sub(s, send)
            local input = node:match('semantic="INPUT" source="#([^"]+)"')
            local output = node:match('semantic="OUTPUT" source="#([^"]+)"')
            samplers[id] = { input = input, output = output }
        end
        p = (send or e) + 10
    end

    -- 3. Link Channels
    local animations = {}
    local max_duration = 0
    p = 1
    while true do
        local s, e = anim_xml:find("<channel", p)
        if not s then break end
        local source_id = anim_xml:match('source="#([^"]+)"', s)
        local target = anim_xml:match('target="([^/]+)/', s)
        
        if source_id and target then
            local sampler = samplers[source_id]
            if sampler then
                local t_str = sources[sampler.input]
                local m_str = sources[sampler.output]
                if t_str and m_str then
                    local chan = { times = {}, matrices = {} }
                    for v in t_str:gmatch("[^%s]+") do
                        local t = tonumber(v)
                        if t then
                            table.insert(chan.times, t)
                            if t > max_duration then max_duration = t end
                        end
                    end
                    local m_vals = {}
                    for v in m_str:gmatch("[^%s]+") do
                        local val = tonumber(v)
                        if val then table.insert(m_vals, val) end
                    end
                    for i=1, #m_vals, 16 do
                        local m = {}
                        for j=0,15 do table.insert(m, m_vals[i+j] or 0) end
                        table.insert(chan.matrices, m)
                    end
                    animations[target] = chan
                end
            end
        end
        p = e + 1
    end

    local final_count = 0
    for _ in pairs(animations) do final_count = final_count + 1 end
    print("DEBUG: Successfully linked " .. final_count .. " animation channels. Duration: " .. max_duration .. "s")
    return { channels = animations, duration = max_duration }
end

return M
