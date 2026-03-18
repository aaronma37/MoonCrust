local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")

local M = {}

ffi.cdef[[
    typedef struct MeshVertex {
        float pos[4];
        float normal[4];
        float color[4];
        float weights[4];
        uint32_t bone_ids[4];
    } MeshVertex;

    typedef struct MeshBone {
        float start_pos[4];
        float end_pos[4];
        float plane_start[4];
        float plane_end[4];
    } MeshBone;

    typedef struct MeshRingParams {
        float coeffs[8];
    } MeshRingParams;
]]

function M.calculate_bone_segments(skeleton_bones)
    local segments = {}
    local bone_map = {}
    for i, b in ipairs(skeleton_bones) do bone_map[b.id] = b end
    
    for i, b in ipairs(skeleton_bones) do
        if b.parent_id ~= 0 then
            local parent = bone_map[b.parent_id]
            local dx = b.pos[1] - parent.pos[1]
            local dy = b.pos[2] - parent.pos[2]
            local dz = b.pos[3] - parent.pos[3]
            local len = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if len > 0.05 then
                table.insert(segments, {
                    start_pos = {parent.pos[1], parent.pos[2], parent.pos[3], parent.id - 1},
                    end_pos = {b.pos[1], b.pos[2], b.pos[3], b.id - 1},
                    name = parent.name .. "_to_" .. b.name,
                    bone_name = parent.name
                })
            end
        end
    end
    return segments
end

function M.generate_indices(num_bones, rings_per_bone, verts_per_ring)
    local indices = {}
    for b = 0, num_bones - 1 do
        for r = 0, rings_per_bone - 2 do
            for v = 0, verts_per_ring - 1 do
                local next_v = (v + 1) % verts_per_ring
                local v0 = b * (rings_per_bone * verts_per_ring) + r * verts_per_ring + v
                local v1 = b * (rings_per_bone * verts_per_ring) + (r + 1) * verts_per_ring + v
                local v2 = b * (rings_per_bone * verts_per_ring) + r * verts_per_ring + next_v
                local v3 = b * (rings_per_bone * verts_per_ring) + (r + 1) * verts_per_ring + next_v
                table.insert(indices, v0); table.insert(indices, v1); table.insert(indices, v2)
                table.insert(indices, v2); table.insert(indices, v1); table.insert(indices, v3)
            end
        end
    end
    return indices
end

function M.create_params(num_bones, rings_per_bone, segments)
    local params = ffi.new("MeshRingParams[?]", num_bones * rings_per_bone)
    
    for b = 0, num_bones - 1 do
        local seg = segments[b+1]
        local name = seg.bone_name
        
        local start_r, end_r = 0.4, 0.4
        local ovality = 0.2
        
        -- PURE LOCAL CONTROL: Assign radii to specific bones
        if name:find("Hips") then 
            start_r, end_r = 1.3, 1.1
            ovality = 0.4
        elseif name:find("Spine") then -- mixamorig_Spine
            start_r, end_r = 1.1, 0.8
            ovality = 0.3
        elseif name:find("Spine1") then
            start_r, end_r = 0.8, 1.2
            ovality = 0.4
        elseif name:find("Spine2") then
            start_r, end_r = 1.2, 1.6
            ovality = 0.5
        elseif name:find("Neck") then
            start_r, end_r = 0.6, 0.4
        elseif name:find("Head") then
            start_r, end_r = 0.8, 0.8
        elseif name:find("Arm") or name:find("Leg") then
            start_r, end_r = 0.4, 0.4
        end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local t = r / (rings_per_bone - 1)
            local current_r = start_r + (end_r - start_r) * t
            
            p.coeffs[0] = current_r
            p.coeffs[3] = ovality * current_r
        end
    end

    -- NO HEAL PASS: Boundary constraints are now the user's responsibility
    return params
end

return M
