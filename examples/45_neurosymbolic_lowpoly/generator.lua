local csg = require("csg")

local M = {}

-- Classic RS style character blocky proportions
function M.generate_character()
    -- Colors
    local skin = {0.8, 0.6, 0.4}
    local shirt = {0.1, 0.5, 0.1}
    local pants = {0.3, 0.2, 0.1}
    local shoes = {0.1, 0.1, 0.1}
    
    -- Body Parts
    local head = csg.make_cube(2, 2, 2, skin[1], skin[2], skin[3])
    head = csg.translate(head, 0, 7, 0)
    
    local torso = csg.make_cube(3, 4, 1.5, shirt[1], shirt[2], shirt[3])
    torso = csg.translate(torso, 0, 4, 0)
    
    local left_arm = csg.make_cube(1, 4, 1, shirt[1], shirt[2], shirt[3])
    left_arm = csg.translate(left_arm, -2, 4, 0)
    
    local right_arm = csg.make_cube(1, 4, 1, shirt[1], shirt[2], shirt[3])
    right_arm = csg.translate(right_arm, 2, 4, 0)
    
    local left_leg = csg.make_cube(1.2, 4, 1.2, pants[1], pants[2], pants[3])
    left_leg = csg.translate(left_leg, -0.8, 0, 0)
    
    local right_leg = csg.make_cube(1.2, 4, 1.2, pants[1], pants[2], pants[3])
    right_leg = csg.translate(right_leg, 0.8, 0, 0)
    
    local left_shoe = csg.make_cube(1.4, 1, 1.8, shoes[1], shoes[2], shoes[3])
    left_shoe = csg.translate(left_shoe, -0.8, -2, 0.2)
    
    local right_shoe = csg.make_cube(1.4, 1, 1.8, shoes[1], shoes[2], shoes[3])
    right_shoe = csg.translate(right_shoe, 0.8, -2, 0.2)
    
    -- Compile
    local char = csg.union(head, torso)
    char = csg.union(char, left_arm)
    char = csg.union(char, right_arm)
    char = csg.union(char, left_leg)
    char = csg.union(char, right_leg)
    char = csg.union(char, left_shoe)
    char = csg.union(char, right_shoe)
    
    return char
end

return M
