local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")

local M = {}
local device, queue, graphics_family, pipe, pipe_layout, sets, buf, data_ptr, cb, cmd_pool

function M.init()
    print("Example 02: Basic Compute")
    
    local instance = vulkan.create_instance("MoonCrust_Basic")
    local physical_device = vulkan.select_physical_device(instance)
    device, graphics_family = vulkan.create_device(physical_device)
    queue = vulkan.get_queue(device, graphics_family)

    -- Pipeline
    local ds_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }
    })
    pipe_layout = pipeline.create_layout(device, {ds_layout})
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("add", "examples/02_compute_basic/add.comp", pipe_layout)
    pipe = cache:get("add")

    -- Data
    local host_mem_type = heap.find_memory_type(physical_device, 0xFFFFFFFF, 
        bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))
    local host_heap = heap.new(physical_device, device, host_mem_type, 1024 * 1024)

    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = 1024,
        usage = vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    }), nil, pBuffer)
    buf = pBuffer[0]
    local alloc = host_heap:malloc(1024)
    vk.vkBindBufferMemory(device, buf, alloc.memory, alloc.offset)

    data_ptr = ffi.cast("uint32_t*", alloc.ptr)
    for i=0, 9 do data_ptr[i] = i end

    local pool = descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 1 }})
    sets = descriptors.allocate_sets(device, pool, {ds_layout})
    descriptors.update_buffer_set(device, sets[1], 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf)

    cmd_pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, cmd_pool, 1)[1]

    print("Running Basic Compute...")
    command.encode(cb, function(cmd)
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, sets)
        cmd:dispatch(1, 1, 1)
        
        local barrier = ffi.new("VkMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
            srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
            dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT
        }})
        cmd:pipeline_barrier(vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, barrier)
    end)
    command.end_and_submit(cb, queue, device)

    print("Result indices 0-4: ", data_ptr[0], data_ptr[1], data_ptr[2], data_ptr[3], data_ptr[4])
end

function M.update()
    -- Run once in init
end

return M
