local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")

local M = {}

ffi.cdef[[
    typedef struct MeshVertex {
        float pos[3]; float pad1;
        float normal[3]; float pad2;
        float color[3]; float pad3;
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
            if parent then
                table.insert(segments, {
                    start_pos = {parent.pos[1], parent.pos[2], parent.pos[3], parent.id - 1},
                    end_pos = {b.pos[1], b.pos[2], b.pos[3], b.id - 1},
                    name = parent.name .. "_to_" .. b.name,
                    parent_name = parent.name,
                    child_name = b.name
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
    
    -- 1. SIMPLE JOINT REPOSITORY (Exact matching only)
    local joints = {
        mixamorig_Hips = { r = 1.2, oval = 0.35 },
        mixamorig_Spine = { r = 1.0, oval = 0.3 },
        mixamorig_Spine1 = { r = 0.7, oval = 0.2 },
        mixamorig_Spine2 = { r = 1.2, oval = 0.4 }, -- NARROWER CHEST
        mixamorig_Neck = { r = 0.5, oval = 0.1 },
        mixamorig_Head = { r = 0.8, oval = 0.0 },
        -- Limbs
        mixamorig_LeftArm = { r = 0.45, oval = 0.2 },
        mixamorig_RightArm = { r = 0.45, oval = 0.2 },
        mixamorig_LeftUpLeg = { r = 0.6, oval = 0.2 },
        mixamorig_RightUpLeg = { r = 0.6, oval = 0.2 },
    }

    local function get_joint(name)
        return joints[name] or { r = 0.4, oval = 0.2 }
    end

    for b = 0, num_bones - 1 do
        local seg = segments[b+1]
        local start_j = get_joint(seg.parent_name)
        local end_j = get_joint(seg.child_name)

        -- SOCKET LOGIC & PELVIS FUSION
        local s_r, e_r = start_j.r, end_j.r
        local s_push, e_push = 0.0, 0.0
        local taper_pow = 1.0

        -- LEG FUSION: Start legs at hip-width, then cinch smoothly
        if seg.parent_name == "mixamorig_Hips" then
            s_r = 1.2 
            s_oval = 0.4
            if seg.child_name:find("Leg") then
                taper_pow = 1.0 -- LINEAR CINCH: Smooth muscular transition
                e_r = 0.7 -- WIDER THIGH
            end
        end

        -- SHOULDER SOCKET: Keep these as sockets for now to prevent chest-mess
        if seg.parent_name == "mixamorig_Spine2" and (seg.child_name:find("Shoulder") or seg.child_name:find("Arm")) then
            s_r = 0.5 
        end

        -- CHEST SHELF
        if seg.parent_name == "mixamorig_Spine2" and seg.child_name == "mixamorig_Neck" then
            taper_pow = 5.0
            s_push = 0.4
        end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local rt = r / (rings_per_bone - 1)
            -- Apply the taper power to the progression
            local t = math.pow(rt, taper_pow)
            
            local cur_r = s_r + (e_r - s_r) * t
            local cur_oval = start_j.oval + (end_j.oval - start_j.oval) * t
            
            p.coeffs[0] = cur_r
            p.coeffs[3] = cur_oval * cur_r
            p.coeffs[2] = (s_push * (1.0 - rt) + e_push * rt) -- Linear push along segment
        end
    end

    -- 2. ROBUST BRANCH WELDING: Ensure parent end matches child start perfectly
    for b = 0, num_bones - 1 do
        local curr = segments[b+1]
        for prev_idx = 0, num_bones - 1 do
            local prev = segments[prev_idx+1]
            -- If current segment starts where prev ends
            if prev.end_pos[4] == curr.start_pos[4] then
                -- WELDER RULE: Only weld if both are "Torso" or both are "Limb"
                local function is_torso(name) return name:find("Spine") or name:find("Hips") or name:find("Neck") end
                if is_torso(prev.child_name) == is_torso(curr.child_name) then
                    local p_last = params[prev_idx * rings_per_bone + (rings_per_bone-1)]
                    local c_first = params[b * rings_per_bone]
                    for i=0,7 do c_first.coeffs[i] = p_last.coeffs[i] end
                end
            end
        end
    end

    return params
end

return M
