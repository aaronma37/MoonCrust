local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")

local M = {}

function M.init()
    print("Example 02: Basic Compute (Clean Setup)")
    
    local d = vulkan.get_device()
    local q, family = vulkan.get_queue()
    
    -- 1. Use high-level mc.buffer (host_visible=true for readback)
    local buf_size = 1024
    local buf = mc.buffer(buf_size, "storage", nil, true)
    
    local data_ptr = ffi.cast("uint32_t*", buf.allocation.ptr)
    for i=0, 9 do data_ptr[i] = i end

    -- 2. Create a compute pipeline
    local pipe = mc.compute_pipeline("examples/02_compute_basic/add.comp")
    
    -- 3. Update bindless descriptor set
    local bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(d, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, buf.handle, 0, buf_size, 0)

    -- 4. Execute
    local pool = command.create_pool(d, family)
    local cb = command.allocate_buffers(d, pool, 1)[1]

    print("Running Basic Compute...")
    command.encode(cb, function(cmd)
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe.handle)
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe.layout, 0, {bindless_set})
        cmd:dispatch(1, 1, 1)
        
        local barrier = ffi.new("VkMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
            srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
            dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT
        }})
        cmd:pipeline_barrier(vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, barrier)
    end)
    command.end_and_submit(cb, q, d)

    print("Result indices 0-4 (Expected: 1, 2, 3, 4, 5):", data_ptr[0], data_ptr[1], data_ptr[2], data_ptr[3], data_ptr[4])
    
    -- Cleanup
    vk.vkDestroyCommandPool(d, pool, nil)
end

function M.update()
end

return M
