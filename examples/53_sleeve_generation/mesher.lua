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
    for _, b in ipairs(skeleton_bones) do bone_map[b.id] = b end

    for _, b in ipairs(skeleton_bones) do
        if b.parent_id ~= 0 then
            local parent = bone_map[b.parent_id]
            if not b.name:find("HeadTop_End") then
                table.insert(segments, {
                    name = parent.name .. "_to_" .. b.name,
                    parent_name = parent.name,
                    child_name = b.name,
                    start_pos = {parent.pos[1], parent.pos[2], parent.pos[3], parent.id-1},
                    end_pos = {b.pos[1], b.pos[2], b.pos[3], b.id-1}
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
                local i0 = b * (rings_per_bone * verts_per_ring) + r * verts_per_ring + v
                local i1 = b * (rings_per_bone * verts_per_ring) + r * verts_per_ring + next_v
                local i2 = b * (rings_per_bone * verts_per_ring) + (r + 1) * verts_per_ring + v
                local i3 = b * (rings_per_bone * verts_per_ring) + (r + 1) * verts_per_ring + next_v
                table.insert(indices, i0); table.insert(indices, i2); table.insert(indices, i1)
                table.insert(indices, i1); table.insert(indices, i2); table.insert(indices, i3)
            end
        end
    end
    return indices
end

function M.create_params(num_bones, rings_per_bone, segments)
    local params = ffi.new("MeshRingParams[?]", num_bones * rings_per_bone)
    
    local joints = {
        mixamorig_Hips = { r = 1.2, oval = 0.35 },
        mixamorig_Spine = { r = 1.0, oval = 0.3 },
        mixamorig_Spine1 = { r = 0.7, oval = 0.2 },
        mixamorig_Spine2 = { r = 1.2, oval = 0.4 },
        mixamorig_Neck = { r = 0.35, oval = 0.1 },
        mixamorig_Head = { r = 0.35, oval = 0.1 },
        virtual_Skull = { r = 0.85, oval = 0.2, taper = 1.0 },
        virtual_Face = { r = 0.4, oval = 0.2, taper = 1.0, sharp = 2.0 },
        -- Limbs
        mixamorig_LeftArm = { r = 0.35, oval = 0.1 },
        mixamorig_RightArm = { r = 0.35, oval = 0.1 },
        mixamorig_LeftUpLeg = { r = 0.75, oval = 0.3 },
        mixamorig_RightUpLeg = { r = 0.75, oval = 0.3 },
    }

    local function get_joint(name)
        return joints[name] or { r = 0.4, oval = 0.2, taper = 0.0, sharp = 1.0 }
    end

    for b = 0, num_bones - 1 do
        local seg = segments[b+1]
        local start_j = get_joint(seg.parent_name)
        local end_j = get_joint(seg.child_name)
        local s_r, e_r = start_j.r, end_j.r
        local taper_pow = 1.0

        if seg.parent_name == "mixamorig_Hips" then
            s_r = 1.2 
            if seg.child_name:find("Leg") then e_r = 0.7 end
        end
        if seg.parent_name == "mixamorig_Spine2" and (seg.child_name:find("Shoulder") or seg.child_name:find("Arm")) then s_r = 0.5 end
        if seg.parent_name == "mixamorig_Spine2" and seg.child_name == "mixamorig_Neck" then taper_pow = 5.0 end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local rt = r / (rings_per_bone - 1)
            local t = math.pow(rt, taper_pow)
            
            local cur_r = s_r + (e_r - s_r) * t
            local cur_oval = (start_j.oval or 0.2) * (1.0 - t) + (end_j.oval or 0.2) * t
            local cur_sharp = (start_j.sharp or 1.0) * (1.0 - rt) + (end_j.sharp or 1.0) * rt
            local cur_taper = (start_j.taper or 0.0) * (1.0 - rt) + (end_j.taper or 0.0) * rt
            
            p.coeffs[0] = cur_r
            p.coeffs[1] = 0 -- Forward/Back (Reset)
            p.coeffs[3] = cur_oval * cur_r
            p.coeffs[5] = cur_sharp
            p.coeffs[7] = cur_taper

            -- VERTICAL FACE SCULPTING (rt=0 is Top, rt=1.0 is Chin)
            if seg.child_name == "virtual_Face" then
                -- Define nose bridge, mouth, and chin protrusion
                local face_r = 0.4
                local fwd_push = 0.0
                
                if rt < 0.2 then -- Forehead
                    face_r = 0.8
                    fwd_push = 0.2
                elseif rt < 0.5 then -- Nose Bridge
                    face_r = 0.6 + (rt-0.2) * 0.5
                    fwd_push = 0.2 + (rt-0.2) * 3.0
                elseif rt < 0.7 then -- Mouth
                    face_r = 0.75 - (rt-0.5) * 1.0
                    fwd_push = 1.1 - (rt-0.5) * 1.5
                else -- Chin
                    face_r = 0.55 - (rt-0.7) * 0.5
                    fwd_push = 0.65 + (rt-0.7) * 1.0
                end
                
                p.coeffs[0] = face_r
                p.coeffs[1] = 0 -- NO SIDE PUSH
                p.coeffs[2] = fwd_push -- PUSH FORWARD (n=1, sin axis is depth now that spiral is fixed)
                p.coeffs[3] = 0.4 * face_r -- Wide ear-to-ear ovality
                p.coeffs[5] = 2.0 -- Smooth chiseled
            end
        end
    end

    -- 2. ROBUST BRANCH WELDING
    for b = 0, num_bones - 1 do
        local curr = segments[b+1]
        for prev_idx = 0, num_bones - 1 do
            local prev = segments[prev_idx+1]
            if prev.end_pos[4] == curr.start_pos[4] then
                local function is_torso(name) 
                    return name:find("Spine") or name:find("Hips") or name:find("Neck") or name:find("Head") or name:find("virtual") 
                end
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
