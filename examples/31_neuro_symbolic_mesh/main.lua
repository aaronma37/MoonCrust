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

local M = { cam_pos = {0, 5, 15}, cam_rot = {0, -0.3}, current_time = 0, frame_count = 0 }
local device, queue, graphics_family, sw, pipe_layout, pipe_render, pipe_compute
local bindless_set, cb, frame_fence, image_available
local v_buffer, s_buffer, i_buffer, depth_image, compute_set, compute_layout

ffi.cdef[[
    typedef struct ScenePC {
        mc_mat4 view_proj;
        mc_vec4 color;
        float time;
    } ScenePC;

    typedef struct AnnealPC {
        float temp;
        uint32_t iter;
        uint32_t vertex_count;
        uint32_t triangle_count;
        uint32_t steps;
        float learning_rate;
        float time;
    } AnnealPC;
]]

local pc_stages = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT)

-- Generate a subdivided box (used as primitive seed)
local function add_box(vertices, indices, pos, size, res, bone_id)
    local function add_face(dir, up, right)
        local f_start = #vertices / 4
        for y = 0, res do
            for x = 0, res do
                local u, v = x / res - 0.5, y / res - 0.5
                local lx = (dir[1] * 0.5 + u * right[1] + v * up[1]) * size[1] * 2
                local ly = (dir[2] * 0.5 + u * right[2] + v * up[2]) * size[2] * 2
                local lz = (dir[3] * 0.5 + u * right[3] + v * up[3]) * size[3] * 2
                table.insert(vertices, pos[1] + lx)
                table.insert(vertices, pos[2] + ly)
                table.insert(vertices, pos[3] + lz)
                table.insert(vertices, bone_id or 0.0)
            end
        end
        for y = 0, res - 1 do
            for x = 0, res - 1 do
                local i = f_start + y * (res + 1) + x
                table.insert(indices, i); table.insert(indices, i + 1); table.insert(indices, i + res + 1)
                table.insert(indices, i + 1); table.insert(indices, i + res + 2); table.insert(indices, i + res + 1)
            end
        end
    end
    add_face({0,0,1}, {0,1,0}, {1,0,0})
    add_face({0,0,-1}, {0,1,0}, {-1,0,0})
    add_face({0,1,0}, {0,0,-1}, {1,0,0})
    add_face({0,-1,0}, {0,0,1}, {1,0,0})
    add_face({1,0,0}, {0,1,0}, {0,0,-1})
    add_face({-1,0,0}, {0,1,0}, {0,0,1})
end

function M.init()
    print("Example 31: Neuro-Symbolic Dragon Designer (Extended Wings)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue(); sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    depth_image = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")
    
    local vertices, indices = {}, {}
    local res = 10
    -- 1. DRAGON SKELTON CONSTRUCTION
    add_box(vertices, indices, {0, 1.5, 0.2}, {0.8, 0.8, 1.5}, res, 0) -- Body
    add_box(vertices, indices, {0, 2.2, 2.2}, {0.4, 0.4, 1.0}, res, 1) -- Neck
    add_box(vertices, indices, {0, 3.1, 3.5}, {0.5, 0.5, 0.6}, res, 2) -- Head
    add_box(vertices, indices, {0, 1.0, -2.5}, {0.3, 0.3, 2.5}, res, 3) -- Tail
    add_box(vertices, indices, {-0.9, 0.7, 1.1}, {0.3, 0.8, 0.3}, 4, 4) -- Legs
    add_box(vertices, indices, { 0.9, 0.7, 1.1}, {0.3, 0.8, 0.3}, 4, 4)
    add_box(vertices, indices, {-0.9, 0.6, -0.6}, {0.3, 0.8, 0.3}, 4, 4)
    add_box(vertices, indices, { 0.9, 0.6, -0.6}, {0.3, 0.8, 0.3}, 4, 4)
    
    -- Wings: Start them at the shoulder pivots, but make them very wide (extent 4.0)
    add_box(vertices, indices, {-3.0, 2.0, 0.0}, {3.0, 0.1, 1.5}, res, 5) -- Wing L
    add_box(vertices, indices, { 3.0, 2.0, 0.0}, {3.0, 0.1, 1.5}, res, 6) -- Wing R
    
    local sa_v_count = #vertices / 4
    local fs = #vertices / 4; local fz = 30.0
    table.insert(vertices, -fz); table.insert(vertices, 0); table.insert(vertices, -fz); table.insert(vertices, 99.0)
    table.insert(vertices,  fz); table.insert(vertices, 0); table.insert(vertices, -fz); table.insert(vertices, 99.0)
    table.insert(vertices,  fz); table.insert(vertices, 0); table.insert(vertices,  fz); table.insert(vertices, 99.0)
    table.insert(vertices, -fz); table.insert(vertices, 0); table.insert(vertices,  fz); table.insert(vertices, 99.0)
    table.insert(indices, fs+0); table.insert(indices, fs+1); table.insert(indices, fs+2); table.insert(indices, fs+0); table.insert(indices, fs+2); table.insert(indices, fs+3)
    
    local v_data = ffi.new("float[?]", #vertices); for i=1, #vertices do v_data[i-1] = vertices[i] end
    local i_data = ffi.new("uint32_t[?]", #indices); for i=1, #indices do i_data[i-1] = indices[i] end
    v_buffer, s_buffer, i_buffer = mc.gpu.buffer(#vertices * 4, "vertex", v_data), mc.gpu.buffer(#vertices * 4, "storage", v_data), mc.gpu.buffer(#indices * 4, "index", i_data)
    M.vertex_count, M.sa_vertex_count, M.index_count = #vertices / 4, sa_v_count, #indices
    
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    compute_layout = descriptors.create_layout(device, {{ binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }})
    compute_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 2 }}), {compute_layout})[1]
    vk.vkUpdateDescriptorSets(device, 2, ffi.new("VkWriteDescriptorSet[2]", { { sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = compute_set, dstBinding = 0, descriptorCount = 1, descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pBufferInfo = ffi.new("VkDescriptorBufferInfo", { buffer = v_buffer.handle, offset = 0, range = v_buffer.size }) }, { sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = compute_set, dstBinding = 1, descriptorCount = 1, descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pBufferInfo = ffi.new("VkDescriptorBufferInfo", { buffer = s_buffer.handle, offset = 0, range = s_buffer.size }) } }), 0, nil)
    pipe_layout = pipeline.create_layout(device, {bl_layout, compute_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_stages, offset = 0, size = 128 }}))
    local v_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 4 * 4, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}); local v_attribs = ffi.new("VkVertexInputAttributeDescription[1]", {{ location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32A32_SFLOAT, offset = 0 }})
    local v_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/31_neuro_symbolic_mesh/render.vert"):read("*all"):gsub('#include "cost.glsl"', io.open("examples/31_neuro_symbolic_mesh/cost.glsl"):read("*all")), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl(io.open("examples/31_neuro_symbolic_mesh/render.frag"):read("*all"):gsub('#include "cost.glsl"', io.open("examples/31_neuro_symbolic_mesh/cost.glsl"):read("*all")), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_render = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { depth_test = true, depth_write = true, color_formats = {vk.VK_FORMAT_B8G8R8A8_SRGB}, vertex_binding = v_binding, vertex_attributes = v_attribs, vertex_attribute_count = 1, cull_mode = vk.VK_CULL_MODE_NONE, topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST })
    local compute_src = [[#version 450
layout(local_size_x = 64) in;
layout(set = 1, binding = 0) buffer V { vec4 p[]; } v;
layout(set = 1, binding = 1) buffer S { vec4 p[]; } s;
layout(push_constant) uniform PC { float temp; uint iter; uint count; uint tr; uint steps; float lr; float time; } pc;
#include "cost.glsl"
uint hash(uint x) { x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; x ^= x >> 16; return x; }
float rand(inout uint s) { s = hash(s + 0x9e3779b9); return float(s & 0xffffff) / 16777216.0; }
void main() {
    uint i = gl_GlobalInvocationID.x; if (i >= pc.count) return;
    uint rng = (pc.iter * 747796405u) ^ i;
    vec3 p = v.p[i].xyz; vec4 seed_full = s.p[i]; uint bone_id = uint(seed_full.w);
    
    // 1. Calculate Moving Anchor for Wings
    vec3 anchor_p = seed_full.xyz;
    if (bone_id == 5) { // Left Wing
        vec3 pl = anchor_p - vec3(-0.8, 2.0, 0.0);
        float flap = sin(pc.time * 3.5) * 0.5;
        pRotY(pl, -0.4); pRotZ(pl, 0.5 + flap);
        anchor_p = pl + vec3(-2.8, 2.0, 0.0);
    } else if (bone_id == 6) { // Right Wing
        vec3 pr = anchor_p - vec3(0.8, 2.0, 0.0);
        float flap = sin(pc.time * 3.5) * 0.5;
        pRotY(pr, 0.4); pRotZ(pr, -0.5 - flap);
        anchor_p = pr + vec3(2.8, 2.0, 0.0);
    }

    float anchor_w = (bone_id >= 5) ? 1.5 : 3.0; // Stronger tether for wings
    float cost = abs(compute_shape_cost(p, pc.time)) * 30.0 + length(p - anchor_p) * anchor_w;
    
    // 2. Repulsion Force (Prevent wing gathering)
    for (int k = 0; k < 4; k++) {
        uint other = uint(rand(rng) * float(pc.count));
        if (other != i) {
            float dist = length(p - v.p[other].xyz);
            cost += 0.05 / (dist + 0.01);
        }
    }

    float step = pc.lr * (0.1 + pc.temp);
    for (uint it = 0; it < pc.steps; ++it) {
        vec3 np = p + (vec3(rand(rng), rand(rng), rand(rng)) * 2.0 - 1.0) * step;
        float nc = abs(compute_shape_cost(np, pc.time)) * 30.0 + length(np - anchor_p) * anchor_w;
        if (nc < cost || rand(rng) < exp(-(nc - cost) / pc.temp)) { p = np; cost = nc; }
    }
    v.p[i].xyz = p;
}]]
    pipe_compute = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(compute_src:gsub('#include "cost.glsl"', io.open("examples/31_neuro_symbolic_mesh/cost.glsl"):read("*all")), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    frame_fence, image_available = ffi.new("VkFence[1]"), ffi.new("VkSemaphore[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); frame_fence, image_available = frame_fence[0], image_available[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    input.tick(); M.current_time = M.current_time + 0.016; M.frame_count = M.frame_count + 1
    local speed, look_speed = (input.key_down(input.SCANCODE_LSHIFT) and 15.0 or 5.0) * 0.016, 1.5 * 0.016
    if input.key_down(input.SCANCODE_A) then M.cam_rot[1] = M.cam_rot[1] + look_speed end; if input.key_down(input.SCANCODE_D) then M.cam_rot[1] = M.cam_rot[1] - look_speed end
    local fwd_x, fwd_z = math.sin(M.cam_rot[1]), -math.cos(M.cam_rot[1])
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] + fwd_x*speed, M.cam_pos[3] + fwd_z*speed end; if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] - fwd_x*speed, M.cam_pos[3] - fwd_z*speed end
    local view = mc.math.mat4_look_at(M.cam_pos, { M.cam_pos[1] + fwd_x, M.cam_pos[2], M.cam_pos[3] + fwd_z }, {0, 1, 0})
    local vp = mc.math.mat4_multiply(mc.math.mat4_perspective(mc.math.rad(70), sw.extent.width / sw.extent.height, 0.01, 1000.0), view)
    local sc_pc = ffi.new("ScenePC"); ffi.copy(sc_pc.view_proj.m, vp.m, 64); sc_pc.color.x, sc_pc.color.y, sc_pc.color.z, sc_pc.color.w = 0.2, 0.6, 0.3, 1.0; sc_pc.time = M.current_time
    local an_pc = ffi.new("AnnealPC"); an_pc.temp = 0.02; an_pc.vertex_count, an_pc.steps, an_pc.learning_rate, an_pc.time = M.sa_vertex_count, 15, 0.01, M.current_time
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_compute); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 1, 1, ffi.new("VkDescriptorSet[1]", {compute_set}), 0, nil)
    for i = 1, 10 do
        an_pc.iter = M.frame_count * 10 + i; vk.vkCmdPushConstants(cb, pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("AnnealPC"), an_pc); vk.vkCmdDispatch(cb, math.ceil(M.sa_vertex_count / 64), 1, 1)
        vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, ffi.new("VkBufferMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, buffer = v_buffer.handle, offset = 0, size = vk.VK_WHOLE_SIZE, srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED, dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED }}), 0, nil)
    end
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, 0, 0, nil, 0, nil, 0, nil)
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE; color_attach[0].clearValue.color.float32[0], color_attach[0].clearValue.color.float32[1], color_attach[0].clearValue.color.float32[2], color_attach[0].clearValue.color.float32[3] = 0.02, 0.03, 0.05, 1.0
    local d_attach = ffi.new("VkRenderingAttachmentInfo[1]"); d_attach[0].sType, d_attach[0].imageView, d_attach[0].imageLayout, d_attach[0].loadOp, d_attach[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, depth_image.view, vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_DONT_CARE; d_attach[0].clearValue.depthStencil = {depth=1.0}
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 2, ffi.new("VkImageMemoryBarrier[2]", { { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }, { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, image = depth_image.handle, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT } }))
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach, pDepthAttachment = d_attach }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_render); vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {v_buffer.handle}), ffi.new("VkDeviceSize[1]", {0})); vk.vkCmdBindIndexBuffer(cb, i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT32); vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("ScenePC"), sc_pc); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x = 0, y = 0, width = sw.extent.width, height = sw.extent.height, minDepth = 0, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset = {0,0}, extent = sw.extent }))
    vk.vkCmdDrawIndexed(cb, M.index_count, 1, 0, 0, 0); vk.vkCmdEndRendering(cb)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask = 0 }}))
    vk.vkEndCommandBuffer(cb); vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence); sw:present(queue, idx, sw.semaphores[idx])
end

return M
