local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local image = require("vulkan.image")
local swapchain = require("vulkan.swapchain")
local staging = require("vulkan.staging")
local render_graph = require("vulkan.graph")
local sdl = require("vulkan.sdl")

local M = {}

-- CONFIG
local TERM_W = 80
local TERM_H = 40
local PARTICLES_PER_CHAR = 256
local PARTICLE_COUNT = TERM_W * TERM_H * PARTICLES_PER_CHAR

-- State
local device, queue, graphics_family, sw, pipe_layout, graphics_pipe
local bindless_set, cbs, graph
local g_pBuffer, g_tBuffer, g_swImages = {}, {}, {}
local current_time = 0

-- Lua-side Text Buffer
local text_buffer = ffi.new("uint32_t[?]", TERM_W * TERM_H)
local cursor_x, cursor_y = 0, 0

ffi.cdef[[
    typedef struct Particle { 
        float px, py, pz, pw; 
        float vx, vy, vz, vw; 
        float temp;
        uint32_t cell_id;
        uint32_t char_id;
        uint32_t pad;
    } Particle;

    typedef struct PushConstants { 
        float dt;
        float time;
        uint32_t p_buf;
        uint32_t t_buf;
        uint32_t sdf_tex;
        uint32_t term_w;
        uint32_t term_h;
        uint32_t particles_per_char;
    } PushConstants;
]]

function M.init()
    print("Example 40: PARTICLE TERMINAL (Back to Basics)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)

    -- 1. Initialize Particles (Careful initialization)
    local BUFFER_SIZE = ffi.sizeof("Particle") * PARTICLE_COUNT
    local initial_data = ffi.new("Particle[?]", PARTICLE_COUNT)
    math.randomseed(os.time())
    
    local cell_w = 2.0 / TERM_W
    local cell_h = 2.0 / TERM_H

    for i = 0, PARTICLE_COUNT - 1 do
        local cell_id = math.floor(i / PARTICLES_PER_CHAR)
        local cx = cell_id % TERM_W
        local cy = math.floor(cell_id / TERM_W)
        
        initial_data[i].px = ((cx / TERM_W) * 2 - 1) + (math.random() * cell_w)
        initial_data[i].py = ((cy / TERM_H) * 2 - 1) + (math.random() * cell_h)
        initial_data[i].pz = 0.5
        initial_data[i].pw = 0.0 -- Visibility
        
        initial_data[i].vx = 0
        initial_data[i].vy = 0
        initial_data[i].vz = 0
        initial_data[i].vw = 0
        
        initial_data[i].temp = 1.0
        initial_data[i].cell_id = cell_id
        initial_data[i].char_id = 32 -- Space
        initial_data[i].pad = 0
    end
    
    local particle_buffer = mc.buffer(BUFFER_SIZE, "storage", initial_data)
    
    -- 2. Text Buffer
    local text_buf_size = TERM_W * TERM_H * 4
    for i=0, (TERM_W * TERM_H)-1 do text_buffer[i] = 32 end 
    local text_gpu_buffer = mc.buffer(text_buf_size, "storage", text_buffer, true)
    M.text_ptr = ffi.cast("uint32_t*", text_gpu_buffer.allocation.ptr)

    -- 3. Bindless
    bindless_set = mc.gpu.get_bindless_set()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, particle_buffer.handle, 0, BUFFER_SIZE, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, text_gpu_buffer.handle, 0, text_buf_size, 1)

    -- 4. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 32 }})
    pipe_layout = pipeline.create_layout(device, {mc.gpu.get_bindless_layout()}, pc_range)
    
    local cache = pipeline.new_cache(device)
    cache:add_compute_from_file("physics", "examples/40_particle_term/physics.comp", pipe_layout)
    
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, 
        shader.create_module(device, shader.compile_glsl(io.open("examples/40_particle_term/render.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), 
        shader.create_module(device, shader.compile_glsl(io.open("examples/40_particle_term/render.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), 
        { 
            additive = true,
            depth_write = false,
            depth_test = false,
            topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST
        }
    )

    -- 5. Render Graph
    graph = render_graph.new(device)
    g_pBuffer = graph:register_resource("ParticleBuffer", render_graph.TYPE_BUFFER, particle_buffer.handle)
    g_tBuffer = graph:register_resource("TextBuffer", render_graph.TYPE_BUFFER, text_gpu_buffer.handle)
    for i=0, sw.image_count-1 do g_swImages[i] = graph:register_resource("SW_"..i, render_graph.TYPE_IMAGE, sw.images[i]) end
    
    -- Sync
    M.MAX_FRAMES_IN_FLIGHT = 2
    M.current_frame = 0
    local pF = ffi.new("VkFence[1]")
    local pS = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO})
    local fence_info = ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT})

    M.frame_fences = {}
    M.image_available_sems = {}
    M.render_finished_sems = {}

    for i=0, M.MAX_FRAMES_IN_FLIGHT-1 do
        vk.vkCreateFence(device, fence_info, nil, pF); M.frame_fences[i] = pF[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.image_available_sems[i] = pS[0]
        vk.vkCreateSemaphore(device, sem_info, nil, pS); M.render_finished_sems[i] = pS[0]
    end
    
    cbs = command.allocate_buffers(device, command.create_pool(device, graphics_family), M.MAX_FRAMES_IN_FLIGHT)
    M.cache = cache

    M.write_string("MOONCRUST PARTICLE TERMINAL V1.0\nREADY > ")
end

function M.write_string(str)
    for i = 1, #str do
        local char = str:sub(i,i)
        if char == "\n" then
            cursor_x = 0
            cursor_y = cursor_y + 1
        else
            if cursor_x >= TERM_W then
                cursor_x = 0
                cursor_y = cursor_y + 1
            end
            if cursor_y < TERM_H then
                M.text_ptr[cursor_y * TERM_W + cursor_x] = string.byte(char)
                cursor_x = cursor_x + 1
            end
        end
        if cursor_y >= TERM_H then
            for y = 0, TERM_H - 2 do
                ffi.copy(M.text_ptr + y * TERM_W, M.text_ptr + (y + 1) * TERM_W, TERM_W * 4)
            end
            for x = 0, TERM_W - 1 do M.text_ptr[(TERM_H - 1) * TERM_W + x] = 32 end
            cursor_y = TERM_H - 1
        end
    end
end

local last_ticks = 0

function M.update()
    M.cache:update()
    local ticks = tonumber(sdl.SDL_GetTicks())
    if last_ticks == 0 then last_ticks = ticks end
    local dt = (ticks - last_ticks) / 1000.0
    if dt > 0.05 then dt = 0.05 end
    last_ticks = ticks
    
    -- Input
    for sc = 4, 29 do if mc.input.key_pressed(sc) then M.write_string(string.char(string.byte('A') + (sc - 4))) end end
    if mc.input.key_pressed(44) then M.write_string(" ") end
    if mc.input.key_pressed(40) then M.write_string("\n") end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local img_idx = sw:acquire_next_image(M.image_available_sems[M.current_frame])
    if not img_idx then return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {M.frame_fences[M.current_frame]}))
    
    current_time = current_time + dt
    local cb = cbs[M.current_frame + 1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local pc = ffi.new("PushConstants", { 
        dt = dt, 
        time = current_time,
        p_buf = 0, t_buf = 1, sdf_tex = 0,
        term_w = TERM_W, term_h = TERM_H, particles_per_char = PARTICLES_PER_CHAR 
    })
    
    local pSetsArr = ffi.new("VkDescriptorSet[1]", {bindless_set})
    local sw_res = g_swImages[img_idx]

    graph:reset()
    graph:add_pass("Physics", function(c)
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, M.cache.pipelines["physics"])
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 32, pc)
        vk.vkCmdDispatch(c, math.ceil(PARTICLE_COUNT / 256), 1, 1)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT + vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(g_tBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("Render", function(c)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
        color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[img_idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
        color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0,0,0,1}

        vk.vkCmdBeginRendering(c, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach }))
        vk.vkCmdSetViewport(c, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
        vk.vkCmdSetScissor(c, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
        vk.vkCmdBindPipeline(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
        vk.vkCmdBindDescriptorSets(c, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, pSetsArr, 0, nil)
        vk.vkCmdPushConstants(c, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_COMPUTE_BIT, vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 32, pc)
        vk.vkCmdDraw(c, PARTICLE_COUNT, 1, 0, 0)
        vk.vkCmdEndRendering(c)
    end):using(g_pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT)
       :using(sw_res, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)

    graph:add_pass("Present", function(c) end):using(sw_res, 0, vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR)
    graph:execute(cb)
    vk.vkEndCommandBuffer(cb)

    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {M.image_available_sems[M.current_frame]}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {M.render_finished_sems[M.current_frame]}) 
    }), M.frame_fences[M.current_frame])
    
    sw:present(queue, img_idx, M.render_finished_sems[M.current_frame])
    M.current_frame = (M.current_frame + 1) % M.MAX_FRAMES_IN_FLIGHT
end

return M
