package.path = "src/lua/?.lua;src/lua/?/init.lua;" .. package.path
local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")

-- Example Selector
local CURRENT_EXAMPLE = "examples.06_particles_visual.main"
local example = require(CURRENT_EXAMPLE)

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

print("MoonCrust Hybrid Kernel Ready.")
