local ffi = require("ffi")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local shader = require("vulkan.shader")
local swapchain = require("vulkan.swapchain")
local image = require("vulkan.image")
local command = require("vulkan.command")
local input = require("mc.input")
local bit = require("bit")
local constants = require("examples.29_magic_sandbox.constants")

local M = { 
    world_w = constants.WORLD_W,
    world_h = constants.WORLD_H,
    screen_w = constants.RES_W,
    screen_h = constants.RES_H,
    cam_x = 800,
    cam_y = 400,
    current_time = 0,
    frame_count = 0,
    brush_material = constants.MAT.SAND,
    brush_size = 25,
    light_img_idx = 0,
    out_img_idx = 1,
    zoom = 1.0 -- Standard HD View
}

local device, queue, sw, pipe_layout, pipe_physics, pipe_render, pipe_light, pipe_gen
local bindless_set, cb, frame_fence, image_available
local world_bufs = {}
local accum_img, light_img

local function load_glsl(path)
    local f = io.open("examples/29_magic_sandbox/shaders/" .. path, "r")
    if not f then error("Could not load shader fragment: " .. path) end
    local content = f:read("*all")
    f:close()
    return content
end

local function build_physics_shader()
    local common = load_glsl("common.glsl")
    local motion = load_glsl("physics_motion.glsl")
    local botany = load_glsl("physics_botany.glsl")
    local weather = load_glsl("physics_weather.glsl")
    
    return string.format([[
        #version 450
        #extension GL_EXT_nonuniform_qualifier : enable
        layout(local_size_x = 16, local_size_y = 16) in;
        %s
        layout(set = 0, binding = 0) buffer WorldBuffers { Pixel cells[]; } all_buffers[];
        layout(push_constant) uniform PushConstants {
            uint world_w, world_h; float time; uint frame_count;
            float mouse_x, mouse_y; uint brush_material, brush_size;
            uint in_buf_idx, out_buf_idx; float cam_x, cam_y;
            uint screen_w, screen_h; uint light_img_idx, out_img_idx;
            float zoom;
        } pc;
        void main() {
            ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
            if (pos.x >= pc.world_w || pos.y >= pc.world_h) return;
            
            // ACTIVE WINDOW ADJUSTED FOR ZOOM
            int margin = 64;
            float view_w = float(pc.screen_w) * pc.zoom;
            float view_h = float(pc.screen_h) * pc.zoom;
            if (pos.x < int(pc.cam_x) - margin || pos.x > int(pc.cam_x) + int(view_w) + margin ||
                pos.y < int(pc.cam_y) - margin || pos.y > int(pc.cam_y) + int(view_h) + margin) {
                all_buffers[pc.out_buf_idx].cells[pos.y * pc.world_w + pos.x] = all_buffers[pc.in_buf_idx].cells[pos.y * pc.world_w + pos.x];
                return;
            }
            uint idx = pos.y * pc.world_w + pos.x;
            Pixel self = all_buffers[pc.in_buf_idx].cells[idx];
            uint id = GET_ID(self); uint density = GET_DENSITY(self); uint life = GET_LIFE(self); uint flags = GET_FLAGS(self);
            Pixel next = self; float r = rand(vec2(pos) + pc.time);
            %s
            %s
            %s
            if (pc.brush_material != 0) {
                vec2 world_mouse = vec2(pc.cam_x + pc.mouse_x * view_w, pc.cam_y + pc.mouse_y * view_h);
                if (distance(vec2(pos), world_mouse) < float(pc.brush_size)) {
                    if (pc.brush_material == 1) { next.data0 = pack_data0(1, 128, 0, 0); next.data1 = pack_data1(200, 0, 0, 0, 0); }
                    else if (pc.brush_material == 2) { next.data0 = pack_data0(2, 128, 0, 0); next.data1 = pack_data1(100, 0, 0, 0, 0); }
                    else if (pc.brush_material == 3) { next.data0 = pack_data0(3, 255, 0, 0); next.data1 = pack_data1(10, 30, 0, 0, 0); }
                    else if (pc.brush_material == 6) { next.data0 = pack_data0(6, 128, 0, 0); next.data1 = pack_data1(255, 0, 0, 0, 1); }
                    else if (pc.brush_material == 12) { next.data0 = pack_data0(12, 128, 0, 0); next.data1 = pack_data1(150, (40u << 4) | 5u, 0, 0, 1); }
                }
            }
            all_buffers[pc.out_buf_idx].cells[idx] = next;
        }
    ]], common, motion, botany, weather)
end

function M.init()
    print("Example 29: EMERGENT MAGIC SANDBOX (ZOOM ENABLED)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); local q, family = vulkan.get_queue(); queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    local world_size = M.world_w * M.world_h * 8
    world_bufs[1] = mc.buffer(world_size, "storage", nil, false)
    world_bufs[2] = mc.buffer(world_size, "storage", nil, false)
    light_img = mc.gpu.image(M.screen_w, M.screen_h, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")
    accum_img = mc.gpu.image(M.screen_w, M.screen_h, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, world_bufs[1].handle, 0, world_size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, world_bufs[2].handle, 0, world_size, 1)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, light_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, M.light_img_idx)
    descriptors.update_storage_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, accum_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, M.out_img_idx)
    
    ffi.cdef[[ typedef struct SandboxPC { uint32_t world_w, world_h; float time; uint32_t frame_count; float mouse_x, mouse_y; uint32_t brush_material, brush_size; uint32_t in_buf_idx, out_buf_idx; float cam_x, cam_y; uint32_t screen_w, screen_h; uint32_t light_img_idx, out_img_idx; float zoom; } SandboxPC; ]]
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = 0x7FFFFFFF, offset = 0, size = ffi.sizeof("SandboxPC") }})
    pipe_layout = pipeline.create_layout(device, {bl_layout}, pc_range)
    
    pipe_physics = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(build_physics_shader(), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_light = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(load_glsl("light.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_render = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(load_glsl("render.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_gen = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(load_glsl("gen.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    local pool = command.create_pool(device, family)
    local gcb = command.allocate_buffers(device, pool, 1)[1]
    vk.vkBeginCommandBuffer(gcb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local bar = ffi.new("VkImageMemoryBarrier[2]")
    bar[0].sType, bar[0].oldLayout, bar[0].newLayout, bar[0].image, bar[0].srcAccessMask, bar[0].dstAccessMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL, accum_img.handle, 0, vk.VK_ACCESS_SHADER_WRITE_BIT
    bar[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    bar[1].sType, bar[1].oldLayout, bar[1].newLayout, bar[1].image, bar[1].srcAccessMask, bar[1].dstAccessMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_GENERAL, light_img.handle, 0, vk.VK_ACCESS_SHADER_WRITE_BIT
    bar[1].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    vk.vkCmdPipelineBarrier(gcb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 2, bar)
    local pc_gen = ffi.new("SandboxPC", { M.world_w, M.world_h, 123.456, 0, 0, 0, 0, 0, 0, 0, 0, 0, M.screen_w, M.screen_h, M.light_img_idx, M.out_img_idx, M.zoom })
    vk.vkCmdBindPipeline(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_gen)
    vk.vkCmdBindDescriptorSets(gcb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(gcb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("SandboxPC"), pc_gen)
    vk.vkCmdDispatch(gcb, math.ceil(M.world_w / 16), math.ceil(M.world_h / 16), 1)
    vk.vkEndCommandBuffer(gcb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, commandBufferCount = 1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {gcb}) }), nil)
    vk.vkQueueWaitIdle(queue)
    cb = command.allocate_buffers(device, pool, 1)[1]
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); image_available = image_available[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available)
    if idx == nil then return end
    input.tick(); M.current_time = M.current_time + 0.016; M.frame_count = M.frame_count + 1
    
    local speed = 4 * M.zoom -- Slow down camera movement for zoomed view
    if input.key_down(input.SCANCODE_W) then M.cam_y = M.cam_y - speed end
    if input.key_down(input.SCANCODE_S) then M.cam_y = M.cam_y + speed end
    if input.key_down(input.SCANCODE_A) then M.cam_x = M.cam_x - speed end
    if input.key_down(input.SCANCODE_D) then M.cam_x = M.cam_x + speed end
    M.cam_x = math.max(0, math.min(M.world_w - M.screen_w * M.zoom, M.cam_x))
    M.cam_y = math.max(0, math.min(M.world_h - M.screen_h * M.zoom, M.cam_y))

    local mx, my = input.mouse_pos()
    if input.key_down(input.SCANCODE_1) then M.brush_material = 1 end
    if input.key_down(input.SCANCODE_2) then M.brush_material = 2 end
    if input.key_down(input.SCANCODE_3) then M.brush_material = 3 end
    if input.key_down(input.SCANCODE_4) then M.brush_material = 6 end
    if input.key_down(input.SCANCODE_5) then M.brush_material = 8 end
    if input.key_down(input.SCANCODE_7) then M.brush_material = 12 end
    
    -- Dynamic Zoom Control
    if input.key_pressed(input.SCANCODE_Z) then
        M.zoom = (M.zoom == 0.5) and 1.0 or 0.5
        print("Zoom Level: " .. (1.0/M.zoom) .. "x")
    end

    local brush_mat = input.mouse_down(1) and M.brush_material or 0
    local in_idx = M.frame_count % 2
    local out_idx = (M.frame_count + 1) % 2
    local pc = ffi.new("SandboxPC", { M.world_w, M.world_h, M.current_time, M.frame_count, mx / sw.extent.width, my / sw.extent.height, brush_mat, M.brush_size, in_idx, out_idx, M.cam_x, M.cam_y, M.screen_w, M.screen_h, M.light_img_idx, M.out_img_idx, M.zoom })
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_physics)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("SandboxPC"), pc)
    vk.vkCmdDispatch(cb, math.ceil(M.world_w / 16), math.ceil(M.world_h / 16), 1)
    local mem_bar = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, mem_bar, 0, nil, 0, nil)
    pc.in_buf_idx = out_idx
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_light)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("SandboxPC"), pc)
    vk.vkCmdDispatch(cb, math.ceil(M.screen_w / 16), math.ceil(M.screen_h / 16), 1)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, mem_bar, 0, nil, 0, nil)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_render)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("SandboxPC"), pc)
    vk.vkCmdDispatch(cb, math.ceil(M.screen_w / 16), math.ceil(M.screen_h / 16), 1)
    local bars = ffi.new("VkImageMemoryBarrier[2]")
    bars[0].sType, bars[0].oldLayout, bars[0].newLayout, bars[0].image, bars[0].srcAccessMask, bars[0].dstAccessMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_GENERAL, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, accum_img.handle, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_ACCESS_TRANSFER_READ_BIT
    bars[0].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    bars[1].sType, bars[1].oldLayout, bars[1].newLayout, bars[1].image, bars[1].srcAccessMask, bars[1].dstAccessMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), 0, vk.VK_ACCESS_TRANSFER_WRITE_BIT
    bars[1].subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 2, bars)
    local region = ffi.new("VkImageBlit[1]")
    region[0].srcSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }
    region[0].srcOffsets[1] = { x = M.screen_w, y = M.screen_h, z = 1 }
    region[0].dstSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }
    region[0].dstOffsets[1] = { x = sw.extent.width, y = sw.extent.height, z = 1 }
    vk.vkCmdBlitImage(cb, accum_img.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region, vk.VK_FILTER_NEAREST)
    bars[0].oldLayout, bars[0].newLayout, bars[0].srcAccessMask, bars[0].dstAccessMask = vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, vk.VK_IMAGE_LAYOUT_GENERAL, vk.VK_ACCESS_TRANSFER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT
    bars[1].oldLayout, bars[1].newLayout, bars[1].srcAccessMask, bars[1].dstAccessMask = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, vk.VK_ACCESS_TRANSFER_WRITE_BIT, 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 2, bars)
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
