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
    
    print("--- Bone Segment Analysis ---")
    for i, b in ipairs(skeleton_bones) do
        if b.parent_id ~= 0 then
            local parent = bone_map[b.parent_id]
            local dx = b.pos[1] - parent.pos[1]
            local dy = b.pos[2] - parent.pos[2]
            local dz = b.pos[3] - parent.pos[3]
            local len = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if len > 0.05 then
                local dir = {dx/len, dy/len, dz/len}
                print(string.format("Segment: %s -> %s | Length: %.2f | Direction: %.2f, %.2f, %.2f", 
                    parent.name, b.name, len, dir[1], dir[2], dir[3]))
                
                table.insert(segments, {
                    start_pos = {parent.pos[1], parent.pos[2], parent.pos[3], parent.id - 1},
                    end_pos = {b.pos[1], b.pos[2], b.pos[3], b.id - 1},
                    plane_start = {dir[1], dir[2], dir[3], 0},
                    plane_end = {dir[1], dir[2], dir[3], 0},
                    name = parent.name .. "_to_" .. b.name
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
        local base_radius = 0.3
        
        -- Humanoid Volumes
        if seg.name:find("Spine") or seg.name:find("Hips") then base_radius = 1.2 end
        if seg.name:find("Head") then base_radius = 0.8 end
        if seg.name:find("Arm") then base_radius = 0.4 end
        if seg.name:find("Hand") or seg.name:find("Foot") then base_radius = 0.2 end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local t = r / (rings_per_bone - 1)
            
            p.coeffs[0] = base_radius
            
            -- Tapering
            if seg.name:find("Arm") or seg.name:find("Leg") then
                -- Thick in middle, thin at joints (Muscles)
                p.coeffs[0] = base_radius * (0.8 + 0.4 * math.sin(t * math.pi))
            end
            
            if seg.name:find("Spine") then
                -- Belly push
                p.coeffs[0] = base_radius * (1.0 + 0.2 * math.sin(t * math.pi))
            end
        end
    end
    return params
end

return M
