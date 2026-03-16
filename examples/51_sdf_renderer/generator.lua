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
    -- True anatomical joints:
    -- shoulder -> rotates upper arm
    -- arm_upper -> elbow, rotates lower arm
    -- arm_lower -> wrist, rotates hand
    -- hip -> rotates upper leg
    -- leg_upper -> knee, rotates lower leg
    -- leg_lower -> ankle, rotates foot
    local tree = {
        root = { parent = nil, offset = {0, 0.9, 0}, rot = {0,0,0}, base_offset = {0, 0.9, 0} },
        spine = { parent = "root", offset = {0, 0.25, 0}, rot = {0,0,0} },
        neck = { parent = "spine", offset = {0, 0.2, 0}, rot = {0,0,0} },
        head = { parent = "neck", offset = {0, 0.15, 0}, rot = {0,0,0} },
        
        shoulder_L = { parent = "spine", offset = {-0.2, 0.1, 0}, rot = {0,0,0} },
        arm_upper_L = { parent = "shoulder_L", offset = {0, -0.25, 0}, rot = {0,0,0} },
        arm_lower_L = { parent = "arm_upper_L", offset = {0, -0.25, 0}, rot = {0,0,0} },
        hand_L = { parent = "arm_lower_L", offset = {0, -0.1, 0}, rot = {0,0,0} },
        
        shoulder_R = { parent = "spine", offset = {0.2, 0.1, 0}, rot = {0,0,0} },
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
        
        tree.hip_L.rot[1] = math.sin(t) * 0.8
        tree.hip_R.rot[1] = math.sin(t + math.pi) * 0.8
        
        -- Knee is leg_upper. Bends backwards (positive X rot)
        tree.leg_upper_L.rot[1] = math.max(0, math.sin(t + 1.5)) * 1.2
        tree.leg_upper_R.rot[1] = math.max(0, math.sin(t + math.pi + 1.5)) * 1.2

        -- Foot plant
        tree.leg_lower_L.rot[1] = -tree.hip_L.rot[1] - tree.leg_upper_L.rot[1] + 0.2
        tree.leg_lower_R.rot[1] = -tree.hip_R.rot[1] - tree.leg_upper_R.rot[1] + 0.2

        tree.shoulder_L.rot[1] = math.sin(t + math.pi) * 0.6
        tree.shoulder_R.rot[1] = math.sin(t) * 0.6
        
        -- Elbow is arm_upper. Bends forwards/upwards (negative X rot)
        tree.arm_upper_L.rot[1] = -0.2 + math.sin(t + math.pi) * 0.2
        tree.arm_upper_R.rot[1] = -0.2 + math.sin(t) * 0.2

        tree.shoulder_L.rot[3] = 0.15
        tree.shoulder_R.rot[3] = -0.15

        tree.spine.rot[2] = math.sin(t) * 0.2
        tree.neck.rot[2] = -math.sin(t) * 0.2 

        tree.root.offset[2] = tree.root.base_offset[2] + math.abs(math.sin(t)) * 0.05
    end
end

function M.equip_character(tree, style)
    local sdfs = {}
    local body_color = pack_color(0.8, 0.7, 0.6)
    
    local function add_body(bone, type, params)
        table.insert(sdfs, { bone = bone, type = type, id = 1, color = body_color, params = params })
    end

    -- Torso & Head
    add_body("root", "capsule", {0.13, -0.05, 0.05, 0.05})   -- Pelvis
    add_body("spine", "capsule", {0.15, -0.15, 0.05, 0.05})  -- Chest
    add_body("neck", "capsule", {0.04, -0.05, 0.1, 0.02})    -- Neck
    add_body("head", "sphere", {0.1, 0, 0, 0.02})            -- Head
    
    -- Left Arm 
    add_body("shoulder_L", "sphere", {0.08, 0, 0, 0.05})     -- Shoulder socket
    add_body("shoulder_L", "capsule", {0.05, 0.0, -0.25, 0.05}) -- Upper arm (rotates with shoulder)
    add_body("arm_upper_L", "capsule", {0.04, 0.0, -0.25, 0.05}) -- Lower arm (rotates with elbow)
    add_body("arm_lower_L", "sphere", {0.05, 0, 0, 0.05}) -- Hand (rotates with wrist)

    -- Right Arm
    add_body("shoulder_R", "sphere", {0.08, 0, 0, 0.05})
    add_body("shoulder_R", "capsule", {0.05, 0.0, -0.25, 0.05})
    add_body("arm_upper_R", "capsule", {0.04, 0.0, -0.25, 0.05})
    add_body("arm_lower_R", "sphere", {0.05, 0, 0, 0.05})

    -- Left Leg
    add_body("hip_L", "sphere", {0.09, 0, 0, 0.05})          -- Hip socket
    add_body("hip_L", "capsule", {0.07, 0.0, -0.35, 0.05}) -- Upper leg (rotates with hip)
    add_body("leg_upper_L", "capsule", {0.06, 0.0, -0.35, 0.05}) -- Lower leg (rotates with knee)
    add_body("leg_lower_L", "box", {0.05, 0.04, 0.1, 0.05}) -- Foot (at ankle)  

    -- Right Leg
    add_body("hip_R", "sphere", {0.09, 0, 0, 0.05})
    add_body("hip_R", "capsule", {0.07, 0.0, -0.35, 0.05})
    add_body("leg_upper_R", "capsule", {0.06, 0.0, -0.35, 0.05})
    add_body("leg_lower_R", "box", {0.05, 0.04, 0.1, 0.05})

    if style == "knight" then
        local metal = pack_color(0.6, 0.6, 0.65)
        local gold = pack_color(0.8, 0.7, 0.2)
        local dark_metal = pack_color(0.3, 0.3, 0.35)

        -- Bucket Helm (Head)
        table.insert(sdfs, { bone = "head", type = "capsule", id = 10, color = metal, params = {0.12, -0.05, 0.05, 0.01} })
        -- Eye slit (subtracts implicitly if we set id to background, but for now we just add a dark box over the eyes)
        table.insert(sdfs, { bone = "head", type = "box", id = 11, color = dark_metal, params = {0.08, 0.02, 0.13, 0.0} })

        -- Pauldrons (Shoulders)
        table.insert(sdfs, { bone = "shoulder_L", type = "sphere", id = 12, color = gold, params = {0.11, 0, 0, 0.0} })
        table.insert(sdfs, { bone = "shoulder_R", type = "sphere", id = 13, color = gold, params = {0.11, 0, 0, 0.0} })

        -- Bracers (Lower Arms)
        table.insert(sdfs, { bone = "arm_upper_L", type = "capsule", id = 14, color = metal, params = {0.055, -0.05, -0.2, 0.0} })
        table.insert(sdfs, { bone = "arm_upper_R", type = "capsule", id = 15, color = metal, params = {0.055, -0.05, -0.2, 0.0} })

        -- Sword (Right Hand)
        -- Blade
        table.insert(sdfs, { bone = "arm_lower_R", type = "box", id = 16, color = metal, params = {0.02, 0.4, 0.05, 0.0} })
        -- Crossguard
        table.insert(sdfs, { bone = "arm_lower_R", type = "box", id = 17, color = gold, params = {0.12, 0.02, 0.03, 0.0} })
    end

    return sdfs
end

function M.generate_cape(rows, cols, bone_map)
    local particles = {}
    local constraints = {}
    local spacing = 0.1
    local width = (cols - 1) * spacing
    
    local start_x = -width / 2
    local start_y = 1.05
    local start_z = 0.15

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            local p = {
                pos = {start_x + c * spacing, start_y - r * spacing, start_z},
                inv_mass = (r == 0) and 0.0 or 1.0, 
                bone_index = (r == 0) and bone_map["spine"] or -1,
                id = 50 
            }
            table.insert(particles, p)

            local idx = r * cols + c
            if c > 0 then 
                table.insert(constraints, {a = idx - 1, b = idx, length = spacing, compliance = 0.005})
            end
            if r > 0 then 
                table.insert(constraints, {a = idx - cols, b = idx, length = spacing, compliance = 0.005})
            end
            if r > 0 and c > 0 then
                table.insert(constraints, {a = idx - cols - 1, b = idx, length = spacing * 1.414, compliance = 0.01})
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
