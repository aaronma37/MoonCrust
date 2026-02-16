-- MoonCrust Kernel Launcher
package.path = package.path .. ";src/lua/?.lua;src/lua/?/init.lua;./?.lua"

-- Configuration: Set the example you want to run here
local CURRENT_EXAMPLE = "examples.06_particles_visual.main"

print("MoonCrust Kernel Starting...")
print("Loading Example: " .. CURRENT_EXAMPLE)

local example = require(CURRENT_EXAMPLE)

-- Initialize the selected example
example.init()

function mooncrust_update()
    -- Main loop delegate to the example
    example.update()
end

print("MoonCrust Kernel Ready.")
