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
            local dx, dy, dz = b.pos[1]-parent.pos[1], b.pos[2]-parent.pos[2], b.pos[3]-parent.pos[3]
            local len = math.sqrt(dx*dx + dy*dy + dz*dz)
            if len > 0.05 then
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
    
    print("--- Segment Diagnostic Legend ---")
    for i, s in ipairs(segments) do
        print(string.format("ID %d: %s", i-1, s.name))
    end

    local joint_genes = {
        default = { r = 0.4, oval = 0.2 },
        mixamorig_Hips = { r = 1.3, oval = 0.35 },
        mixamorig_Spine = { r = 1.0, oval = 0.25 },
        mixamorig_Spine1 = { r = 0.6, oval = 0.2 }, 
        mixamorig_Spine2 = { r = 1.3, oval = 0.35 },
        mixamorig_Neck = { r = 0.5, oval = 0.1 },
        mixamorig_Head = { r = 0.8, oval = 0.0 },
        mixamorig_LeftArm = { r = 0.4, oval = 0.2 },
        mixamorig_RightArm = { r = 0.4, oval = 0.2 },
        mixamorig_LeftUpLeg = { r = 0.5, oval = 0.2 },
        mixamorig_RightUpLeg = { r = 0.5, oval = 0.2 },
    }

    local function get_gene(name)
        for k, v in pairs(joint_genes) do if name:find(k) then return v end end
        return joint_genes.default
    end

    for b = 0, num_bones - 1 do
        local seg = segments[b+1]
        local start_gene = get_gene(seg.parent_name)
        local end_gene = get_gene(seg.child_name)

        -- SOCKET FIX: If we are branching from the Hips to a Leg, 
        -- don't use the Hips' torso radius for the leg start.
        if seg.parent_name:find("Hips") and seg.child_name:find("Leg") then
            start_gene = { r = 0.6, oval = 0.2 } 
        end

        -- SHOULDER SOCKET FIX: If we are branching from the Chest to a Shoulder,
        -- use a smaller radius to prevent clipping into the pectorals/back.
        if seg.parent_name:find("Spine2") and (seg.child_name:find("Shoulder") or seg.child_name:find("Arm")) then
            start_gene = { r = 0.5, oval = 0.2 } 
        end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local t = r / (rings_per_bone - 1)
            local current_r = start_gene.r + (end_gene.r - start_gene.r) * t
            local current_oval = start_gene.oval + (end_gene.oval - start_gene.oval) * t
            
            p.coeffs[0] = current_r
            p.coeffs[3] = current_oval * current_r
        end
    end
    return params
end

return M
