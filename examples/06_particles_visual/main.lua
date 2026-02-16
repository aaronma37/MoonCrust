local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local graph = require("vulkan.graph")
local staging = require("vulkan.staging")
local vshader = require("vulkan.shader")
local vswapchain = require("vulkan.swapchain")

local M = {}

local PARTICLE_COUNT = 1024 * 1024
local device, queue, graphics_family, sw, cache, rg, cb, pool, sets, image_available_sem, render_finished_sem, pipe_layout

function M.init()
    print("Example 06: Visual 1M Particle Simulation")
    
    local inst = vulkan.create_instance("MoonCrust_Particles_Visual")
    print("Instance Created")
    instance = inst
    physical_device = vulkan.select_physical_device(instance)
    device, graphics_family = vulkan.create_device(physical_device)
    queue = vulkan.get_queue(device, graphics_family)
    sw = vswapchain.new(instance, physical_device, device, _SDL_WINDOW)

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

    -- Particle Buffer
    local buffer_info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = BUFFER_SIZE,
        usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    local pBuffer = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(device, buffer_info, nil, pBuffer)
    local particle_buffer = pBuffer[0]
    local buf_alloc = device_heap:malloc(BUFFER_SIZE)
    vk.vkBindBufferMemory(device, particle_buffer, buf_alloc.memory, buf_alloc.offset)

    -- Staging Data
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    for i = 0, PARTICLE_COUNT - 1 do
        initial_data[i].px = (math.random() * 2.0) - 1.0
        initial_data[i].py = (math.random() * 2.0) - 1.0
        initial_data[i].vx = (math.random() - 0.5) * 0.1
        initial_data[i].vy = (math.random() - 0.5) * 0.1
    end
    local staging_engine = staging.new(physical_device, device, host_heap, BUFFER_SIZE)
    staging_engine:upload_buffer(particle_buffer, initial_data, 0, queue, graphics_family)

    -- Pipelines
    local ds_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT) }
    })
    local pc_range = ffi.new("VkPushConstantRange[1]", {{
        stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT,
        offset = 0, size = 4
    }})
    pipe_layout = pipeline.create_layout(device, {ds_layout}, pc_range)
    
    cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/06_particles_visual/physics.comp", pipe_layout)
    
    local v_source = io.open("examples/06_particles_visual/render.vert"):read("*all")
    local f_source = io.open("examples/06_particles_visual/render.frag"):read("*all")
    local v_spirv = vshader.compile_glsl(v_source, vk.VK_SHADER_STAGE_VERTEX_BIT)
    local f_spirv = vshader.compile_glsl(f_source, vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    local v_mod = vshader.create_module(device, v_spirv)
    local f_mod = vshader.create_module(device, f_spirv)
    local graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod)
    cache.pipelines["render"] = graphics_pipe

    local pool_sizes = {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 1 }}
    local dpool = descriptors.create_pool(device, pool_sizes, 1)
    sets = descriptors.allocate_sets(device, dpool, {ds_layout})
    descriptors.update_buffer_set(device, sets[1], 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer)

    -- Sync
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    local pSem = ffi.new("VkSemaphore[1]")
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); image_available_sem = pSem[0]
    vk.vkCreateSemaphore(device, sem_info, nil, pSem); render_finished_sem = pSem[0]

    cmd_pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, cmd_pool, 1)[1]
end

function M.update()
    cache:update()
    local img_idx = sw:acquire_next_image(image_available_sem)
    local img = sw.images[img_idx]
    local view = sw.views[img_idx]

    command.encode(cb, function(cmd)
        -- 1. Physics Pass
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, cache.pipelines["physics"])
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, sets)
        local dt = ffi.new("float[1]", {0.016})
        vk.vkCmdPushConstants(cmd.buffer, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 4, dt)
        cmd:dispatch(math.ceil(PARTICLE_COUNT / 256), 1, 1)

        -- 2. Barrier: Compute Write -> Vertex Read
        local barrier = ffi.new("VkMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
            srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
            dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT
        }})
        cmd:pipeline_barrier(vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, barrier)

        -- 3. Transition Swapchain Image to Attachment Optimal
        local img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            srcAccessMask = 0,
            dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            image = img,
            subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 }
        }})
        cmd:pipeline_barrier(vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, nil, nil, img_barrier)

        -- 4. Render Pass
        cmd:begin_rendering(sw.extent.width, sw.extent.height, view)
        cmd:set_viewport(sw.extent.width, sw.extent.height)
        cmd:set_scissor(sw.extent.width, sw.extent.height)
        cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_GRAPHICS, cache.pipelines["render"])
        cmd:bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, sets)
        cmd:draw(PARTICLE_COUNT)
        cmd:end_rendering()

        -- 5. Transition Swapchain Image to Present
        img_barrier[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
        img_barrier[0].dstAccessMask = 0
        img_barrier[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        img_barrier[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        cmd:pipeline_barrier(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, nil, nil, img_barrier)
    end)

    -- Submit & Present
    local wait_sems = ffi.new("VkSemaphore[1]", {image_available_sem})
    local signal_sems = ffi.new("VkSemaphore[1]", {render_finished_sem})
    local wait_stages = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT})
    
    local submit_info = ffi.new("VkSubmitInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        waitSemaphoreCount = 1,
        pWaitSemaphores = wait_sems,
        pWaitDstStageMask = wait_stages,
        commandBufferCount = 1,
        pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}),
        signalSemaphoreCount = 1,
        pSignalSemaphores = signal_sems
    })
    vk.vkQueueSubmit(queue, 1, submit_info, nil)
    sw:present(queue, img_idx, render_finished_sem)
    vk.vkQueueWaitIdle(queue)
end

return M
