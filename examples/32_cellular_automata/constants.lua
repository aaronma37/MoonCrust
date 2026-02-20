local M = {}

-- THE DETAILED MACRO VIEW
M.RES_W = 640
M.RES_H = 360
M.WORLD_W = 2048
M.WORLD_H = 2048

M.MAT = {
    AIR = 0,
    SAND = 1,
    WATER = 2,
    FIRE = 3,
    STEAM = 4,
    LAVA = 5,
    STONE = 6,
    SEED = 7,
    BOMB = 8,
    GRASS = 9,
    WOOD = 10,
    LEAF = 11,
    GROWTH_TIP = 12,
    VINE = 13,
    TRUNK = 14,
    HUMAN = 15,
    BRANCH_NODE = 16,
}

M.PALETTE = {
    [M.MAT.AIR]   = {0.05, 0.05, 0.15},
    [M.MAT.SAND]  = {0.92, 0.82, 0.45},
    [M.MAT.WATER] = {0.15, 0.45, 0.95},
    [M.MAT.FIRE]  = {1.00, 0.35, 0.10},
    [M.MAT.STEAM] = {0.80, 0.80, 0.85},
    [M.MAT.LAVA]  = {1.00, 0.10, 0.05},
    [M.MAT.STONE] = {0.35, 0.35, 0.38},
    [M.MAT.GRASS] = {0.30, 0.85, 0.20},
    [M.MAT.WOOD]  = {0.40, 0.25, 0.10},
    [M.MAT.LEAF]  = {0.10, 0.55, 0.15},
    [M.MAT.SEED]  = {1.00, 1.00, 1.00},
    [M.MAT.VINE]  = {0.10, 0.50, 0.15},
    [M.MAT.TRUNK] = {0.45, 0.25, 0.15},
    [M.MAT.HUMAN] = {1.00, 0.20, 0.20},
    [M.MAT.BRANCH_NODE] = {0.35, 0.25, 0.20},
}

return M
