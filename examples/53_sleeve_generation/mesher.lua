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
        float pins[8];
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
        mixamorig_Hips = { r = 1.2, oval = 0.3 },
        mixamorig_Spine = { r = 1.0, oval = 0.3 },
        mixamorig_Spine1 = { r = 0.7, oval = 0.2 },
        mixamorig_Spine2 = { r = 1.2, oval = 0.4 },
        mixamorig_Neck = { r = 0.35, oval = 0.1 },
        mixamorig_Head = { r = 0.05, oval = 0.0 },
        virtual_Face = { r = 0.1, oval = 0.0 },
        -- Limbs
        mixamorig_LeftArm = { r = 0.35, oval = 0.1 },
        mixamorig_RightArm = { r = 0.35, oval = 0.1 },
        mixamorig_LeftUpLeg = { r = 0.75, oval = 0.3 },
        mixamorig_RightUpLeg = { r = 0.75, oval = 0.3 },
    }

    local function get_joint(name)
        return joints[name] or { r = 0.4, oval = 0.2 }
    end

    for b = 0, num_bones - 1 do
        local seg = segments[b+1]
        local start_j = get_joint(seg.parent_name)
        local end_j = get_joint(seg.child_name)
        local s_r, e_r = start_j.r, end_j.r

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local rt = r / (rings_per_bone - 1)
            
            local cur_r = s_r + (e_r - s_r) * rt
            local cur_oval = (start_j.oval or 0.2) * (1.0 - rt) + (end_j.oval or 0.2) * rt
            
            for i = 0, 7 do
                local angle = (i / 8.0) * 6.283185
                local side_factor = math.abs(math.sin(angle))
                local r_final = cur_r * (1.0 + cur_oval * side_factor)
                p.pins[i] = r_final
            end

            -- TOTAL HEAD SCULPTING (UP Bone)
            if seg.child_name == "virtual_Face" then
                -- Global Profile Recess
                p.pins[3], p.pins[4], p.pins[5] = 0.5, 0.5, 0.5 
                
                if rt < 0.25 then -- Neck -> Chin
                    local cap = math.pow(rt / 0.25, 0.5)
                    p.pins[0] = 0.45 * cap
                    p.pins[2], p.pins[6] = 0.4 * cap, 0.4 * cap
                elseif rt < 0.45 then -- Jaw / Mouth
                    p.pins[0] = 0.5 
                    p.pins[2], p.pins[6] = 0.8, 0.8
                elseif rt < 0.65 then -- Nose Bridge
                    local nose_out = 0.5 + (rt-0.45) * 4.0
                    p.pins[0] = nose_out
                    p.pins[1], p.pins[7] = 0.6, 0.6 -- WIDER bridge base
                    p.pins[2], p.pins[6] = 0.7, 0.7 -- Temples
                elseif rt < 0.85 then -- Forehead
                    p.pins[0] = 0.7 
                    p.pins[2], p.pins[6] = 0.7, 0.7
                else -- Crown
                    local cap = math.pow(1.0 - (rt-0.85)/0.15, 0.5)
                    p.pins[0] = 0.6 * cap
                    p.pins[2], p.pins[6] = 0.6 * cap, 0.6 * cap
                    p.pins[4] = 0.3 * cap
                end
            end
        end
    end

    -- 2. BRANCH WELDING
    for b = 0, num_bones - 1 do
        local curr = segments[b+1]
        for prev_idx = 0, num_bones - 1 do
            local prev = segments[prev_idx+1]
            if prev.end_pos[4] == curr.start_pos[4] then
                local function is_torso(name) 
                    return name:find("Spine") or name:find("Hips") or name:find("Neck") or name:find("Head") or name:find("virtual") 
                end
                if is_torso(prev.child_name) and is_torso(curr.child_name) then
                    local p_last = params[prev_idx * rings_per_bone + (rings_per_bone-1)]
                    local c_first = params[b * rings_per_bone]
                    for i=0,7 do c_first.pins[i] = p_last.pins[i] end
                end
            end
        end
    end
    return params
end

return M
