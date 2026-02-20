local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local command = require("vulkan.command")
local loader = require("examples.27_obj_viewer.loader")
local input = require("mc.input")
local sdl = require("vulkan.sdl")
local bit = require("bit")

local M = { 
    cam_pos = {0, 200, -500},
    cam_yaw = 0,
    cam_pitch = 0
}

local device, queue, sw, pipe_layout, graphics_pipe, pipe_voxelize
local vertex_buffer, vertex_count, grid_buffer, depth_img
local cb, image_available_sem, frame_fence, bindless_set

local function clamp(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end

function M.init()
    print("Example 27: STABLE SPONZA (FFI Hardened)")
    
    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    local q, family = vulkan.get_queue()
    queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    -- 1. Depth Buffer
    local depth_format = image.find_depth_format(physical_device)
    depth_img = mc.gpu.image(sw.extent.width, sw.extent.height, depth_format, "depth")

    -- 2. Load Model
    local obj_path = "examples/27_obj_viewer/Sponza/sponza.obj" 
    local data, count = loader.load(obj_path)
    vertex_count = count
    vertex_buffer = mc.buffer(ffi.sizeof(data), "vertex", data)

    -- 3. Voxel Grid (32x32x32)
    grid_buffer = mc.buffer(32 * 32 * 32 * 4, "storage", nil, false)

    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, vertex_buffer.handle, 0, vertex_buffer.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, grid_buffer.handle, 0, grid_buffer.size, 1)

    -- 4. Pipelines
    ffi.cdef[[
        typedef struct DrawPC { float mvp[16]; } DrawPC;
        typedef struct VoxPC { uint32_t v_buf, v_count, g_buf, res; } VoxPC;
    ]]

    local pc_range = ffi.new("VkPushConstantRange[1]", {{ 
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 
        offset = 0, size = 64 
    }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)

    pipe_voxelize = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/27_obj_viewer/voxelize.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local v_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/27_obj_viewer/obj.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/27_obj_viewer/obj.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))

    graphics_pipe = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { 
        vertex_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 36, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}),
        vertex_attributes = ffi.new("VkVertexInputAttributeDescription[3]", {
            { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
            { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 12 },
            { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 24 }
        }),
        depth_test = true, depth_write = true, depth_format = depth_format
    })

    -- 5. Sync
    local pool = command.create_pool(device, family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available_sem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available_sem); image_available_sem = image_available_sem[0]

    -- 6. Voxelize
    local vcb = command.allocate_buffers(device, pool, 1)[1]
    vk.vkBeginCommandBuffer(vcb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    vk.vkCmdBindPipeline(vcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_voxelize)
    vk.vkCmdBindDescriptorSets(vcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(vcb, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, ffi.new("VoxPC", { 0, vertex_count / 3, 1, 32 }))
    vk.vkCmdDispatch(vcb, math.ceil((vertex_count / 3) / 256), 1, 1)
    vk.vkEndCommandBuffer(vcb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {vcb}) }), nil)
    vk.vkQueueWaitIdle(queue)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    
    local idx = sw:acquire_next_image(image_available_sem)
    if idx == nil then return end
    
    input.tick(); local speed = 10.0; local rot_speed = 0.03; local keys = sdl.SDL_GetKeyboardState(nil)
    if keys[80] ~= 0 then M.cam_yaw = M.cam_yaw + rot_speed end
    if keys[79] ~= 0 then M.cam_yaw = M.cam_yaw - rot_speed end
    if keys[82] ~= 0 then M.cam_pitch = clamp(M.cam_pitch + rot_speed, -1.5, 1.5) end
    if keys[81] ~= 0 then M.cam_pitch = clamp(M.cam_pitch - rot_speed, -1.5, 1.5) end
    local forward = { math.sin(M.cam_yaw) * math.cos(M.cam_pitch), math.sin(M.cam_pitch), math.cos(M.cam_yaw) * math.cos(M.cam_pitch) }
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1] = M.cam_pos[1] + forward[1] * speed; M.cam_pos[2] = M.cam_pos[2] + forward[2] * speed; M.cam_pos[3] = M.cam_pos[3] + forward[3] * speed end
    if input.key_down(input.SCANCODE_S) then M.cam_pos[1] = M.cam_pos[1] - forward[1] * speed; M.cam_pos[2] = M.cam_pos[2] - forward[2] * speed; M.cam_pos[3] = M.cam_pos[3] - forward[3] * speed end
    
    local view = mc.mat4_look_at(M.cam_pos, {M.cam_pos[1]+forward[1], M.cam_pos[2]+forward[2], M.cam_pos[3]+forward[3]}, {0, 1, 0})
    local proj = mc.mat4_perspective(mc.rad(75), sw.extent.width/sw.extent.height, 1.0, 5000.0)
    proj.m[5] = -proj.m[5] -- VULKAN Y-FLIP FIX
    local mvp = mc.mat4_multiply(proj, view)

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ 
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, 
        oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, 
        newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 
        image = ffi.cast("VkImage", sw.images[idx]), 
        subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, 
        dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT 
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    color_attach[0].imageView = ffi.cast("VkImageView", sw.views[idx])
    color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color.float32[0] = 0.05
    color_attach[0].clearValue.color.float32[1] = 0.05
    color_attach[0].clearValue.color.float32[2] = 0.08
    color_attach[0].clearValue.color.float32[3] = 1.0
    
    local depth_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    depth_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    depth_attach[0].imageView = depth_img.view
    depth_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    depth_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    depth_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    depth_attach[0].clearValue.depthStencil.depth = 1.0

    local render_info = ffi.new("VkRenderingInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, 
        renderArea = { extent = sw.extent }, 
        layerCount = 1, 
        colorAttachmentCount = 1, 
        pColorAttachments = color_attach, 
        pDepthAttachment = depth_attach 
    })

    vk.vkCmdBeginRendering(cb, render_info)
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    
    local offsets = ffi.new("VkDeviceSize[1]", {0})
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {vertex_buffer.handle}), offsets)
    vk.vkCmdPushConstants(cb, pipe_layout, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, 64, mvp.m)
    vk.vkCmdDraw(cb, vertex_count, 1, 0, 0)
    
    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    bar[0].dstAccessMask = 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)
    
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { 
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, 
        waitSemaphoreCount = 1, 
        pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available_sem}), 
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), 
        commandBufferCount = 1, 
        pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), 
        signalSemaphoreCount = 1, 
        pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) 
    }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
