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
    last_perf_counter = 0,
    needs_rebuild = true,
    grid_build_ms = 0,
    render_ms = 0,
    render_scale = 1.0,
    last_render_scale = 1.0
}

local device, queue, sw, pipe_layout, pipe_render, pipe_blit, pipe_fsr
local pipe_hash, pipe_sort, pipe_build_grid
local bindless_set, cb, frame_fence, image_available
local tf_buf, mat_buf, grid_buf, coarse_buf, bitmask_buf, idx_buf, sphere_buf, sort_buf, out_img, upscale_img
local query_pool, timestamp_period
local num_blocks = 1048576 
local grid_res = 128
local coarse_res = 16
local world_min, world_max = -20, 20
local cell_size = (world_max - world_min) / grid_res

ffi.cdef[[
    typedef struct Transform { float px, py, pz, sx; float qx, qy, qz, qw; } Transform;
    typedef struct Material { float r, g, b, a; float roughness, metallic, emissive; uint32_t type; } Material;
    typedef struct Sphere { float x, y, z, r; } Sphere;
    typedef struct RenderPC {
        float cam_px, cam_py, cam_pz, cam_pw;
        float cam_dx, cam_dy, cam_dz, cam_dw;
        float cam_ux, cam_uy, cam_uz, cam_uw;
        float cam_rx, cam_ry, cam_rz, cam_rw;
        float res_x, res_y;
        float time;
        uint32_t num_transforms;
        uint32_t tf_id, mat_id, img_id, grid_id, idx_id;
        uint32_t use_shadows, sphere_id, coarse_id, bitmask_id;
    } RenderPC;
    typedef struct FSRPC {
        float src_res_x, src_res_y;
        float dst_res_x, dst_res_y;
        uint32_t src_id, dst_id, pad0, pad1;
    } FSRPC;
    typedef struct HashPC { uint32_t sphere_id, entry_id, num_blocks, pad; } HashPC;
    typedef struct SortPC { uint32_t entry_id, j, k, pad; } SortPC;
    typedef struct BuildPC { uint32_t entry_id, grid_id, coarse_id, idx_id, bitmask_id; uint32_t num_blocks, pass, pad; } BuildPC;
]]

function M.rebuild_grid(cb)
    vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, query_pool, 0)
    local h_pc = ffi.new("HashPC", { sphere_id = 4, entry_id = 6, num_blocks = num_blocks })
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_hash)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("HashPC"), h_pc)
    vk.vkCmdDispatch(cb, num_blocks / 256, 1, 1)
    local bar_hash = ffi.new("VkBufferMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), buffer=sort_buf.handle, offset=0, size=sort_buf.size }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, bar_hash, 0, nil)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_sort)
    local s_pc = ffi.new("SortPC", { entry_id = 6 })
    local k = 2
    while k <= num_blocks do
        local j = k / 2
        while j >= 1 do
            s_pc.j, s_pc.k = j, k
            vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("SortPC"), s_pc)
            vk.vkCmdDispatch(cb, num_blocks / 256, 1, 1)
            vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, bar_hash, 0, nil)
            j = j / 2
        end
        k = k * 2
    end
    local b_pc = ffi.new("BuildPC", { entry_id = 6, grid_id = 2, coarse_id = 5, idx_id = 3, bitmask_id = 7, num_blocks = num_blocks, pass = 0 })
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_build_grid)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("BuildPC"), b_pc)
    vk.vkCmdDispatch(cb, math.ceil((grid_res^3) / 256), 1, 1) 
    
    local bar_grid = ffi.new("VkBufferMemoryBarrier[3]", {
        { sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), buffer=grid_buf.handle, offset=0, size=grid_buf.size },
        { sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), buffer=coarse_buf.handle, offset=0, size=coarse_buf.size },
        { sType=vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask=vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask=bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT), buffer=bitmask_buf.handle, offset=0, size=bitmask_buf.size }
    })
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 3, bar_grid, 0, nil)
    
    b_pc.pass = 1
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("BuildPC"), b_pc)
    vk.vkCmdDispatch(cb, math.ceil(num_blocks / 256), 1, 1) 
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 3, bar_grid, 0, nil)

    b_pc.pass = 2
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("BuildPC"), b_pc)
    vk.vkCmdDispatch(cb, math.ceil(num_blocks / 256), 1, 1) 
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 3, bar_grid, 0, nil)
    vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, query_pool, 1)
end

function M.create_render_target()
    local render_w = math.floor(sw.extent.width * M.render_scale)
    local render_h = math.floor(sw.extent.height * M.render_scale)
    out_img = mc.gpu.image(render_w, render_h, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")
    upscale_img = mc.gpu.image(sw.extent.width, sw.extent.height, vk.VK_FORMAT_R32G32B32A32_SFLOAT, "storage")
    
    descriptors.update_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, out_img.view, nil, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, bindless_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, upscale_img.view, nil, vk.VK_IMAGE_LAYOUT_GENERAL, 1)
    
    local blit_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR, vk.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, out_img.view, blit_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 50)
    descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, upscale_img.view, blit_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 51)
end

function M.init()
    print("Example 50: GPU Spatial Hash Renderer (1M blocks)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); local q, family = vulkan.get_queue(); queue = q
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    imgui.init(); M.last_perf_counter = tonumber(sdl.SDL_GetPerformanceCounter())
    local props = ffi.new("VkPhysicalDeviceProperties")
    vk.vkGetPhysicalDeviceProperties(physical_device, props)
    timestamp_period = props.limits.timestampPeriod
    local q_pool_info = ffi.new("VkQueryPoolCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO, queryType = vk.VK_QUERY_TYPE_TIMESTAMP, queryCount = 4 })
    local qp = ffi.new("VkQueryPool[1]"); vk.vkCreateQueryPool(device, q_pool_info, nil, qp); query_pool = qp[0]

    tf_buf = mc.buffer(num_blocks * ffi.sizeof("Transform"), "storage", nil, false)
    mat_buf = mc.buffer(num_blocks * ffi.sizeof("Material"), "storage", nil, false)
    sphere_buf = mc.buffer(num_blocks * ffi.sizeof("Sphere"), "storage", nil, false)
    idx_buf = mc.buffer(num_blocks * 4, "storage", nil, false) 
    sort_buf = mc.buffer(num_blocks * 8, "storage", nil, false) 
    grid_buf = mc.buffer(grid_res * grid_res * grid_res * 8, "storage", nil, false) 
    coarse_buf = mc.buffer(coarse_res * coarse_res * coarse_res * 4, "storage", nil, false) 
    bitmask_buf = mc.buffer((grid_res/4)^3 * 8, "storage", nil, false) 

    local host_tf, host_mat, host_sphere = ffi.new("Transform[?]", num_blocks), ffi.new("Material[?]", num_blocks), ffi.new("Sphere[?]", num_blocks)
    math.randomseed(42)
    for i=0, num_blocks-1 do
        local px, py, pz = (math.random()-0.5)*38, (math.random()-0.5)*38, (math.random()-0.5)*38
        local sx = 0.1
        host_tf[i].px, host_tf[i].py, host_tf[i].pz, host_tf[i].sx = px, py, pz, sx
        host_tf[i].qx, host_tf[i].qy, host_tf[i].qz, host_tf[i].qw = 0, 0, 0, 1
        host_sphere[i].x, host_sphere[i].y, host_sphere[i].z, host_sphere[i].r = px, py, pz, 0.1
        host_mat[i].r, host_mat[i].g, host_mat[i].b, host_mat[i].a = math.random(), math.random(), math.random(), 1
        host_mat[i].emissive = (math.random() > 0.999) and 5.0 or 0.0
    end
    tf_buf:upload(host_tf); mat_buf:upload(host_mat); sphere_buf:upload(host_sphere)

    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, tf_buf.handle, 0, tf_buf.size, 0)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, mat_buf.handle, 0, mat_buf.size, 1)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, grid_buf.handle, 0, grid_buf.size, 2)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, idx_buf.handle, 0, idx_buf.size, 3)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sphere_buf.handle, 0, sphere_buf.size, 4)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, coarse_buf.handle, 0, coarse_buf.size, 5)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, sort_buf.handle, 0, sort_buf.size, 6)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, bitmask_buf.handle, 0, bitmask_buf.size, 7)

    M.create_render_target()

    pipe_layout = pipeline.create_layout(device, {bl_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = 0x7FFFFFFF, offset = 0, size = 128 }}))
    local function load_comp(path) return pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open(path):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT))) end
    pipe_render, pipe_hash, pipe_sort, pipe_build_grid = load_comp("examples/50_custom_renderer/render.comp"), load_comp("examples/50_custom_renderer/hash.comp"), load_comp("examples/50_custom_renderer/sort.comp"), load_comp("examples/50_custom_renderer/build_grid.comp")
    pipe_fsr = load_comp("examples/50_custom_renderer/fsr.comp")
    
    local v_mod = shader.create_module(device, shader.compile_glsl([[#version 450
        layout(location = 0) out vec2 outUV;
        void main() { 
            vec2 pos[3] = vec2[](vec2(-1,-1), vec2(3,-1), vec2(-1,3)); 
            gl_Position = vec4(pos[gl_VertexIndex], 0, 1); 
            outUV = pos[gl_VertexIndex] * 0.5 + 0.5;
        }]], vk.VK_SHADER_STAGE_VERTEX_BIT))
    local f_mod = shader.create_module(device, shader.compile_glsl([[#version 450
        #extension GL_EXT_nonuniform_qualifier : require
        layout(location = 0) in vec2 inUV;
        layout(location = 0) out vec4 outColor;
        layout(set = 0, binding = 1) uniform sampler2D tex_samplers[];
        layout(push_constant) uniform PC { float pad[22]; uint img_id; } pc;
        void main() { outColor = texture(tex_samplers[nonuniformEXT(pc.img_id)], inUV); }]], vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    pipe_blit = pipeline.create_graphics_pipeline(device, pipe_layout, v_mod, f_mod, { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST })

    local pool = command.create_pool(device, family)
    cb = command.allocate_buffers(device, pool, 1)[1]
    frame_fence = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); frame_fence = frame_fence[0]
    image_available = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); image_available = image_available[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local results = ffi.new("uint64_t[4]")
    local res = vk.vkGetQueryPoolResults(device, query_pool, 0, 4, ffi.sizeof("uint64_t") * 4, results, ffi.sizeof("uint64_t"), vk.VK_QUERY_RESULT_64_BIT)
    if res == vk.VK_SUCCESS then
        M.grid_build_ms = tonumber(results[1] - results[0]) * timestamp_period / 1e6
        M.render_ms = tonumber(results[3] - results[2]) * timestamp_period / 1e6
    end
    vk.vkResetQueryPool(device, query_pool, 0, 4)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available)
    if idx == nil then return end
    input.tick(); M.current_time = M.current_time + 0.016
    local speed = 0.2
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1] = M.cam_pos[1] + math.sin(M.cam_yaw) * speed; M.cam_pos[3] = M.cam_pos[3] + math.cos(M.cam_yaw) * speed end
    if input.key_down(input.SCANCODE_S) then M.cam_pos[1] = M.cam_pos[1] - math.sin(M.cam_yaw) * speed; M.cam_pos[3] = M.cam_pos[3] - math.cos(M.cam_yaw) * speed end
    if input.key_down(input.SCANCODE_A) then M.cam_yaw = M.cam_yaw + 0.03 end
    if input.key_down(input.SCANCODE_D) then M.cam_yaw = M.cam_yaw - 0.03 end

    if math.abs(M.render_scale - M.last_render_scale) > 0.001 then
        vk.vkDeviceWaitIdle(device)
        M.create_render_target()
        M.last_render_scale = M.render_scale
    end

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    if M.needs_rebuild then M.rebuild_grid(cb); M.needs_rebuild = false
    else vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, query_pool, 0); vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, query_pool, 1) end

    local render_w, render_h = math.floor(sw.extent.width * M.render_scale), math.floor(sw.extent.height * M.render_scale)
    local pc = ffi.new("RenderPC")
    pc.cam_px, pc.cam_py, pc.cam_pz, pc.cam_pw = M.cam_pos[1], M.cam_pos[2], M.cam_pos[3], 1.0
    pc.cam_dx, pc.cam_dy, pc.cam_dz, pc.cam_dw = math.sin(M.cam_yaw), 0, math.cos(M.cam_yaw), 0.0
    pc.cam_ux, pc.cam_uy, pc.cam_uz, pc.cam_uw = 0, 1, 0, 0.0
    pc.cam_rx, pc.cam_ry, pc.cam_rz, pc.cam_rw = math.cos(M.cam_yaw), 0, -math.sin(M.cam_yaw), 0.0
    pc.res_x, pc.res_y, pc.time, pc.num_transforms = render_w, render_h, M.current_time, num_blocks
    pc.tf_id, pc.mat_id, pc.img_id, pc.grid_id, pc.idx_id = 0, 1, 0, 2, 3
    pc.use_shadows, pc.sphere_id, pc.coarse_id, pc.bitmask_id = (M.enable_shadows and 1 or 0), 4, 5, 7

    vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, query_pool, 2)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_render)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("RenderPC"), pc)
    vk.vkCmdDispatch(cb, math.ceil(render_w / 8), math.ceil(render_h / 8), 1)

    -- Stage 2: FSR Upscale
    local img_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, oldLayout = vk.VK_IMAGE_LAYOUT_GENERAL, newLayout = vk.VK_IMAGE_LAYOUT_GENERAL, image = out_img.handle, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, img_barrier)
    
    local fsr_pc = ffi.new("FSRPC", { 
        src_res_x = render_w, src_res_y = render_h, 
        dst_res_x = sw.extent.width, dst_res_y = sw.extent.height, 
        src_id = 50, dst_id = 1 
    })
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_fsr)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("FSRPC"), fsr_pc)
    vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 8), math.ceil(sw.extent.height / 8), 1)

    vk.vkCmdWriteTimestamp(cb, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, query_pool, 3)

    local upscale_barrier = ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, oldLayout = vk.VK_IMAGE_LAYOUT_GENERAL, newLayout = vk.VK_IMAGE_LAYOUT_GENERAL, image = upscale_img.handle, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nil, 0, nil, 1, upscale_barrier)
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, image=ffi.cast("VkImage", sw.images[idx]), subresourceRange={aspectMask=vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount=1, layerCount=1}, dstAccessMask=vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)
    
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType, color_attach[0].imageView, color_attach[0].imageLayout, color_attach[0].loadOp, color_attach[0].storeOp = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, ffi.cast("VkImageView", sw.views[idx]), vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { width=sw.extent.width, height=sw.extent.height, maxDepth=1 }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent=sw.extent }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_blit)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    pc.img_id = 51 -- Binding 1, index 51 (Upscaled Scene)
    vk.vkCmdPushConstants(cb, pipe_layout, 0x7FFFFFFF, 0, ffi.sizeof("RenderPC"), pc)
    vk.vkCmdDraw(cb, 3, 1, 0, 0)
    
    imgui.new_frame()
    imgui.gui.igSetNextWindowPos(ffi.new("ImVec2_c", 10, 10), imgui.gui.ImGuiCond_Always, ffi.new("ImVec2_c", 0, 0))
    imgui.gui.igBegin("Settings", nil, imgui.gui.ImGuiWindowFlags_AlwaysAutoResize)
    imgui.gui.igText(string.format("FPS: %.1f", M.fps)); imgui.gui.igText(string.format("Grid Build: %.3f ms", M.grid_build_ms)); imgui.gui.igText(string.format("Render: %.3f ms", M.render_ms))
    local p_scale = ffi.new("float[1]", M.render_scale); if imgui.gui.igSliderFloat("Render Scale", p_scale, 0.1, 1.0, "%.2f", 0) then M.render_scale = p_scale[0] end
    local p_shadows = ffi.new("bool[1]", M.enable_shadows); if imgui.gui.igCheckbox("Enable Shadows", p_shadows) then M.enable_shadows = p_shadows[0] end
    if imgui.gui.igButton("Force Rebuild Grid", ffi.new("ImVec2_c", 0, 0)) then M.needs_rebuild = true end
    imgui.gui.igEnd(); imgui.render(cb); vk.vkCmdEndRendering(cb)

    bar[0].oldLayout, bar[0].newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
    local now, freq = tonumber(sdl.SDL_GetPerformanceCounter()), tonumber(sdl.SDL_GetPerformanceFrequency())
    local dt = (now - M.last_perf_counter) / freq; M.last_perf_counter = now
    table.insert(M.frame_times, dt); if #M.frame_times > 60 then table.remove(M.frame_times, 1) end
    local sum = 0; for _, t in ipairs(M.frame_times) do sum = sum + t end; M.fps = 1.0 / (sum / #M.frame_times)
end

return M
