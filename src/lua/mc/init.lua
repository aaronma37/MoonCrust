local M = {}

M.math = require("mc.math")
M.gpu = require("mc.gpu")
M.input = require("mc.input")

-- Alias common math functions directly to mc for convenience
for k, v in pairs(require("mc.math")) do
    M[k] = v
end

-- Alias common gpu functions
M.buffer = M.gpu.buffer
M.image = M.gpu.image
M.compute_pipeline = M.gpu.compute_pipeline

function M.tick()
    M.gpu.tick()
    M.input.tick()
end

return M
