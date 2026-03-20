local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local command = require("vulkan.command")
local input = require("mc.input")
local bit = require("bit")
local sdl = require("vulkan.sdl")
local descriptors = require("vulkan.descriptors")

local scene = require("examples.53_sleeve_generation.scene")
local Character = require("examples.53_sleeve_generation.entities.procedural_character")
local SDFHead = require("examples.53_sleeve_generation.entities.sdf_head")

local M = { 
    orbit_radius = 25,
    orbit_yaw = 0,
    orbit_pitch = 0.3,
    target_pos = {0, 8, 0},
    time = 0,
    state = {
        anim_state = "rest",
        wireframe = false,
        diagnostic = false
    },
    last_frame_time = 0
}

local device, queue, sw, graphics_pipe, outline_pipe, wire_pipe, pipe_layout
local debug_pipe, debug_layout
local depth_img, ds_pool
local cbs, image_available_sem, frame_fence

function M.init()
    print("Example 53: Neurosymbolic Mesh Rings (Dynamic Meshing) - Multi-Asset Ready")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    local q, family = vulkan.get_queue()
    queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")

    local get_dir = function() return "examples/53_sleeve_generation/" end
    ds_pool = descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }})

    local g_bindings = {
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT }
    }
    local g_ds_layout = descriptors.create_layout(device, g_bindings)
    pipe_layout = pipeline.create_layout(device, {g_ds_layout}, { { stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 160 } })

    -- DEBUG PIPELINE
    debug_layout = pipeline.create_layout(device, {}, { { stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT, offset = 0, size = 64 } })
    local dv_src = io.open(get_dir().."debug.vert"):read("*all")
    local df_src = io.open(get_dir().."debug.frag"):read("*all")
    debug_pipe = pipeline.create_graphics_pipeline(device, debug_layout, shader.create_module(device, shader.compile_glsl(dv_src, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(df_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 24, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[2]", { 
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 12 }
        }),
        vertex_attribute_count = 2, depth_test = false, topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_LIST, depth_format = depth_format
    })

    ffi.cdef[[ typedef struct Example53PC { float projection_view[16]; float model[16]; float mouse_pos[2]; float outline_width; float wireframe_mode; float pad; } Example53PC; ]]
    local v_src = io.open(get_dir().."render.vert"):read("*all")
    local f_src = io.open(get_dir().."render.frag"):read("*all")
    
    local vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = ffi.sizeof("MeshVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }})
    local vertex_attributes = ffi.new("VkVertexInputAttributeDescription[5]", {
        { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
        { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 16 },
        { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 32 },
        { location = 3, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 48 },
        { location = 4, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_UINT, offset = 64 }
    })

    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        vertex_binding = vertex_binding, vertex_attributes = vertex_attributes, vertex_attribute_count = 5, 
        depth_test = true, depth_write = true, depth_format = depth_format, cull_mode = vk.VK_CULL_MODE_NONE
    })

    outline_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        vertex_binding = vertex_binding, vertex_attributes = vertex_attributes, vertex_attribute_count = 5, 
        depth_test = true, depth_write = false, depth_format = depth_format, cull_mode = vk.VK_CULL_MODE_FRONT_BIT
    })

    wire_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        vertex_binding = vertex_binding, vertex_attributes = vertex_attributes, vertex_attribute_count = 5, 
        depth_test = true, depth_write = true, depth_format = depth_format, cull_mode = vk.VK_CULL_MODE_NONE,
        polygon_mode = vk.VK_POLYGON_MODE_LINE
    })

    -- Add Character Entity
    M.character = Character.new(device, ds_pool, g_ds_layout)
    scene.add_entity(M.character)

    -- Add SDF Head Entity
    M.sdf_head = SDFHead.new(device, ds_pool, M.character)
    scene.add_entity(M.sdf_head)

    cbs = command.allocate_buffers(device, command.create_pool(device, family), sw.image_count)
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available_sem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sem); image_available_sem = image_available_sem[0]
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
end

function M.update()
    local dt = (tonumber(sdl.SDL_GetTicks()) - M.last_frame_time) / 1000.0
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
    M.time = M.time + dt
    
    if input.key_pressed(input.SCANCODE_1) then M.state.anim_state = "rest" end
    if input.key_pressed(input.SCANCODE_2) then M.state.anim_state = "walking" end
    if input.key_pressed(input.SCANCODE_4) then M.state.anim_state = "slash" end
    if input.key_pressed(input.SCANCODE_3) then M.state.diagnostic = not M.state.diagnostic end
    if input.key_pressed(input.SCANCODE_5) or input.key_pressed(input.SCANCODE_Z) then 
        M.state.wireframe = not M.state.wireframe 
        print("WIRE_TOGGLE: " .. tostring(M.state.wireframe))
    end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available_sem)
    if idx == nil then return end

    if _G._MOUSE_L then
        local dx, dy = input.mouse_delta()
        M.orbit_yaw, M.orbit_pitch = M.orbit_yaw - dx * 0.01, math.max(-math.pi/2+0.1, math.min(math.pi/2-0.1, M.orbit_pitch + dy * 0.01))
    end
    if _G._MOUSE_M then
        local dx, dy = input.mouse_delta()
        local side_x, side_z = math.cos(M.orbit_yaw), -math.sin(M.orbit_yaw)
        local pan_speed = 0.05
        M.target_pos[1] = M.target_pos[1] - side_x * dx * pan_speed
        M.target_pos[3] = M.target_pos[3] - side_z * dx * pan_speed
        M.target_pos[2] = M.target_pos[2] + dy * pan_speed
    end
    local cam_x = M.target_pos[1] + math.sin(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local cam_y = M.target_pos[2] + math.sin(M.orbit_pitch) * M.orbit_radius
    local cam_z = M.target_pos[3] + math.cos(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local view = mc.mat4_look_at({cam_x, cam_y, cam_z}, M.target_pos, {0, 1, 0})
    local proj = mc.mat4_perspective(mc.rad(60), sw.extent.width/sw.extent.height, 0.1, 1000.0)
    local vp = mc.mat4_multiply(proj, view)

    if input.key_pressed(input.SCANCODE_H) then
        local head_mat = M.character:get_head_matrix()
        if head_mat then
            M.target_pos = {head_mat.m[12], head_mat.m[13], head_mat.m[14]}
            M.orbit_radius = 5.0
        end
    end

    -- 1. CPU UPDATE
    scene.update(dt, M.time, M.state)

    local cb = cbs[idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- 2. GPU COMPUTE
    scene.record_compute(cb, M.state)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05, 0.05, 0.05, 1.0}
    local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, depth_img.view, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil.depth = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
    
    local barriers = ffi.new("VkImageMemoryBarrier[2]")
    barriers[0].sType, barriers[0].oldLayout, barriers[0].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    barriers[0].image, barriers[0].subresourceRange = ffi.cast("VkImage", sw.images[idx]), { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    barriers[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    barriers[1].sType, barriers[1].oldLayout, barriers[1].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    barriers[1].image, barriers[1].subresourceRange = depth_img.handle, { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }
    barriers[1].dstAccessMask = bit.bor(vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 2, barriers)

    -- 3. GPU GRAPHICS
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))

    local pc = ffi.new("Example53PC")
    local model = mc.mat4_identity()
    for i=0,15 do pc.projection_view[i], pc.model[i] = vp.m[i], model.m[i] end
    local mx, my = input.mouse_pos(); pc.mouse_pos[0], pc.mouse_pos[1] = mx, my

    local active_pipe = M.state.wireframe and wire_pipe or graphics_pipe

    if not M.state.wireframe then
        pc.outline_width = 0.015
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, outline_pipe)
        vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("Example53PC"), pc)
        scene.record_draw(cb, pipe_layout, M.state.wireframe)
    end

    pc.outline_width = 0.0
    pc.wireframe_mode = M.state.wireframe and 1.0 or 0.0
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, active_pipe)
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("Example53PC"), pc)
    scene.record_draw(cb, pipe_layout, M.state.wireframe)

    if M.state.diagnostic then
        vk.vkCmdPushConstants(cb, debug_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 64, pc.projection_view)
        scene.record_debug_draw(cb, debug_pipe, debug_layout)
    end
    vk.vkCmdEndRendering(cb)

    scene.check_picking()

    -- Debug SDF Head Counts
    if M.sdf_head then
        local ptr = ffi.cast("uint32_t*", M.sdf_head.counter_buf.allocation.ptr)
        if M.time % 1.0 < 0.02 then
            print(string.format("SDF Head Stats | Indices: %d | Vertices: %d", ptr[0], ptr[6]))
        end
    end

    local present_bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={ aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1 }, srcAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, present_bar)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
