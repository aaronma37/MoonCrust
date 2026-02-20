local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")

local M = {}

local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, pipe, cb, cmd_pool

function M.init()
    print("Example 04: 1M Particle Simulation (using mc.gpu StdLib)")
    
    local d = vulkan.get_device()
    local q, family = vulkan.get_queue()

    ffi.cdef[[
        typedef struct Particle {
            float px, py;
            float vx, vy;
        } Particle;
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- 1. Initial data for staging
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do
        initial_data[i].px = (math.random() * 2.0) - 1.0
        initial_data[i].py = (math.random() * 2.0) - 1.0
        initial_data[i].vx = (math.random() - 0.5) * 0.1
        initial_data[i].vy = (math.random() - 0.5) * 0.1
    end

    -- 2. Use mc.buffer factory (handles staging upload automatically)
    local buf = mc.buffer(BUFFER_SIZE, "storage", initial_data)
    M.particle_buffer = buf

    -- 3. Create a compute pipeline using the StdLib
    pipe = mc.compute_pipeline("examples/04_particles_1m/particles.comp", 4) -- 4 bytes for dt push constant
    
    -- 4. Update bindless descriptor set (Binding 0 for buffers)
    local bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(d, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf.handle, 0, BUFFER_SIZE, 0)

    -- 5. Command buffer setup
    cmd_pool = command.create_pool(d, family)
    cb = command.allocate_buffers(d, cmd_pool, 1)[1]
end

function M.update()
    pipe.cache:update()
    local d = vulkan.get_device()
    local q, _ = vulkan.get_queue()
    local bindless_set = mc.gpu.get_bindless_set()

    command.encode(cb, function(cmd)
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe.handle)
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe.layout, 0, {bindless_set})
        
        local dt = ffi.new("float[1]", {0.016})
        vk.vkCmdPushConstants(cmd.buffer, pipe.layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 4, dt)
        
        cmd:dispatch(math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end)
    command.end_and_submit(cb, q, d)
end

return M
