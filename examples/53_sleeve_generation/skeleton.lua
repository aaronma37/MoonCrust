local dae = require("examples.53_sleeve_generation.dae_loader")

local M = {}

function M.get_bone_list()
    local path = "examples/53_sleeve_generation/X Bot.dae"
    local bones = dae.load_skeleton(path)
    
    -- Scale the skeleton for easier viewing (Mixamo is usually in cm)
    local scale = 0.1
    for _, b in ipairs(bones) do
        b.pos[1] = b.pos[1] * scale
        b.pos[2] = b.pos[2] * scale
        b.pos[3] = b.pos[3] * scale
    end
    
    return bones
end

return M
