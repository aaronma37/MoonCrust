local vulkan = require("vulkan")

local M = {}

function M.init()
    print("Example 01: Hello GPU")
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    local device = vulkan.get_device()
    local queue, family = vulkan.get_queue()
    print("Vulkan Instance: ", instance)
    print("Physical Device: ", physical_device)
    print("Logical Device:  ", device)
    print("Queue:           ", queue, " Family:", family)
    print("Kernel initialized successfully.")
end

function M.update()
    -- Nothing to do here for this example
end

return M
