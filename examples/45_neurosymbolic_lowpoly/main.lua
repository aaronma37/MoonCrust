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

local csg = require("csg")
local generator = require("generator")
local animator = require("animator")

-- Local Scancode Fallbacks
local KEY_W = input.SCANCODE_W or 26
local KEY_A = input.SCANCODE_A or 4
local KEY_S = input.SCANCODE_S or 22
local KEY_D = input.SCANCODE_D or 7
local KEY_SPACE = input.SCANCODE_SPACE or 44

local M = { 
    orbit_radius = 35,
    orbit_yaw = 0,
    orbit_pitch = 0.2,
    target_pos = {0, 8, 0},
    time = 0,
    anim_state = "idle",
    last_frame_time = 0
}

local device, queue, sw, pipe_layout, graphics_pipe
local depth_img, floor_vbuf, floor_ibuf, floor_idx_count
local cbs, image_available_sem, frame_fence

local char_parts = {}

function M.init()
    print("Example 45: Neurosymbolic Hierarchical Character")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    local q, family = vulkan.get_queue()
    queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")

    -- 1. Character Parts
    local parts_def = generator.generate_character()
    for name, def in pairs(parts_def) do
        local v_data, v_size, i_data, i_size, ic = csg.build_buffer(def.mesh)
        char_parts[name] = {
            vbuf = mc.gpu.buffer(v_size, "vertex", v_data, true),
            ibuf = mc.gpu.buffer(i_size, "index", i_data, true),
            idx_count = ic,
            offset = def.offset,
            pivot = def.pivot,
            parent = def.parent
        }
    end

    -- 2. Ground Plane
    local floor_mesh = csg.make_cube(100, 0.1, 100, 0.2, 0.25, 0.2)
    -- Add a RED marker in front of the wizard (-Z direction)
    local marker = csg.translate(csg.make_cube(2, 0.2, 2, 1.0, 0.0, 0.0), 0, 0.1, -10)
    floor_mesh = csg.union(floor_mesh, marker)
    
    local fv, fvs, fi, fis, fic = csg.build_buffer(floor_mesh)
    floor_vbuf = mc.gpu.buffer(fvs, "vertex", fv, true)
    floor_ibuf = mc.gpu.buffer(fis, "index", fi, true)
    floor_idx_count = fic

    -- 3. Pipeline
    ffi.cdef[[ typedef struct PCLowPoly { float mvp[16]; float model[16]; } PCLowPoly; ]]
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 128 }})
    pipe_layout = pipeline.create_layout(device, {}, pc_range)

    local function get_dir() return "examples/45_neurosymbolic_lowpoly/" end
    local v_src = io.open(get_dir().."render.vert"):read("*all")
    local f_src = io.open(get_dir().."render.frag"):read("*all")
    local v_mod = shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 36, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[3]", {
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 12 },
            { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 24 }
        }),
        vertex_attribute_count = 3,
        depth_test = true, depth_write = true, depth_format = depth_format,
        cull_mode = vk.VK_CULL_MODE_NONE
    })

    local pool = command.create_pool(device, family)
    cbs = command.allocate_buffers(device, pool, sw.image_count)
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available_sem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sem); image_available_sem = image_available_sem[0]
    
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
end

function M.update()
    local current_ticks = tonumber(sdl.SDL_GetTicks())
    local dt_ms = current_ticks - M.last_frame_time
    if dt_ms < 16.66 then 
        sdl.SDL_Delay(math.floor(16.66 - dt_ms))
        current_ticks = tonumber(sdl.SDL_GetTicks())
        dt_ms = current_ticks - M.last_frame_time
    end
    M.last_frame_time = current_ticks
    local dt = dt_ms / 1000.0

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    
    local idx = sw:acquire_next_image(image_available_sem)
    if idx == nil then return end
    
    M.time = M.time + dt
    
    -- State Machine (Character only)
    if input.key_down(KEY_SPACE) then
        M.anim_state = "cast"
    elseif input.key_down(KEY_W) or input.key_down(KEY_S) or input.key_down(KEY_A) or input.key_down(KEY_D) then
        M.anim_state = "walk"
    else
        M.anim_state = "idle"
    end

    -- Orbit Controls
    if _G._MOUSE_L then
        local dx, dy = input.mouse_delta()
        M.orbit_yaw = M.orbit_yaw - dx * 0.01
        M.orbit_pitch = M.orbit_pitch + dy * 0.01
        M.orbit_pitch = math.max(-math.pi/2 + 0.1, math.min(math.pi/2 - 0.1, M.orbit_pitch))
    end
    
    -- Zoom
    local wheel = _G._MOUSE_WHEEL or 0
    M.orbit_radius = math.max(5, M.orbit_radius - wheel * 2.0)
    _G._MOUSE_WHEEL = 0 -- Reset wheel

    local cam_x = M.target_pos[1] + math.sin(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local cam_y = M.target_pos[2] + math.sin(M.orbit_pitch) * M.orbit_radius
    local cam_z = M.target_pos[3] + math.cos(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    
    local view = mc.mat4_look_at({cam_x, cam_y, cam_z}, M.target_pos, {0, 1, 0})
    local proj = mc.mat4_perspective(mc.rad(60), sw.extent.width/sw.extent.height, 0.1, 1000.0)
    local vp = mc.mat4_multiply(proj, view)

    local pose = animator.get_pose(M.time, M.anim_state)

    local cb = cbs[idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local barriers = ffi.new("VkImageMemoryBarrier[2]")
    barriers[0].sType, barriers[0].oldLayout, barriers[0].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    barriers[0].image, barriers[0].subresourceRange = ffi.cast("VkImage", sw.images[idx]), { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    barriers[0].dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    barriers[1].sType, barriers[1].oldLayout, barriers[1].newLayout = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    barriers[1].image, barriers[1].subresourceRange = depth_img.handle, { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }
    barriers[1].dstAccessMask = bit.bor(vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 2, barriers)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.1, 0.1, 0.15, 1.0}
    local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, depth_img.view, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil.depth = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
    
    -- STANDARD VIEWPORT
    local viewport = ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 })
    vk.vkCmdSetViewport(cb, 0, 1, viewport)
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)

    local pc = ffi.new("PCLowPoly")
    local floor_model = mc.mat4_identity()
    local floor_mvp = mc.mat4_multiply(vp, floor_model)
    for i=0,15 do pc.mvp[i] = floor_mvp.m[i]; pc.model[i] = floor_model.m[i] end
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 128, pc)
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {floor_vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, floor_ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    vk.vkCmdDrawIndexed(cb, floor_idx_count, 1, 0, 0, 0)

    local function draw_part(name, parent_global)
        local part = char_parts[name]
        local p = pose[name]

        -- CORRECT ORDER:
        -- 1. Offset from parent center to joint location
        -- 2. Animation Rotation (at joint)
        -- 3. Offset from joint to mesh center (-pivot)
        local local_m = mc.mat4_translate(part.offset[1] + p.pos[1], part.offset[2] + p.pos[2], part.offset[3] + p.pos[3])
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_x(p.rot[1]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_y(p.rot[2]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_z(p.rot[3]))
        local_m = mc.mat4_multiply(local_m, mc.mat4_translate(-part.pivot[1], -part.pivot[2], -part.pivot[3]))

        local global_m = mc.mat4_multiply(parent_global, local_m)
        local mvp = mc.mat4_multiply(vp, global_m)

        for i=0,15 do pc.mvp[i] = mvp.m[i]; pc.model[i] = global_m.m[i] end
        vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 128, pc)
        vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {part.vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
        vk.vkCmdBindIndexBuffer(cb, part.ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
        vk.vkCmdDrawIndexed(cb, part.idx_count, 1, 0, 0, 0)

        for child_name, child_part in pairs(char_parts) do
            if child_part.parent == name then
                -- Pass the Global matrix BEFORE the mesh pivot was applied for children attachment
                local joint_global = mc.mat4_multiply(parent_global, mc.mat4_translate(part.offset[1] + p.pos[1], part.offset[2] + p.pos[2], part.offset[3] + p.pos[3]))
                joint_global = mc.mat4_multiply(joint_global, mc.mat4_rotate_x(p.rot[1]))
                joint_global = mc.mat4_multiply(joint_global, mc.mat4_rotate_y(p.rot[2]))
                joint_global = mc.mat4_multiply(joint_global, mc.mat4_rotate_z(p.rot[3]))

                draw_part(child_name, joint_global)
            end
        end
    end
    draw_part("torso", mc.mat4_identity())
    
    vk.vkCmdEndRendering(cb)
    local present_bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={ aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1 }, srcAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, present_bar)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
