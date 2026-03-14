local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local command = require("vulkan.command")
local input = require("mc.input")
local math_util = require("mc.math")
local imgui = require("imgui")
local sdl = require("vulkan.sdl")

local M = { 
    cam_pos = {0, 5, -10},
    cam_yaw = 0,
    cam_pitch = 0,
    current_time = 0,
    fps = 0,
    frame_times = {},
    enable_shadows = true,
    last_perf_counter = 0
}

local device, queue, sw, pipe_layout, pipe_render, pipe_blit
local bindless_set, cb, frame_fence, image_available
local tf_buf, mat_buf, grid_buf, idx_buf, sphere_buf, out_img
local num_blocks = 10000 
local grid_res = 32
local world_min, world_max = -20, 20
local cell_size = (world_max - world_min) / grid_res

ffi.cdef[[
    typedef struct Transform {
        float inv_m[16]; 
    } Transform;

    typedef struct Material {
        float r, g, b, a;
        float roughness, metallic, emissive;
        uint32_t type;
    } Material;

    typedef struct Sphere {
        float x, y, z, r;
    } Sphere;

    typedef struct RenderPC {
        float cam_px, cam_py, cam_pz, cam_pw;
        float cam_dx, cam_dy, cam_dz, cam_dw;
        float cam_ux, cam_uy, cam_uz, cam_uw;
        float cam_rx, cam_ry, cam_rz, cam_rw;
        float res_x, res_y;
        float time;
        uint32_t num_transforms;
        uint32_t tf_id, mat_id, img_id, grid_id, idx_id;
        uint32_t use_shadows, sphere_id;
    } RenderPC;
]]

function M.init()
    print("Example 50: Super-Optimized DDA Renderer")
    
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); local q, family = vulkan.get_queue(); queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    imgui.init()
    M.last_perf_counter = tonumber(sdl.SDL_GetPerformanceCounter())

    -- 1. Create Buffers
    tf_buf = mc.buffer(num_blocks * ffi.sizeof("Transform"), "storage", nil, true)
    mat_buf = mc.buffer(num_blocks * ffi.sizeof("Material"), "storage", nil, true)
    sphere_buf = mc.buffer(num_blocks * ffi.sizeof("Sphere"), "storage", nil, true)
    
    idx_buf = mc.buffer(num_blocks * 32, "storage", nil, true) 
    grid_buf = mc.buffer(grid_res * grid_res * grid_res * 8, "storage", nil, true) 

    out_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")

    -- Initial layout transition
    do
        local pool = command.create_pool(device, family)
        local t_cb = command.allocate_buffers(device, pool, 1)[1]
        vk.vkBeginCommandBuffer(t_cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT }))
        local bar = ffi.new("VkImageMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
            newLayout = vk.VK_IMAGE_LAYOUT_GENERAL,
            image = out_img.handle,
            subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 },
            srcAccessMask = 0,
            dstAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT
        }})
        vk.vkCmdPipelineBarrier(t_cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, bar)
        vk.vkEndCommandBuffer(t_cb)
        vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {t_cb}) }), nil)
        vk.vkQueueWaitIdle(queue)
        vk.vkDestroyCommandPool(device, pool, nil)
    end

    -- 2. Populate Initial Data
    local tf_ptr = ffi.cast("Transform*", tf_buf.allocation.ptr)
    local mat_ptr = ffi.cast("Material*", mat_buf.allocation.ptr)
    local sphere_ptr = ffi.cast("Sphere*", sphere_buf.allocation.ptr)
    
    math.randomseed(42)
    local cell_counts = {}
    for i=0, grid_res^3-1 do cell_counts[i] = 0 end

    local blocks = {}

    for i=0, num_blocks-1 do
        local px, py, pz = (math.random()-0.5)*38, (math.random()-0.5)*38, (math.random()-0.5)*38
        local sx, sy, sz = 0.5 + math.random()*0.5, 0.5 + math.random()*0.5, 0.5 + math.random()*0.5
        local ry = math.random() * math.pi * 2
        
        local m = math_util.mat4_translate(px, py, pz)
        m = math_util.mat4_multiply(m, math_util.mat4_rotate_y(ry))
        local m_scale = math_util.mat4_identity(); m_scale.m[0], m_scale.m[5], m_scale.m[10] = sx, sy, sz
        m = math_util.mat4_multiply(m, m_scale)
        
        local inv_m = math_util.mat4_inverse(m)
        for j=0,15 do tf_ptr[i].inv_m[j] = inv_m.m[j] end
        
        local r = math.sqrt(sx*sx + sy*sy + sz*sz) * 0.5
        sphere_ptr[i].x, sphere_ptr[i].y, sphere_ptr[i].z, sphere_ptr[i].r = px, py, pz, r
        
        mat_ptr[i].r, mat_ptr[i].g, mat_ptr[i].b, mat_ptr[i].a = math.random(), math.random(), math.random(), 1
        mat_ptr[i].roughness = math.random()
        mat_ptr[i].metallic = math.random()
        mat_ptr[i].emissive = (math.random() > 0.98) and 5.0 or 0.0
        mat_ptr[i].type = 1
        
        local min_gx = math.max(0, math.floor((px - r - world_min) / cell_size))
        local max_gx = math.min(grid_res-1, math.floor((px + r - world_min) / cell_size))
        local min_gy = math.max(0, math.floor((py - r - world_min) / cell_size))
        local max_gy = math.min(grid_res-1, math.floor((py + r - world_min) / cell_size))
        local min_gz = math.max(0, math.floor((pz - r - world_min) / cell_size))
        local max_gz = math.min(grid_res-1, math.floor((pz + r - world_min) / cell_size))

        blocks[i] = {min_gx, max_gx, min_gy, max_gy, min_gz, max_gz}

        for gx = min_gx, max_gx do
            for gy = min_gy, max_gy do
                for gz = min_gz, max_gz do
                    local gidx = gx + gy*grid_res + gz*grid_res*grid_res
                    cell_counts[gidx] = cell_counts[gidx] + 1
                end
            end
        end
    end

    local grid_ptr = ffi.cast("uint32_t*", grid_buf.allocation.ptr)
    local idx_ptr = ffi.cast("uint32_t*", idx_buf.allocation.ptr)
    local current_offset = 0
    local cell_offsets = {}
    for i=0, grid_res^3-1 do
        grid_ptr[i*2] = current_offset
        grid_ptr[i*2+1] = 0 
        cell_offsets[i] = current_offset
        current_offset = current_offset + cell_counts[i]
    end

    for i=0, num_blocks-1 do
        local b = blocks[i]
        for gx = b[1], b[2] do
            for gy = b[3], b[4] do
                for gz = b[5], b[6] do
                    local gidx = gx + gy*grid_res + gz*grid_res*grid_res
                    local pos = cell_offsets[gidx] + grid_ptr[gidx*2+1]
                    idx_ptr[pos] = i
                    grid_ptr[gidx*2+1] = grid_ptr[gidx*2+1] + 1
                end
            end
        end
    end

    -- 3. Bindless & Descriptors
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, tf_buf.handle, 0, tf_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, mat_buf.handle, 0, mat_buf.size, 1)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, out_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, grid_buf.handle, 0, grid_buf.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, idx_buf.handle, 0, idx_buf.size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sphere_buf.handle, 0, sphere_buf.size, 4)

    -- 4. Pipelines
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = 0x7FFFFFFF, offset = 0, size = ffi.sizeof("RenderPC") }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)

    local render_src = io.open("examples/50_custom_renderer/render.comp"):read("*all")
    pipe_render = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(render_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local v_mod = shader.create_module(device, shader.compile_glsl([[
        #version 450
        void main() {
            vec2 pos[3] = vec2[](vec2(-1,-1), vec2(3,-1), vec2(-1,3));
            gl_Position = vec4(pos[gl_VertexIndex], 0, 1);
        }
    ]], vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl([[
        #version 450
        #extension GL_EXT_nonuniform_qualifier : require
        layout(location = 0) out vec4 outColor;
        layout(set = 0, binding = 2, rgba32f) uniform readonly image2D tex[];
        layout(push_constant) uniform PC { 
            vec4 cam_pos;
            vec4 cam_dir;
            vec4 cam_up;
            vec4 cam_right;
            vec2 res;
            float time;
            uint num_transforms;
            uint tf_id, mat_id, img_id, grid_id, idx_id;
            uint use_shadows, sphere_id;
        } pc;
        void main() {
            outColor = imageLoad(tex[nonuniformEXT(pc.img_id)], ivec2(gl_FragCoord.xy));
        }
    ]], vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_blit = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST })

    -- 5. Sync
    local pool = command.create_pool(device, family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); image_available = image_available[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available)
    if idx == nil then return end
    
    input.tick(); M.current_time = M.current_time + 0.016
    
    local speed = 0.2
    if input.key_down(input.SCANCODE_W) then 
        M.cam_pos[1] = M.cam_pos[1] + math.sin(M.cam_yaw) * speed
        M.cam_pos[3] = M.cam_pos[3] + math.cos(M.cam_yaw) * speed
    end
    if input.key_down(input.SCANCODE_S) then 
        M.cam_pos[1] = M.cam_pos[1] - math.sin(M.cam_yaw) * speed
        M.cam_pos[3] = M.cam_pos[3] - math.cos(M.cam_yaw) * speed
    end
    if input.key_down(input.SCANCODE_A) then M.cam_yaw = M.cam_yaw + 0.03 end
    if input.key_down(input.SCANCODE_D) then M.cam_yaw = M.cam_yaw - 0.03 end

    local dir = { math.sin(M.cam_yaw), 0, math.cos(M.cam_yaw) }
    local right = { math.cos(M.cam_yaw), 0, -math.sin(M.cam_yaw) }
    local up = { 0, 1, 0 }

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    local pc = ffi.new("RenderPC")
    pc.cam_px, pc.cam_py, pc.cam_pz = M.cam_pos[1], M.cam_pos[2], M.cam_pos[3]
    pc.cam_dx, pc.cam_dy, pc.cam_dz = dir[1], dir[2], dir[3]
    pc.cam_ux, pc.cam_uy, pc.cam_uz = up[1], up[2], up[3]
    pc.cam_rx, pc.cam_ry, pc.cam_rz = right[1], right[2], right[3]
    pc.res_x, pc.res_y = sw.extent.width, sw.extent.height
    pc.time = M.current_time
    pc.num_transforms = num_blocks
    pc.tf_id, pc.mat_id, pc.img_id, pc.grid_id, pc.idx_id = 0, 1, 0, 2, 3
    pc.use_shadows, pc.sphere_id = (M.enable_shadows and 1 or 0), 4

    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("RenderPC"), pc)
    vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)

    local img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
        dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT,
        oldLayout = vk.VK_IMAGE_LAYOUT_GENERAL,
        newLayout = vk.VK_IMAGE_LAYOUT_GENERAL,
        image = out_img.handle,
        subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, img_barrier)

    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_blit)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("RenderPC"), pc)
    vk.vkCmdDraw(cb, 3, 1, 0, 0)
    
    imgui.new_frame()
    imgui.gui.igSetNextWindowPos(ffi.new("ImVec2_c", 10, 10), imgui.gui.ImGuiCond_Always, ffi.new("ImVec2_c", 0, 0))
    imgui.gui.igBegin("Settings", nil, imgui.gui.ImGuiWindowFlags_AlwaysAutoResize)
    imgui.gui.igText(string.format("FPS: %.1f", M.fps))
    local p_shadows = ffi.new("bool[1]", M.enable_shadows)
    if imgui.gui.igCheckbox("Enable Shadows", p_shadows) then
        M.enable_shadows = p_shadows[0]
    end
    imgui.gui.igEnd()
    imgui.render(cb)

    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])

    local now = tonumber(sdl.SDL_GetPerformanceCounter())
    local freq = tonumber(sdl.SDL_GetPerformanceFrequency())
    local dt = (now - M.last_perf_counter) / freq
    M.last_perf_counter = now
    
    table.insert(M.frame_times, dt)
    if #M.frame_times > 60 then table.remove(M.frame_times, 1) end
    local sum = 0
    for _, t in ipairs(M.frame_times) do sum = sum + t end
    M.fps = 1.0 / (sum / #M.frame_times)
end

return M
