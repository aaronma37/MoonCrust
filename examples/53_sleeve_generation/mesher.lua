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
            local dx = b.pos[1] - parent.pos[1]
            local dy = b.pos[2] - parent.pos[2]
            local dz = b.pos[3] - parent.pos[3]
            local len = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if len > 0.05 then
                local dir = {dx/len, dy/len, dz/len}
                
                -- Mitering: find incoming and outgoing directions
                local incoming = dir
                if parent.parent_id ~= 0 then
                    local gp = bone_map[parent.parent_id]
                    local idx = parent.pos[1] - gp.pos[1]
                    local idy = parent.pos[2] - gp.pos[2]
                    local idz = parent.pos[3] - gp.pos[3]
                    local ilen = math.sqrt(idx*idx + idy*idy + idz*idz)
                    if ilen > 0 then incoming = {idx/ilen, idy/ilen, idz/ilen} end
                end
                
                local outgoing = dir
                for _, b2 in ipairs(skeleton_bones) do
                    if b2.parent_id == b.id then
                        local odx = b2.pos[1] - b.pos[1]
                        local ody = b2.pos[2] - b.pos[2]
                        local odz = b2.pos[3] - b.pos[3]
                        local olen = math.sqrt(odx*odx + ody*ody + odz*odz)
                        if olen > 0.05 then outgoing = {odx/olen, ody/olen, odz/olen}; break end
                    end
                end

                -- Bisector Plane Normals
                -- Start plane: bisector of incoming bone and current bone
                local plane_start = {incoming[1] + dir[1], incoming[2] + dir[2], incoming[3] + dir[3]}
                local ps_l = math.sqrt(plane_start[1]^2 + plane_start[2]^2 + plane_start[3]^2)
                if ps_l > 0.001 then plane_start = {plane_start[1]/ps_l, plane_start[2]/ps_l, plane_start[3]/ps_l} else plane_start = dir end

                -- End plane: bisector of current bone and outgoing bone
                local plane_end = {dir[1] + outgoing[1], dir[2] + outgoing[2], dir[3] + outgoing[3]}
                local pe_l = math.sqrt(plane_end[1]^2 + plane_end[2]^2 + plane_end[3]^2)
                if pe_l > 0.001 then plane_end = {plane_end[1]/pe_l, plane_end[2]/pe_l, plane_end[3]/pe_l} else plane_end = dir end

                table.insert(segments, {
                    start_pos = {parent.pos[1], parent.pos[2], parent.pos[3], parent.id - 1},
                    end_pos = {b.pos[1], b.pos[2], b.pos[3], b.id - 1},
                    plane_start = {plane_start[1], plane_start[2], plane_start[3], 0},
                    plane_end = {plane_end[1], plane_end[2], plane_end[3], 0},
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
        local base_r = 0.3
        
        -- Default Volumes
        if seg.name:find("Spine") or seg.name:find("Hips") then base_r = 1.1 end
        if seg.name:find("Head") then base_r = 0.8 end
        if seg.name:find("Arm") then base_r = 0.4 end
        if seg.name:find("Hand") or seg.name:find("Foot") then base_r = 0.2 end

        for r = 0, rings_per_bone - 1 do
            local p = params[b * rings_per_bone + r]
            local t = r / (rings_per_bone - 1)
            
            p.coeffs[0] = base_r
            
            -- Torso Oval (2nd Harmonic)
            if seg.name:find("Spine") or seg.name:find("Hips") then
                p.coeffs[3] = -0.3 -- Wider on X axis
                p.coeffs[1] = 0.1 * math.sin(t * math.pi) -- Slight belly push
            end
            
            -- Muscle Bulge (Sin tapering + harmonics)
            if seg.name:find("Arm") or seg.name:find("Leg") then
                local bulge = 0.4 * math.sin(t * math.pi)
                p.coeffs[0] = base_r * (0.8 + bulge)
                p.coeffs[3] = -0.1 * bulge -- Slightly oval muscles
            end
        end
    end
    return params
end

return M
