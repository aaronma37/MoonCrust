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

local skeleton = require("examples.53_sleeve_generation.skeleton")
local mesher = require("examples.53_sleeve_generation.mesher")
local dae = require("examples.53_sleeve_generation.dae_loader")

local M = { 
    orbit_radius = 25,
    orbit_yaw = 0,
    orbit_pitch = 0.3,
    target_pos = {0, 8, 0},
    time = 0,
    anim_state = "rest",
    last_frame_time = 0
}

local device, queue, sw, pipe_layout, graphics_pipe
local compute_pipe, compute_layout
local depth_img, vbuf, ibuf, idx_count
local bone_buf, param_buf, matrix_buf, ds_pool
local cbs, image_available_sem, frame_fence

local bones, segments
local RINGS_PER_BONE = 8
local VERTS_PER_RING = 16

local animations = {}

function M.init()
    print("Example 53: Neurosymbolic Mesh Rings (Mixamo Skeleton)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    local q, family = vulkan.get_queue()
    queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")

    bones = skeleton.get_bone_list()
    segments = mesher.calculate_bone_segments(bones)
    local num_bones = #segments
    idx_count = #mesher.generate_indices(#segments, RINGS_PER_BONE, VERTS_PER_RING)

    animations.walking = dae.load_animations("examples/53_sleeve_generation/Walking.dae")

    local v_size = #segments * RINGS_PER_BONE * VERTS_PER_RING * ffi.sizeof("MeshVertex")
    local i_size = idx_count * 4
    vbuf = mc.gpu.buffer(v_size, "vertex_storage", nil, true)
    
    local indices = mesher.generate_indices(#segments, RINGS_PER_BONE, VERTS_PER_RING)
    ibuf = mc.gpu.buffer(i_size, "index", ffi.new("uint32_t[?]", #indices, indices), true)

    local bone_data = ffi.new("MeshBone[?]", #segments)
    for i, s in ipairs(segments) do
        for j=1,4 do 
            bone_data[i-1].start_pos[j-1] = s.start_pos[j]
            bone_data[i-1].end_pos[j-1] = s.end_pos[j]
            bone_data[i-1].plane_start[j-1] = s.plane_start[j]
            bone_data[i-1].plane_end[j-1] = s.plane_end[j]
        end
    end
    bone_buf = mc.gpu.buffer(#segments * ffi.sizeof("MeshBone"), "storage", bone_data, true)

    local param_data = mesher.create_params(#segments, RINGS_PER_BONE, segments)
    param_buf = mc.gpu.buffer(#segments * RINGS_PER_BONE * ffi.sizeof("MeshRingParams"), "storage", param_data, true)

    matrix_buf = mc.gpu.buffer(128 * 64, "storage", nil, true)

    local inv_bind_mats = {}
    for _, b in ipairs(bones) do
        local cm_mat = mc.mat4_identity()
        for row=0,3 do
            for col=0,3 do
                cm_mat.m[col*4 + row] = b.global_mat[row*4 + col + 1]
            end
        end
        cm_mat.m[12], cm_mat.m[13], cm_mat.m[14] = cm_mat.m[12]*0.1, cm_mat.m[13]*0.1, cm_mat.m[14]*0.1
        inv_bind_mats[b.id] = mc.mat4_inverse(cm_mat)
    end
    M.inv_bind_mats = inv_bind_mats

    local get_dir = function() return "examples/53_sleeve_generation/" end
    ds_pool = descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }})

    local c_bindings = {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }
    }
    local c_ds_layout = descriptors.create_layout(device, c_bindings)
    compute_layout = pipeline.create_layout(device, {c_ds_layout}, { { stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 12 } })
    
    local c_src = io.open(get_dir().."mesher.comp"):read("*all")
    local c_mod = shader.create_module(device, shader.compile_glsl(c_src, vk.VK_SHADER_STAGE_COMPUTE_BIT))
    compute_pipe = pipeline.create_compute_pipeline(device, compute_layout, c_mod)

    local g_bindings = {{ binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_VERTEX_BIT }}
    local g_ds_layout = descriptors.create_layout(device, g_bindings)
    pipe_layout = pipeline.create_layout(device, {g_ds_layout}, { { stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = 128 } })

    ffi.cdef[[ typedef struct PC { float mvp[16]; float model[16]; } PC; ]]
    local v_src = io.open(get_dir().."render.vert"):read("*all")
    local f_src = io.open(get_dir().."render.frag"):read("*all")
    local v_mod = shader.create_module(device, shader.compile_glsl(v_src, vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(f_src, vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    
    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = ffi.sizeof("MeshVertex"), inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[5]", {
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 16 },
            { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 32 },
            { location = 3, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 48 },
            { location = 4, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_UINT, offset = 64 }
        }),
        vertex_attribute_count = 5, depth_test = true, depth_write = true, depth_format = depth_format, cull_mode = vk.VK_CULL_MODE_NONE
    })

    M.c_ds = descriptors.allocate_sets(device, ds_pool, {c_ds_layout})[1]
    M.g_ds = descriptors.allocate_sets(device, ds_pool, {g_ds_layout})[1]
    
    descriptors.update_buffer_set(device, M.c_ds, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, vbuf.handle, 0, v_size)
    descriptors.update_buffer_set(device, M.c_ds, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, bone_buf.handle, 0, #segments * ffi.sizeof("MeshBone"))
    descriptors.update_buffer_set(device, M.c_ds, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, param_buf.handle, 0, #segments * RINGS_PER_BONE * ffi.sizeof("MeshRingParams"))
    descriptors.update_buffer_set(device, M.g_ds, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, matrix_buf.handle, 0, 128 * 64)

    local cmd_pool = command.create_pool(device, family)
    cbs = command.allocate_buffers(device, cmd_pool, sw.image_count)
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available_sem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sem); image_available_sem = image_available_sem[0]
    
    M.last_frame_time = tonumber(sdl.SDL_GetTicks())
end

local function lerp_mat(a, b, t)
    local out = {}
    for i=1,16 do out[i] = a[i] + (b[i] - a[i]) * t end
    return out
end

local function get_animated_matrix(bone_name, anim, time)
    if not anim or not anim.channels[bone_name] then return nil end
    local chan = anim.channels[bone_name]
    local duration = anim.duration
    local t = time % duration
    local idx1, idx2 = 1, 1
    for i=1, #chan.times do
        if chan.times[i] > t then
            idx2 = i
            idx1 = math.max(1, i-1)
            break
        end
    end
    local t1, t2 = chan.times[idx1], chan.times[idx2]
    local factor = 0
    if t2 > t1 then factor = (t - t1) / (t2 - t1) end
    return lerp_mat(chan.matrices[idx1], chan.matrices[idx2], factor)
end

function M.update()
    local current_ticks = tonumber(sdl.SDL_GetTicks())
    local dt = (current_ticks - M.last_frame_time) / 1000.0
    M.last_frame_time = current_ticks
    M.time = M.time + dt
    
    M.fps_timer = (M.fps_timer or 0) + dt
    M.frame_count = (M.frame_count or 0) + 1
    if M.fps_timer > 0.5 then
        sdl.SDL_SetWindowTitle(_G._SDL_WINDOW, string.format("MoonCrust | FPS: %.1f", M.frame_count / M.fps_timer))
        M.fps_timer, M.frame_count = 0, 0
    end

    if input.key_pressed(input.SCANCODE_1) then M.anim_state = "rest" end
    if input.key_pressed(input.SCANCODE_2) then M.anim_state = "walking" end

    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    
    local idx = sw:acquire_next_image(image_available_sem)
    if idx == nil then return end

    if _G._MOUSE_L then
        local dx, dy = input.mouse_delta()
        M.orbit_yaw = M.orbit_yaw - dx * 0.01
        M.orbit_pitch = math.max(-math.pi/2+0.1, math.min(math.pi/2-0.1, M.orbit_pitch + dy * 0.01))
    end
    
    local cam_x = M.target_pos[1] + math.sin(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local cam_y = M.target_pos[2] + math.sin(M.orbit_pitch) * M.orbit_radius
    local cam_z = M.target_pos[3] + math.cos(M.orbit_yaw) * math.cos(M.orbit_pitch) * M.orbit_radius
    local view = mc.mat4_look_at({cam_x, cam_y, cam_z}, M.target_pos, {0, 1, 0})
    local proj = mc.mat4_perspective(mc.rad(60), sw.extent.width/sw.extent.height, 0.1, 1000.0)
    local vp = mc.mat4_multiply(proj, view)

    local mats = ffi.new("float[128*16]")
    local function calc_mats(bone, parent_global)
        local local_mat_vals = nil
        if M.anim_state == "walking" and animations.walking then
            local_mat_vals = get_animated_matrix(bone.name, animations.walking, M.time)
        end
        local local_m = mc.mat4_identity()
        local vals = local_mat_vals or bone.local_matrix
        if vals then for row=0,3 do for col=0,3 do local_m.m[col*4 + row] = vals[row*4 + col + 1] end end end
        local_m.m[12], local_m.m[13], local_m.m[14] = local_m.m[12]*0.1, local_m.m[13]*0.1, local_m.m[14]*0.1
        local global_m = mc.mat4_multiply(parent_global, local_m)
        local skin_m = mc.mat4_multiply(global_m, M.inv_bind_mats[bone.id])
        for j=0,15 do local i = (bone.id-1)*16 + j; if i < 128*16 then mats[i] = skin_m.m[j] end end
        for _, b in ipairs(bones) do if b.parent_id == bone.id then calc_mats(b, global_m) end end
    end
    local root = nil
    for _, b in ipairs(bones) do if b.parent_id == 0 then root = b; break end end
    if root then calc_mats(root, mc.mat4_identity()) end
    matrix_buf:upload(mats)

    local cb = cbs[idx+1]
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, compute_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {M.c_ds}), 0, nil)
    vk.vkCmdPushConstants(cb, compute_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 12, ffi.new("uint32_t[3]", { #segments, RINGS_PER_BONE, VERTS_PER_RING }))
    vk.vkCmdDispatch(cb, 1, 1, #segments)

    local v_barrier = ffi.new("VkBufferMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT, buffer = vbuf.handle, offset = 0, size = vbuf.size }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, 0, 0, nil, 1, v_barrier, 0, nil)

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
    color_attach[0].loadOp, color_attach[0].storeOp, color_attach[0].clearValue.color.float32 = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0.05, 0.05, 0.05, 1.0}
    local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    depth_attach[0].sType, depth_attach[0].imageView, depth_attach[0].imageLayout = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, depth_img.view, vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach[0].loadOp, depth_attach[0].storeOp, depth_attach[0].clearValue.depthStencil.depth = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, 1.0
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach, pDepthAttachment=depth_attach }))
    
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x=0, y=0, width=sw.extent.width, height=sw.extent.height, minDepth=0, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {M.g_ds}), 0, nil)

    local pc = ffi.new("PC")
    local model = mc.mat4_identity()
    local mvp = mc.mat4_multiply(vp, model)
    for i=0,15 do pc.mvp[i] = mvp.m[i]; pc.model[i] = model.m[i] end
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 128, pc)
    
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    vk.vkCmdDrawIndexed(cb, idx_count, 1, 0, 0, 0)

    vk.vkCmdEndRendering(cb)
    local present_bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={ aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1 }, srcAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, present_bar)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount = 1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
