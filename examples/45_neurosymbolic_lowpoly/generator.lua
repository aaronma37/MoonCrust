local csg = require("csg")

local M = {}

function M.generate_tree()
    local trunk = csg.make_cube(1, 4, 1)
    trunk = csg.translate(trunk, 0, 2, 0)
    
    local leaves = csg.make_cube(4, 4, 4)
    leaves = csg.translate(leaves, 0, 5, 0)
    
    return csg.union(trunk, leaves)
end

function M.generate_forest(num_trees)
    local forest = csg.create_mesh()
    math.randomseed(42)
    for i=1, num_trees do
        local x = math.random(-30, 30)
        local z = math.random(-30, 30)
        local scale = math.random(60, 150) / 100.0
        
        local tree = M.generate_tree()
        tree = csg.scale(tree, scale, scale, scale)
        tree = csg.translate(tree, x, 0, z)
        
        forest = csg.union(forest, tree)
    end
    return forest
end

return M
