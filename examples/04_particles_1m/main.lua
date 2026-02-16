local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local graph = require("vulkan.graph")
local staging = require("vulkan.staging")

local M = {}

local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, cache, rg, cb, cmd_pool, sets, data_ptr

function M.init()
    print("Example 04: 1M Particle Simulation")
    
    local instance = vulkan.create_instance("MoonCrust_Particles")
    local physical_device = vulkan.select_physical_device(instance)
    device, graphics_family = vulkan.create_device(physical_device)
    queue = vulkan.get_queue(device, graphics_family)

    ffi.cdef[[
        typedef struct Particle {
            float px, py;
            float vx, vy;
        } Particle;
    ]]
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT

    -- Heaps
    local host_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, 
        bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))
    local host_heap = heap.new(physical_device, device, host_mem_type, 32 * 1024 * 1024)

    local device_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
    local device_heap = heap.new(physical_device, device, device_mem_type, 64 * 1024 * 1024)

    -- Buffer
    local buffer_info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = BUFFER_SIZE,
        usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT),
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, buffer_info, nil, pBuffer)
    local particle_buffer = pBuffer[0]

    local buf_alloc = device_heap:malloc(BUFFER_SIZE)
    vk.vkBindBufferMemory(device, particle_buffer, buf_alloc.memory, buf_alloc.offset)

    -- Staging
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do
        initial_data[i].px = (math.random() * 2.0) - 1.0
        initial_data[i].py = (math.random() * 2.0) - 1.0
        initial_data[i].vx = (math.random() - 0.5) * 0.1
        initial_data[i].vy = (math.random() - 0.5) * 0.1
    end

    local staging_engine = staging.new(physical_device, device, host_heap, BUFFER_SIZE)
    staging_engine:upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- Pipeline
    local ds_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }
    })
    local pc_range = ffi.new("VkPushConstantRange[1]", {{
        stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT,
        offset = 0,
        size = 4
    }})
    local pipe_layout = pipeline.create_layout(device, {ds_layout}, pc_range)
    cache = pipeline.new_cache(device)
    cache:add_compute_from_file("simulation", "examples/04_particles_1m/particles.comp", pipe_layout)

    local pool = descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 1 }})
    sets = descriptors.allocate_sets(device, pool, {ds_layout})
    descriptors.update_buffer_set(device, sets[1], 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer)

    -- Graph
    rg = graph.new(device)
    local res_particles = rg:add_resource("particles", graph.TYPE_BUFFER, particle_buffer)
    rg:add_pass("UpdateParticles", function(cmd)
        local pipe, layout = cache:get("simulation")
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, sets)
        local dt = ffi.new("float[1]", {0.016})
        vk.vkCmdPushConstants(cmd.buffer, layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 4, dt)
        cmd:dispatch(math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):write(res_particles, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    cmd_pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, cmd_pool, 1)[1]
end

function M.update()
    cache:update()
    command.encode(cb, function(cmd)
        rg:execute(cb, cmd)
    end)
    command.end_and_submit(cb, queue, device)
end

return M
