local ffi = require("ffi")
local sdf_lib = require("sdf")

local M = {}

-- PERSISTENT BUFFERS
local MAX_VERTS = 500000
local v_out = ffi.new("float[?]", MAX_VERTS * 11)

-- (evaluate_csg, get_normal, find_surface same as before...)
local function sd_sphere(px, py, pz, r) return math.sqrt(px*px + py*py + pz*pz) - r end
local function sd_box(px, py, pz, bx, by, bz)
    local qx, qy, qz = math.abs(px)-bx, math.abs(py)-by, math.abs(pz)-bz
    return math.sqrt(math.max(qx,0)^2 + math.max(qy,0)^2 + math.max(qz,0)^2) + math.min(math.max(qx,math.max(qy,qz)), 0.0)
end
local function sd_capsule(px, py, pz, ax, ay, az, bx, by, bz, r)
    local pax, pay, paz = px-ax, py-ay, pz-az
    local bax, bay, baz = bx-ax, by-ay, bz-az
    local d2 = bax*bax + bay*bay + baz*baz
    local h = (pax*bax + pay*bay + paz*baz) / (d2 + 1e-6)
    if h < 0 then h = 0 elseif h > 1 then h = 1 end
    local dx, dy, dz = pax - bax*h, pay - bay*h, paz - baz*h
    return math.sqrt(dx*dx + dy*dy + dz*dz) - r
end
local function sd_torus(px, py, pz, tx, ty)
    local qx = math.sqrt(px*px + pz*pz) - tx
    return math.sqrt(qx*qx + py*py) - ty
end

local function evaluate_csg(px, py, pz, components)
    local res_d, fr, fg, fb = 1e10, 1, 1, 1
    for i=1,#components do
        local c = components[i]
        local d = 1e10
        if c.type == "sphere" then d = sd_sphere(px - (c.pos and c.pos[1] or 0), py - (c.pos and c.pos[2] or 0), pz - (c.pos and c.pos[3] or 0), c.radius or 1)
        elseif c.type == "box" then d = sd_box(px - (c.pos and c.pos[1] or 0), py - (c.pos and c.pos[2] or 0), pz - (c.pos and c.pos[3] or 0), c.size[1], c.size[2], c.size[3])
        elseif c.type == "capsule" then d = sd_capsule(px, py, pz, c.a[1], c.a[2], c.a[3], c.b[1], c.b[2], c.b[3], c.radius or 1)
        elseif c.type == "torus" then d = sd_torus(px - (c.pos and c.pos[1] or 0), py - (c.pos and c.pos[2] or 0), pz - (c.pos and c.pos[3] or 0), c.radius or 1, c.thick or 0.1) end
        if d < res_d then res_d = d; fr, fg, fb = c.color[1], c.color[2], c.color[3] end
    end
    return res_d, fr, fg, fb
end

local function get_normal(px, py, pz, components)
    local e = 0.001
    local d, _, _, _ = evaluate_csg(px, py, pz, components)
    local nx = evaluate_csg(px + e, py, pz, components) - d
    local ny = evaluate_csg(px, py + e, pz, components) - d
    local nz = evaluate_csg(px, py, pz + e, components) - d
    local l = math.sqrt(nx*nx + ny*ny + nz*nz); if l>0 then return nx/l, ny/l, nz/l end
    return 0, 1, 0
end

local function find_surface(ox, oy, oz, dx, dy, dz, components)
    local t = 0
    for i=1,24 do
        local d, r, g, b = evaluate_csg(ox + dx*t, oy + dy*t, oz + dz*t, components)
        if math.abs(d) < 0.001 then return t, r, g, b end
        t = t + d
        if t > 15 then break end
    end
    return t, 1, 1, 1
end

function M.generate_mesh(components, min_p, max_p, res, global_bone_map)
    local v_count = 0
    local slices, radial_res = 16, 12
    
    -- We'll use a raw int32 pointer to write the bone_id safely
    local v_out_int = ffi.cast("int32_t*", v_out)

    local function add_v(px, py, pz, nx, ny, nz, r, g, b, bone)
        if v_count >= MAX_VERTS then return end
        local off = v_count * 11
        v_out[off], v_out[off+1], v_out[off+2] = px, py, pz
        v_out[off+3], v_out[off+4], v_out[off+5] = nx, ny, nz
        v_out[off+6], v_out[off+7], v_out[off+8] = r, g, b
        -- PACK BONE AS INT
        v_out_int[off+9] = tonumber(bone)
        v_out[off+10] = 1.0 -- weight as float
        v_count = v_count + 1
    end

    local bones_to_mesh = {}
    for i=1,#components do local b = components[i].bone; if not bones_to_mesh[b] then bones_to_mesh[b] = true end end

    for bone_name, _ in pairs(bones_to_mesh) do
        local bone_id = global_bone_map[bone_name] or 0
        local ax, ay, az, bx, by, bz = 0,0,0, 0,0,0
        local has_bone = false
        for i=1,#components do 
            if components[i].bone == bone_name then
                if components[i].type == "capsule" then
                    ax, ay, az = components[i].a[1], components[i].a[2], components[i].a[3]
                    bx, by, bz = components[i].b[1], components[i].b[2], components[i].b[3]
                    has_bone = mag ~= 0; break
                elseif components[i].type == "sphere" or components[i].type == "box" or components[i].type == "torus" then
                    ax, ay, az = components[i].pos[1], components[i].pos[2], components[i].pos[3]
                    bx, by, bz = ax, ay + 0.1, az; has_bone = true
                end
            end
        end
        
        if has_bone then
            local dx, dy, dz = bx-ax, by-ay, bz-az
            local mag = math.sqrt(dx*dx+dy*dy+dz*dz)
            if mag < 0.001 then mag = 0.1; dy = 1 end
            dx, dy, dz = dx/mag, dy/mag, dz/mag
            local rx, ry, rz = 0, 1, 0; if math.abs(dy) > 0.9 then rx, ry, rz = 1, 0, 0 end
            local ux, uy, uz = ry*dz - rz*dy, rz*dx - rx*dz, rx*dy - ry*dx
            local uxm = math.sqrt(ux*ux+uy*uy+uz*uz); ux,uy,uz = ux/uxm, uy/uxm, uz/uxm
            local vx, vy, vz = dy*uz - dz*uy, dz*ux - dx*uz, dx*uy - dy*ux
            
            local prev_ring = {}
            for s = 0, slices do
                local t = s / slices
                local ox, oy, oz = ax + dx*mag*t, ay + dy*mag*t, az + dz*mag*t
                local curr_ring = {}
                for r = 0, radial_res do
                    local angle = (r / radial_res) * math.pi * 2
                    local rdx, rdy, rdz = math.cos(angle)*ux + math.sin(angle)*vx, math.cos(angle)*uy + math.sin(angle)*vy, math.cos(angle)*uz + math.sin(angle)*vz
                    local dist, cr, cg, cb = find_surface(ox, oy, oz, rdx, rdy, rdz, components)
                    local px, py, pz = ox + rdx*dist, oy + rdy*dist, oz + rdz*dist
                    local nx, ny, nz = get_normal(px, py, pz, components)
                    curr_ring[r+1] = {px=px, py=py, pz=pz, nx=nx, ny=ny, nz=nz, r=cr, g=cg, b=cb}
                end
                if s > 0 then
                    for r = 1, radial_res do
                        local p1, p2, p3, p4 = prev_ring[r], prev_ring[r+1], curr_ring[r+1], curr_ring[r]
                        local nux, nuy, nuz = p2.px-p1.px, p2.py-p1.py, p2.pz-p1.pz
                        local nvx, nvy, nvz = p3.px-p1.px, p3.py-p1.py, p3.pz-p1.pz
                        local nx, ny, nz = nuy*nvz - nuz*nvy, nuz*nvx - nux*nvz, nux*nvy - nuy*nvx
                        local l = math.sqrt(nx*nx+ny*ny+nz*nz); if l>0 then nx,ny,nz=nx/l,ny/l,nz/l else nx,ny,nz=0,1,0 end
                        add_v(p1.px, p1.py, p1.pz, nx, ny, nz, p1.r, p1.g, p1.b, bone_id)
                        add_v(p2.px, p2.py, p2.pz, nx, ny, nz, p2.r, p2.g, p2.b, bone_id)
                        add_v(p3.px, p3.py, p3.pz, nx, ny, nz, p3.r, p3.g, p3.b, bone_id)
                        add_v(p3.px, p3.py, p3.pz, nx, ny, nz, p3.r, p3.g, p3.b, bone_id)
                        add_v(p4.px, p4.py, p4.pz, nx, ny, nz, p4.r, p4.g, p4.b, bone_id)
                        add_v(p1.px, p1.py, p1.pz, nx, ny, nz, p1.r, p1.g, p1.b, bone_id)
                    end
                end
                prev_ring = curr_ring
            end
        end
    end

    return v_out, v_count * 11 * 4, v_count
end

return M
