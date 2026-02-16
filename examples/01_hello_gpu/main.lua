local vulkan = require("vulkan")

local M = {}

function M.init()
    print("Example 01: Hello GPU")
    local instance = vulkan.create_instance("MoonCrust_Hello")
    local physical_device = vulkan.select_physical_device(instance)
    print("Kernel initialized successfully.")
end

function M.update()
    -- Nothing to do here for this example
end

return M
