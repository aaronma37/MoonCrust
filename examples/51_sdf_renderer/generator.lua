local mc = require("mc")
local ffi = require("ffi")

local M = {}

local function pack_color(r, g, b)
    local ir = math.floor(r * 255)
    local ig = math.floor(g * 255)
    local ib = math.floor(b * 255)
    return bit.bor(bit.lshift(ir, 16), bit.lshift(ig, 8), ib)
end

function M.create_skeleton()
    local tree = {
        root = { parent = nil, offset = {0, 0.8, 0}, rot = {0,0,0}, base_offset = {0, 0.8, 0} },
        spine = { parent = "root", offset = {0, 0.2, 0}, rot = {0,0,0} },
        neck = { parent = "spine", offset = {0, 0.25, 0}, rot = {0,0,0} },
        head = { parent = "neck", offset = {0, 0.15, 0}, rot = {0,0,0} },
        
        shoulder_L = { parent = "spine", offset = {-0.2, 0.15, 0}, rot = {0,0,0} },
        arm_upper_L = { parent = "shoulder_L", offset = {0, -0.25, 0}, rot = {0,0,0} },
        arm_lower_L = { parent = "arm_upper_L", offset = {0, -0.25, 0}, rot = {0,0,0} },
        hand_L = { parent = "arm_lower_L", offset = {0, -0.1, 0}, rot = {0,0,0} },
        
        shoulder_R = { parent = "spine", offset = {0.2, 0.15, 0}, rot = {0,0,0} },
        arm_upper_R = { parent = "shoulder_R", offset = {0, -0.25, 0}, rot = {0,0,0} },
        arm_lower_R = { parent = "arm_upper_R", offset = {0, -0.25, 0}, rot = {0,0,0} },
        hand_R = { parent = "arm_lower_R", offset = {0, -0.1, 0}, rot = {0,0,0} },

        hip_L = { parent = "root", offset = {-0.12, -0.05, 0}, rot = {0,0,0} },
        leg_upper_L = { parent = "hip_L", offset = {0, -0.35, 0}, rot = {0,0,0} },
        leg_lower_L = { parent = "leg_upper_L", offset = {0, -0.35, 0}, rot = {0,0,0} },
        foot_L = { parent = "leg_lower_L", offset = {0, -0.05, 0.05}, rot = {0,0,0} },

        hip_R = { parent = "root", offset = {0.12, -0.05, 0}, rot = {0,0,0} },
        leg_upper_R = { parent = "hip_R", offset = {0, -0.35, 0}, rot = {0,0,0} },
        leg_lower_R = { parent = "leg_upper_R", offset = {0, -0.35, 0}, rot = {0,0,0} },
        foot_R = { parent = "leg_lower_R", offset = {0, -0.05, 0.05}, rot = {0,0,0} },
    }

    local order = {
        "root", "spine", "neck", "head",
        "shoulder_L", "arm_upper_L", "arm_lower_L", "hand_L",
        "shoulder_R", "arm_upper_R", "arm_lower_R", "hand_R",
        "hip_L", "leg_upper_L", "leg_lower_L", "foot_L",
        "hip_R", "leg_upper_R", "leg_lower_R", "foot_R"
    }

    return tree, order
end

function M.apply_pose(tree, time, state)
    for k, v in pairs(tree) do v.rot = {0, 0, 0} end
    tree.root.offset[2] = tree.root.base_offset[2]

    if state == "walk" then
        local t = time * 5.0
        tree.hip_L.rot[1] = math.sin(t) * 0.6
        tree.hip_R.rot[1] = math.sin(t + math.pi) * 0.6
        tree.leg_upper_L.rot[1] = math.max(0, math.sin(t + 1.5)) * 1.0
        tree.leg_upper_R.rot[1] = math.max(0, math.sin(t + math.pi + 1.5)) * 1.0
        tree.leg_lower_L.rot[1] = -tree.hip_L.rot[1] - tree.leg_upper_L.rot[1] + 0.1
        tree.leg_lower_R.rot[1] = -tree.hip_R.rot[1] - tree.leg_upper_R.rot[1] + 0.1
        tree.shoulder_L.rot[1] = math.sin(t + math.pi) * 0.5
        tree.shoulder_R.rot[1] = math.sin(t) * 0.5
        tree.arm_upper_L.rot[1] = -0.3 + math.sin(t + math.pi) * 0.2
        tree.arm_upper_R.rot[1] = -0.3 + math.sin(t) * 0.2
        tree.root.offset[2] = tree.root.base_offset[2] + math.abs(math.sin(t)) * 0.04
    end
end

local equipment_lib = {
    helmets = {
        bucket = function(sdfs)
            local metal = pack_color(0.6, 0.6, 0.65)
            local gold = pack_color(0.8, 0.7, 0.2)
            local dark_metal = pack_color(0.3, 0.3, 0.35)
            table.insert(sdfs, { bone = "head", type = "capsule", id = 10, color = metal, params = {0.12, -0.05, 0.05, 0.01}, offset = {0, 0, 0} })
            table.insert(sdfs, { bone = "head", type = "box", id = 11, color = dark_metal, params = {0.08, 0.02, 0.04, 0.0}, offset = {0, 0.02, 0.1} })
            table.insert(sdfs, { bone = "head", type = "sphere", id = 12, color = gold, params = {0.03, 0, 0, 0.0}, offset = {0, 0.18, 0} })
        end
    },
    shoulders = {
        plate_pauldrons = function(sdfs)
            local gold = pack_color(0.8, 0.7, 0.2)
            table.insert(sdfs, { bone = "shoulder_L", type = "sphere", id = 13, color = gold, params = {0.11, 0, 0, 0.0}, offset = {-0.02, 0.05, 0} })
            table.insert(sdfs, { bone = "shoulder_R", type = "sphere", id = 14, color = gold, params = {0.11, 0, 0, 0.0}, offset = {0.02, 0.05, 0} })
        end
    },
    arms = {
        plate_bracers = function(sdfs)
            local metal = pack_color(0.6, 0.6, 0.65)
            table.insert(sdfs, { bone = "arm_lower_L", type = "capsule", id = 15, color = metal, params = {0.055, -0.05, -0.2, 0.0} })
            table.insert(sdfs, { bone = "arm_lower_R", type = "capsule", id = 16, color = metal, params = {0.055, -0.05, -0.2, 0.0} })
        end
    },
    right_hand = {
        sword = function(sdfs)
            local metal = pack_color(0.6, 0.6, 0.65)
            local gold = pack_color(0.8, 0.7, 0.2)
            table.insert(sdfs, { bone = "hand_R", type = "box", id = 17, color = metal, params = {0.02, 0.4, 0.05, 0.0}, offset = {0, -0.3, 0.1} })
            table.insert(sdfs, { bone = "hand_R", type = "box", id = 18, color = gold, params = {0.12, 0.02, 0.03, 0.0}, offset = {0, 0.1, 0.1} })
            table.insert(sdfs, { bone = "hand_R", type = "sphere", id = 19, color = gold, params = {0.04, 0, 0, 0}, offset = {0, 0.2, 0.1} })
        end
    }
}

function M.equip_character(tree, loadout, time)
    local sdfs = {}
    local body_color = pack_color(0.8, 0.7, 0.6)
    local function add_body(bone, type, params, offset)
        table.insert(sdfs, { bone = bone, type = type, id = 1, color = body_color, params = params, offset = offset })
    end

    local breathe = math.sin(time * 2.0) * 0.01
    add_body("root", "capsule", {0.12, -0.05, 0.05, 0.05})
    add_body("spine", "capsule", {0.14 + breathe, -0.1, 0.1, 0.08}) 
    add_body("spine", "box", {0.18, 0.04, 0.08, 0.05}, {0, 0.15, 0})
    add_body("neck", "capsule", {0.04, -0.02, 0.15, 0.03})
    add_body("head", "sphere", {0.09, 0, 0, 0.02})
    add_body("shoulder_L", "sphere", {0.07, 0, 0, 0.05})     
    add_body("shoulder_L", "capsule", {0.05, 0.0, -0.22, 0.05}) 
    add_body("arm_upper_L", "capsule", {0.04, 0.0, -0.22, 0.05}) 
    add_body("arm_lower_L", "sphere", {0.05, 0, 0, 0.05}) 
    add_body("shoulder_R", "sphere", {0.07, 0, 0, 0.05})
    add_body("shoulder_R", "capsule", {0.05, 0.0, -0.22, 0.05})
    add_body("arm_upper_R", "capsule", {0.04, 0.0, -0.22, 0.05})
    add_body("arm_lower_R", "sphere", {0.05, 0, 0, 0.05})
    add_body("hip_L", "sphere", {0.08, 0, 0, 0.05})          
    add_body("hip_L", "capsule", {0.07, 0.0, -0.35, 0.05}) 
    add_body("leg_upper_L", "capsule", {0.06, 0.0, -0.35, 0.05}) 
    add_body("leg_lower_L", "box", {0.06, 0.04, 0.1, 0.05}) 
    add_body("hip_R", "sphere", {0.08, 0, 0, 0.05})
    add_body("hip_R", "capsule", {0.07, 0.0, -0.35, 0.05})
    add_body("leg_upper_R", "capsule", {0.06, 0.0, -0.35, 0.05})
    add_body("leg_lower_R", "box", {0.06, 0.04, 0.1, 0.05})

    if loadout then
        for k, v in pairs(loadout) do
            if equipment_lib[k] and equipment_lib[k][v] then equipment_lib[k][v](sdfs) end
        end
    end
    return sdfs
end

function M.generate_dynamic_assets(loadout, bone_map)
    local particles = {}
    local constraints = {}
    
    if loadout.back == "cape" then
        local rows, cols = 12, 12
        local spacing = 0.1
        local width = (cols - 1) * spacing
        local start_x, start_y, start_z = -width / 2, 1.15, 0.15
        for r = 0, rows - 1 do
            for c = 0, cols - 1 do
                table.insert(particles, { pos = {start_x + c * spacing, start_y - r * spacing, start_z}, inv_mass = (r == 0) and 0.0 or 1.0, bone_index = (r == 0) and bone_map["spine"] or -1, id = 50 })
                local idx = #particles - 1
                if c > 0 then table.insert(constraints, {a = idx - 1, b = idx, length = spacing, compliance = 0.005}) end
                if r > 0 then table.insert(constraints, {a = idx - cols, b = idx, length = spacing, compliance = 0.005}) end
            end
        end
    end

    if loadout.hair == "ponytail" then
        local hair_start_idx = #particles
        local hair_count, hair_spacing = 5, 0.08
        local start_y = 1.3 -- Approximately back of head
        for i = 0, hair_count - 1 do
            table.insert(particles, { pos = {0, start_y, -0.1 - i * hair_spacing}, inv_mass = (i == 0) and 0.0 or 1.0, bone_index = (i == 0) and bone_map["head"] or -1, id = 51 })
            if i > 0 then table.insert(constraints, {a = hair_start_idx + i - 1, b = hair_start_idx + i, length = hair_spacing, compliance = 0.001}) end
        end
    end

    return particles, constraints
end

function M.update_matrices(tree, order, bone_data, bone_map, ground_y)
    local globals = {}
    local min_y = 1e10

    -- Pass 1: Compute Hierarchy
    for i, name in ipairs(order) do
        local node = tree[name]
        local local_m = mc.mat4_translate(node.offset[1], node.offset[2], node.offset[3])
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_x(node.rot[1]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_y(node.rot[2]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_z(node.rot[3]))

        local parent_global = node.parent and globals[node.parent] or mc.mat4_identity()
        local global_m = mc.mat4_multiply(parent_global, local_m)
        globals[name] = global_m

        -- Track lowest point (Feet)
        if name == "foot_L" or name == "foot_R" then
            local y = global_m.m[13] - 0.05 -- Sole of the foot
            if y < min_y then min_y = y end
        end
    end

    -- Pass 2: Apply Grounding Offset and Write to GPU
    local shift_y = (ground_y or -0.5) - min_y
    for i, name in ipairs(order) do
        local global_m = globals[name]
        global_m.m[13] = global_m.m[13] + shift_y -- Apply vertical grounding

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
