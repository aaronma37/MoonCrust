package.path = "src/lua/?.lua;src/lua/?/init.lua;" .. package.path

local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")

-- Example Registry
local examples = {
    ["01"] = "examples.01_hello_gpu.main",
    ["02"] = "examples.02_compute_basic.main",
    ["04"] = "examples.04_particles_1m.main",
    ["06"] = "examples.06_particles_visual.main",
    ["07"] = "examples.07_interactive_particles.main",
    ["08"] = "examples.08_slime_mold.main",
}

-- Default to the flagship if no arg provided
local target_key = _STARTUP_ARG or "08"
local target_path = examples[target_key]

if not target_path then
    print("Error: Unknown example '" .. tostring(target_key) .. "'")
    print("Available Examples:")
    for k, v in pairs(examples) do
        print("  " .. k .. " -> " .. v)
    end
    -- Fallback to safe default
    print("Falling back to Example 08...")
    target_path = examples["08"]
end

print("Loading: " .. target_path)
local example = require(target_path)

function mooncrust_update()
    jit.off(true)
    local ok, err = pcall(example.update)
    if not ok then
        print("mooncrust_update: ERROR:", err)
        error(err)
    end
end

-- Initialize the selected example
example.init()

print("MoonCrust Kernel Ready.")
