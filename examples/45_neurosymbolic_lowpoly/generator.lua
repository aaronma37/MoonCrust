local csg = require("csg")

local M = {}

function M.generate_character()
    local skin = {0.85, 0.7, 0.55}
    local robe = {0.2, 0.2, 0.6}
    local beard = {0.9, 0.9, 0.9}
    local eyes = {0.1, 0.1, 0.1}
    
    local parts = {}
    
    -- 1. Torso
    parts.torso = {
        mesh = csg.make_cube(3.0, 4.5, 2.0, robe[1], robe[2], robe[3]),
        offset = {0, 4.2, 0}, pivot = {0, 0, 0}, parent = nil
    }
    
    -- 2. Head & Accessories
    parts.head = {
        mesh = csg.union(
            csg.make_cube(1.8, 1.8, 1.8, skin[1], skin[2], skin[3]),
            csg.union(
                csg.translate(csg.make_cube(0.3, 0.3, 0.1, eyes[1], eyes[2], eyes[3]), -0.4, 0.2, 0.9),
                csg.translate(csg.make_cube(0.3, 0.3, 0.1, eyes[1], eyes[2], eyes[3]), 0.4, 0.2, 0.9)
            )
        ),
        offset = {0, 3.0, 0}, pivot = {0, -0.9, 0}, parent = "torso"
    }
    parts.beard = {
        mesh = csg.make_pyramid(1.6, 2.5, 1.0, beard[1], beard[2], beard[3]),
        offset = {0, -0.5, 0.6}, pivot = {0, 0, 0}, parent = "head"
    }
    parts.hat = {
        mesh = csg.union(
            csg.make_cube(3.0, 0.2, 3.0, robe[1], robe[2], robe[3]),
            csg.translate(csg.make_pyramid(2.2, 4.0, 2.2, robe[1], robe[2], robe[3]), 0, 1.9, 0)
        ),
        offset = {0, 0.9, 0}, pivot = {0, 0, 0}, parent = "head"
    }
    
    -- 3. Arms (2 Segments each)
    -- Left Arm
    parts.arm_l_up = {
        mesh = csg.make_cube(0.7, 2.0, 0.7, robe[1], robe[2], robe[3]),
        offset = {-1.9, 1.5, 0}, pivot = {0, 0.8, 0}, parent = "torso"
    }
    parts.arm_l_low = {
        mesh = csg.union(
            csg.make_cube(0.6, 2.0, 0.6, robe[1], robe[2], robe[3]),
            csg.translate(csg.make_cube(0.7, 0.7, 0.7, skin[1], skin[2], skin[3]), 0, -1.0, 0)
        ),
        offset = {0, -1.8, 0}, pivot = {0, 0.9, 0}, parent = "arm_l_up"
    }
    
    -- Right Arm
    parts.arm_r_up = {
        mesh = csg.make_cube(0.7, 2.0, 0.7, robe[1], robe[2], robe[3]),
        offset = {1.9, 1.5, 0}, pivot = {0, 0.8, 0}, parent = "torso"
    }
    parts.arm_r_low = {
        mesh = csg.union(
            csg.make_cube(0.6, 2.0, 0.6, robe[1], robe[2], robe[3]),
            csg.translate(csg.make_cube(0.7, 0.7, 0.7, skin[1], skin[2], skin[3]), 0, -1.0, 0)
        ),
        offset = {0, -1.8, 0}, pivot = {0, 0.9, 0}, parent = "arm_r_up"
    }
    
    parts.staff = {
        mesh = csg.union(
            csg.make_cube(0.3, 10.0, 0.3, 0.4, 0.2, 0.1),
            csg.translate(csg.make_pyramid(1.0, 1.5, 1.0, 0.2, 0.9, 0.9), 0, 5.5, 0)
        ),
        offset = {0.5, -0.5, 0.5}, pivot = {0, 0, 0}, parent = "arm_r_low"
    }
    
    -- 4. Legs (2 Segments each)
    -- Left Leg
    parts.leg_l_up = {
        mesh = csg.make_cube(1.1, 2.2, 1.1, 0.3, 0.2, 0.1),
        offset = {-0.8, -2.5, 0}, pivot = {0, 1.0, 0}, parent = "torso"
    }
    parts.leg_l_low = {
        mesh = csg.union(
            csg.make_cube(1.0, 2.2, 1.0, 0.3, 0.2, 0.1),
            csg.translate(csg.make_cube(1.1, 0.8, 1.7, 0.1, 0.1, 0.1), 0, -1.1, 0.2)
        ),
        offset = {0, -2.0, 0}, pivot = {0, 1.0, 0}, parent = "leg_l_up"
    }
    
    -- Right Leg
    parts.leg_r_up = {
        mesh = csg.make_cube(1.1, 2.2, 1.1, 0.3, 0.2, 0.1),
        offset = {0.8, -2.5, 0}, pivot = {0, 1.0, 0}, parent = "torso"
    }
    parts.leg_r_low = {
        mesh = csg.union(
            csg.make_cube(1.0, 2.2, 1.0, 0.3, 0.2, 0.1),
            csg.translate(csg.make_cube(1.1, 0.8, 1.7, 0.1, 0.1, 0.1), 0, -1.1, 0.2)
        ),
        offset = {0, -2.0, 0}, pivot = {0, 1.0, 0}, parent = "leg_r_up"
    }

    return parts
end

return M
