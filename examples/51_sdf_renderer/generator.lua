local mc = require("mc")
local ffi = require("ffi")

local M = {}

-- Helper to pack color into uint32
local function pack_color(r, g, b)
    local ir = math.floor(r * 255)
    local ig = math.floor(g * 255)
    local ib = math.floor(b * 255)
    return bit.bor(bit.lshift(ir, 16), bit.lshift(ig, 8), ib)
end

-- Step 1: Create the TF Tree (Skeleton)
function M.create_skeleton()
    local tree = {
        root = { parent = nil, offset = {0, 0.8, 0}, rot = {0,0,0} },
        spine = { parent = "root", offset = {0, 0.4, 0}, rot = {0,0,0} },
        neck = { parent = "spine", offset = {0, 0.3, 0}, rot = {0,0,0} },
        head = { parent = "neck", offset = {0, 0.15, 0}, rot = {0,0,0} },
        
        shoulder_L = { parent = "spine", offset = {-0.35, 0.2, 0}, rot = {0,0,1.5} },
        arm_upper_L = { parent = "shoulder_L", offset = {0, 0.3, 0}, rot = {0,0,0} },
        arm_lower_L = { parent = "arm_upper_L", offset = {0, 0.3, 0}, rot = {0,0,0} },
        
        shoulder_R = { parent = "spine", offset = {0.35, 0.2, 0}, rot = {0,0,-1.5} },
        arm_upper_R = { parent = "shoulder_R", offset = {0, 0.3, 0}, rot = {0,0,0} },
        arm_lower_R = { parent = "arm_upper_R", offset = {0, 0.3, 0}, rot = {0,0,0} },

        hip_L = { parent = "root", offset = {-0.18, -0.1, 0}, rot = {0,0,3.14} },
        leg_upper_L = { parent = "hip_L", offset = {0, 0.4, 0}, rot = {0,0,0} },
        leg_lower_L = { parent = "leg_upper_L", offset = {0, 0.4, 0}, rot = {0,0,0} },

        hip_R = { parent = "root", offset = {0.18, -0.1, 0}, rot = {0,0,3.14} },
        leg_upper_R = { parent = "hip_R", offset = {0, 0.4, 0}, rot = {0,0,0} },
        leg_lower_R = { parent = "leg_upper_R", offset = {0, 0.4, 0}, rot = {0,0,0} },
    }

    local order = {
        "root", "spine", "neck", "head",
        "shoulder_L", "arm_upper_L", "arm_lower_L",
        "shoulder_R", "arm_upper_R", "arm_lower_R",
        "hip_L", "leg_upper_L", "leg_lower_L",
        "hip_R", "leg_upper_R", "leg_lower_R"
    }

    return tree, order
end

-- Step 2: Equip SDFs
function M.equip_character(tree, style)
    local sdfs = {}
    local body_color = pack_color(0.8, 0.7, 0.6)
    local function add_body(bone, type, params)
        table.insert(sdfs, { bone = bone, type = type, id = 1, color = body_color, params = params or {0.1, 0.1, 0.1, 0.05} })
    end

    add_body("root", "capsule", {0.15, 0.2, 0, 0.1})
    add_body("spine", "capsule", {0.2, 0.3, 0, 0.1})
    add_body("head", "sphere", {0.15, 0, 0, 0.05})
    add_body("arm_upper_L", "capsule", {0.08, 0.25, 0, 0.08})
    add_body("arm_lower_L", "capsule", {0.07, 0.25, 0, 0.08})
    add_body("arm_upper_R", "capsule", {0.08, 0.25, 0, 0.08})
    add_body("arm_lower_R", "capsule", {0.07, 0.25, 0, 0.08})
    add_body("leg_upper_L", "capsule", {0.1, 0.35, 0, 0.08})
    add_body("leg_lower_L", "capsule", {0.09, 0.35, 0, 0.08})
    add_body("leg_upper_R", "capsule", {0.1, 0.35, 0, 0.08})
    add_body("leg_lower_R", "capsule", {0.09, 0.35, 0, 0.08})

    if style == "knight" then
        local metal_color = pack_color(0.5, 0.5, 0.6)
        table.insert(sdfs, { bone = "shoulder_L", type = "sphere", id = 2, color = metal_color, params = {0.15, 0, 0, 0} })
        table.insert(sdfs, { bone = "shoulder_R", type = "sphere", id = 3, color = metal_color, params = {0.15, 0, 0, 0} })
        table.insert(sdfs, { bone = "arm_lower_R", type = "box", id = 4, color = metal_color, params = {0.02, 0.8, 0.05, 0} })
    end

    return sdfs
end

-- Step 3: PBD Assets (Cape)
function M.generate_cape(rows, cols, bone_map)
    local particles = {}
    local constraints = {}
    local spacing = 0.1
    local width = (cols - 1) * spacing
    
    local start_x = -width / 2
    local start_y = 1.2
    local start_z = 0.2

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            local p = {
                pos = {start_x + c * spacing, start_y - r * spacing, start_z},
                inv_mass = (r == 0) and 0.0 or 1.0, -- Pin top row
                bone_index = (r == 0) and bone_map["spine"] or -1,
                id = 50 -- Cloth ID
            }
            table.insert(particles, p)

            -- Constraints
            local idx = r * cols + c
            if c > 0 then -- Horizontal
                table.insert(constraints, {a = idx - 1, b = idx, length = spacing, compliance = 0.01})
            end
            if r > 0 then -- Vertical
                table.insert(constraints, {a = idx - cols, b = idx, length = spacing, compliance = 0.01})
            end
            -- Diagonal (Shear)
            if r > 0 and c > 0 then
                table.insert(constraints, {a = idx - cols - 1, b = idx, length = spacing * 1.414, compliance = 0.05})
            end
        end
    end
    return particles, constraints
end

function M.update_matrices(tree, order, bone_data, bone_map)
    local globals = {}
    for i, name in ipairs(order) do
        local node = tree[name]
        local local_m = mc.mat4_translate(node.offset[1], node.offset[2], node.offset[3])
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_x(node.rot[1]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_y(node.rot[2]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_z(node.rot[3]))

        local parent_global = node.parent and globals[node.parent] or mc.mat4_identity()
        local global_m = mc.mat4_multiply(parent_global, local_m)
        globals[name] = global_m

        local b_idx = bone_map[name]
        if b_idx then
            local inv_m = mc.mat4_inverse(global_m)
            for j=0,15 do
                bone_data[b_idx].world_matrix[j] = global_m.m[j]
                bone_data[b_idx].inv_world_matrix[j] = inv_m.m[j]
            end
        end
    end
end

return M
