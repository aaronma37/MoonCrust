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
local loader = require("examples.30_sponza_gltf.loader")

local M = { cam_pos = {0, 2, 5}, cam_rot = {0, 0}, current_time = 0, frame_count = 0 }
local device, queue, graphics_family, sw, pipe_layout, pipe_gbuffer, pipe_lighting, pipe_post
local bindless_set, cb, frame_fence, image_available
local model_data, v_buffer, i_buffer
local g_albedo, g_normal, g_mra, g_worldpos, g_depth, hdr_color
local compute_set, compute_layout
local textures = {}

ffi.cdef[[
    typedef struct ScenePC {
        mc_mat4 view_proj;     // 64 bytes
        mc_vec4 cam_pos;       // 16 bytes
        mc_vec4 light_pos;     // 16 bytes
        mc_vec4 base_color;    // 16 bytes
        mc_mat4 light_space;   // 64 bytes
        float time;            // 4 bytes
        uint32_t albedo_idx;   // 4 bytes
        uint32_t normal_idx;   // 4 bytes
        uint32_t mra_idx;      // 4 bytes
    } ScenePC;                 // Total: 192 bytes (Safely under 256!)
]]

local shadow = { extent = { width = 1024, height = 1024 } }
local ssao = {}
local bloom = {}
local vol = {}
local pre = {} 

local pc_stages = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT)

function M.init()
    print("Example 30: Restoring Stable High-End Sponza")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue(); sw = swapchain.new(instance, physical_device, device, _SDL_WINDOW)
    
    model_data = loader.load("examples/30_sponza_gltf/Sponza/glTF/Sponza.gltf")
    v_buffer = mc.buffer(model_data.vertex_count * 8 * 4, "vertex", model_data.vertices); i_buffer = mc.buffer(model_data.index_count * 4, "index", model_data.indices)
    
    bindless_set = mc.gpu.get_bindless_set(); local bl_layout = mc.gpu.get_bindless_layout()
    local sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR); shadow.sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)
    local linear_sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR); local noise_sampler = mc.gpu.sampler(vk.VK_FILTER_NEAREST, vk.VK_SAMPLER_ADDRESS_MODE_REPEAT)
    
    local staging = require("vulkan.staging").new(physical_device, device, mc.gpu.heaps.host, 64 * 1024 * 1024)
    
    -- SSAO Noise & Kernel
    local kernel_data = ffi.new("float[64 * 4]")
    for i = 0, 63 do local x,y,z = math.random()*2-1, math.random()*2-1, math.random(); local len = math.sqrt(x*x+y*y+z*z); local scale = i/64.0; scale = 0.1+0.9*(scale*scale); kernel_data[i*4+0],kernel_data[i*4+1],kernel_data[i*4+2],kernel_data[i*4+3] = (x/len)*scale, (y/len)*scale, (z/len)*scale, 0.0 end
    ssao.kernel_buffer = mc.gpu.buffer(64 * 4 * 4, "storage", kernel_data)
    local noise_data = ffi.new("float[16 * 4]")
    for i = 0, 15 do noise_data[i*4+0],noise_data[i*4+1],noise_data[i*4+2],noise_data[i*4+3] = math.random()*2-1, math.random()*2-1, 0.0, 1.0 end
    ssao.noise_image = mc.gpu.image(4, 4, vk.VK_FORMAT_R32G32B32_SFLOAT, "sampled"); ssao.noise_image.mip_levels = 1; staging:upload_image(ssao.noise_image.handle, 4, 4, noise_data, queue, graphics_family, 16 * 4 * 4, 1)

    -- Default Textures
    local white_pixels = ffi.new("uint8_t[4]", {255, 255, 255, 255}); local default_img = mc.gpu.image(1, 1, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled"); staging:upload_image(default_img.handle, 1, 1, white_pixels, queue, graphics_family, 4)
    for i = 0, 1023 do descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, default_img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, i) end

    -- Load Sponza Textures (Optimized)
    for i, tex in ipairs(model_data.textures or {}) do
        local img_info = model_data.images[tex.source + 1]; local tex_path = (model_data.base_dir .. img_info.uri); local used = false
        for _, mat in ipairs(model_data.materials or {}) do local pbr = mat.pbrMetallicRoughness or {}; if (pbr.baseColorTexture and pbr.baseColorTexture.index == i - 1) or (pbr.metallicRoughnessTexture and pbr.metallicRoughnessTexture.index == i - 1) or (mat.normalTexture and mat.normalTexture.index == i - 1) then used = true; break end end
        if used then local pixels, tw, th = loader.load_image(tex_path); if pixels then local gpu_img = mc.gpu.image(tw, th, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled"); staging:upload_image(gpu_img.handle, tw, th, pixels, queue, graphics_family, tw * th * 4, gpu_img.mip_levels); descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, gpu_img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, i-1); textures[i] = gpu_img end end
    end

    local w, h = sw.extent.width, sw.extent.height; if not w or w == 0 then w, h = 1280, 720 end
    g_albedo, g_normal, g_mra, g_worldpos, g_depth, hdr_color = mc.gpu.image(w, h, vk.VK_FORMAT_R8G8B8A8_UNORM, "storage"), mc.gpu.image(w, h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage"), mc.gpu.image(w, h, vk.VK_FORMAT_R8G8B8A8_UNORM, "storage"), mc.gpu.image(w, h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage"), mc.gpu.image(w, h, vk.VK_FORMAT_D32_SFLOAT, "depth"), mc.gpu.image(w, h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage")
    ssao.image, ssao.blur_image, vol.image = mc.gpu.image(w/2, h/2, vk.VK_FORMAT_R8_UNORM, "storage"), mc.gpu.image(w/2, h/2, vk.VK_FORMAT_R8_UNORM, "storage"), mc.gpu.image(w/2, h/2, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage")
    bloom.bright_img, bloom.blur_img = mc.gpu.image(w/2, h/2, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage"), mc.gpu.image(w/2, h/2, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage")
    shadow.image = mc.gpu.image(shadow.extent.width, shadow.extent.height, vk.VK_FORMAT_D32_SFLOAT, "depth")

    compute_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 5, type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 6, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 7, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 8, type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 9, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 10, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 11, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 12, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 13, type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 14, type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
    })
    compute_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, count = 30 }, { type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, count = 20 }, { type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 5 }}), {compute_layout})[1]
    descriptors.update_storage_image_set(device, compute_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, g_albedo.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, g_normal.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, g_mra.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, g_worldpos.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, hdr_color.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, compute_set, 5, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, shadow.image.view, shadow.sampler, vk.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 6, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, ssao.image.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 7, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, ssao.blur_image.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, compute_set, 8, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, ssao.noise_image.view, noise_sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 10, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, bloom.bright_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 11, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, bloom.blur_img.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_storage_image_set(device, compute_set, 12, vk.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, vol.image.view, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, compute_set, 13, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, ssao.blur_image.view, linear_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    descriptors.update_image_set(device, compute_set, 14, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, vol.image.view, linear_sampler, vk.VK_IMAGE_LAYOUT_GENERAL, 0)
    
    local kernel_info = ffi.new("VkDescriptorBufferInfo", { buffer = ssao.kernel_buffer.handle, offset = 0, range = ssao.kernel_buffer.size })
    vk.vkUpdateDescriptorSets(device, 1, ffi.new("VkWriteDescriptorSet[1]", {{ sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, dstSet = compute_set, dstBinding = 9, descriptorCount = 1, descriptorType = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, pBufferInfo = kernel_info }}), 0, nil)
    
    pipe_layout = pipeline.create_layout(device, {bl_layout, compute_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_stages, offset = 0, size = ffi.sizeof("ScenePC") }}))
    local v_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 8 * 4, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }}); local v_attribs = ffi.new("VkVertexInputAttributeDescription[3]", {{ location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 }, { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 3 * 4 }, { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32_SFLOAT, offset = 6 * 4 }})
    
    pipe_gbuffer = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/gbuffer.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/gbuffer.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { depth_test = true, depth_write = true, color_formats = {vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT, vk.VK_FORMAT_R8G8B8A8_UNORM, vk.VK_FORMAT_R16G16B16A16_SFLOAT}, vertex_binding = v_binding, vertex_attributes = v_attribs, vertex_attribute_count = 3, cull_mode = vk.VK_CULL_MODE_NONE })
    pipe_shadow = pipeline.create_graphics_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/shadow.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), nil, { depth_test = true, depth_write = true, color_formats = {}, vertex_binding = v_binding, vertex_attributes = v_attribs, vertex_attribute_count = 3, cull_mode = vk.VK_CULL_MODE_BACK_BIT })
    
    pipe_lighting = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/lighting.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    ssao.pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/ssao.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    ssao.pipe_blur = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/ssao_blur.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    bloom.pipe_bright = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/bloom_bright.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    bloom.pipe_blur = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/bloom_blur.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    bloom.pipe_composite = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/bloom_composite.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    vol.pipe = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/volumetric.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    pipe_post = pipeline.create_compute_pipeline(device, pipe_layout, shader.create_module(device, shader.compile_glsl(io.open("examples/30_sponza_gltf/shaders/post.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    
    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    frame_fence, image_available = ffi.new("VkFence[1]"), ffi.new("VkSemaphore[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available); frame_fence, image_available = frame_fence[0], image_available[0]
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL); vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    input.tick(); M.current_time = M.current_time + 0.016
    local speed, look_speed = (input.key_down(input.SCANCODE_LSHIFT) and 10.0 or 3.0) * 0.016, 1.5 * 0.016
    if input.key_down(input.SCANCODE_A) then M.cam_rot[1] = M.cam_rot[1] + look_speed end; if input.key_down(input.SCANCODE_D) then M.cam_rot[1] = M.cam_rot[1] - look_speed end
    local fwd_x, fwd_z = math.sin(M.cam_rot[1]), -math.cos(M.cam_rot[1])
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] + fwd_x*speed, M.cam_pos[3] + fwd_z*speed end; if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] - fwd_x*speed, M.cam_pos[3] - fwd_z*speed end
    local view = mc.math.mat4_look_at(M.cam_pos, { M.cam_pos[1] + fwd_x, M.cam_pos[2], M.cam_pos[3] + fwd_z }, {0, 1, 0})
    local proj = mc.math.mat4_perspective(mc.math.rad(70), sw.extent.width / sw.extent.height, 0.01, 1000.0)
    local vp = mc.math.mat4_multiply(proj, view)
    local light_pos = { 20.0 * math.sin(M.current_time * 0.5), 30.0, 20.0 * math.cos(M.current_time * 0.5) }
    local light_vp = mc.math.mat4_multiply(mc.math.mat4_ortho(-50, 50, -50, 50, 0.1, 150), mc.math.mat4_look_at(light_pos, {0, 0, 0}, {0, 1, 0}))
    
    local pc = ffi.new("ScenePC")
    ffi.copy(pc.view_proj.m, vp.m, 64)
    ffi.copy(pc.light_space.m, light_vp.m, 64)
    pc.cam_pos.x, pc.cam_pos.y, pc.cam_pos.z = M.cam_pos[1], M.cam_pos[2], M.cam_pos[3]
    pc.light_pos.x, pc.light_pos.y, pc.light_pos.z = light_pos[1], light_pos[2], light_pos[3]
    pc.time = M.current_time

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    -- 1. Shadow Pass
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, image = shadow.image.handle, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT }}))
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = shadow.extent }, layerCount = 1, pDepthAttachment = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageView = shadow.image.view, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, clearValue = {depthStencil = {depth=1.0}} }) }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_shadow); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x = 0, y = 0, width = shadow.extent.width, height = shadow.extent.height, minDepth = 0, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset = {0,0}, extent = shadow.extent })); vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {v_buffer.handle}), ffi.new("VkDeviceSize[1]", {0})); vk.vkCmdBindIndexBuffer(cb, i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT32); vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, ffi.sizeof("ScenePC"), pc)
    for i = 1, #model_data.draw_calls do vk.vkCmdDrawIndexed(cb, model_data.draw_calls[i].index_count, 1, model_data.draw_calls[i].index_offset, 0, 0) end
    vk.vkCmdEndRendering(cb)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL, image = shadow.image.handle, srcAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 } }}))

    -- 2. G-Buffer Pass
    local g_imgs = {g_albedo.handle, g_normal.handle, g_mra.handle, g_worldpos.handle, g_depth.handle}
    local g_bars = ffi.new("VkImageMemoryBarrier[5]")
    for i=0,4 do g_bars[i].sType, g_bars[i].oldLayout, g_bars[i].newLayout, g_bars[i].image, g_bars[i].subresourceRange, g_bars[i].srcAccessMask, g_bars[i].dstAccessMask = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, (i < 4) and vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL or vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, g_imgs[i+1], { aspectMask = (i < 4) and vk.VK_IMAGE_ASPECT_COLOR_BIT or vk.VK_IMAGE_ASPECT_DEPTH_BIT, levelCount = 1, layerCount = 1 }, 0, (i < 4) and vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT or vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT end
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT), 0, 0, nil, 0, nil, 5, g_bars)
    
    local color_attach = ffi.new("VkRenderingAttachmentInfo[4]"); local views_g = {g_albedo.view, g_normal.view, g_mra.view, g_worldpos.view}
    for i=0,3 do color_attach[i].sType, color_attach[i].imageView, color_attach[i].imageLayout, color_attach[i].loadOp, color_attach[i].storeOp, color_attach[i].clearValue.color.float32 = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, views_g[i+1], vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ATTACHMENT_LOAD_OP_CLEAR, vk.VK_ATTACHMENT_STORE_OP_STORE, {0,0,0,1} end
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 4, pColorAttachments = color_attach, pDepthAttachment = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageView = g_depth.view, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, clearValue = {depthStencil = {depth=1.0}} }) }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_gbuffer); vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil); vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", { x = 0, y = 0, width = sw.extent.width, height = sw.extent.height, minDepth = 0, maxDepth = 1 })); vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { offset = {0,0}, extent = sw.extent })); vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {v_buffer.handle}), ffi.new("VkDeviceSize[1]", {0})); vk.vkCmdBindIndexBuffer(cb, i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    for i = 1, #model_data.draw_calls do 
        local dc = model_data.draw_calls[i]; local mat = model_data.materials[dc.material_idx + 1]; local pbr = mat.pbrMetallicRoughness or {}
        pc.base_color.x, pc.base_color.y, pc.base_color.z, pc.base_color.w = (pbr.baseColorFactor or {1,1,1,1})[1], (pbr.baseColorFactor or {1,1,1,1})[2], (pbr.baseColorFactor or {1,1,1,1})[3], (pbr.baseColorFactor or {1,1,1,1})[4]
        pc.albedo_idx, pc.normal_idx, pc.mra_idx = pbr.baseColorTexture and pbr.baseColorTexture.index or 0xFFFFFFFF, mat.normalTexture and mat.normalTexture.index or 0xFFFFFFFF, pbr.metallicRoughnessTexture and pbr.metallicRoughnessTexture.index or 0xFFFFFFFF
        vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, ffi.sizeof("ScenePC"), pc)
        vk.vkCmdDrawIndexed(cb, dc.index_count, 1, dc.index_offset, 0, 0) 
    end
    vk.vkCmdEndRendering(cb)

    -- 3. Transition to Compute
    local post_g_imgs = {g_albedo.handle, g_normal.handle, g_mra.handle, g_worldpos.handle, g_depth.handle, hdr_color.handle}
    local post_g_bars = ffi.new("VkImageMemoryBarrier[6]")
    for i=0,5 do 
        post_g_bars[i].sType, post_g_bars[i].image, post_g_bars[i].subresourceRange = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, post_g_imgs[i+1], { aspectMask = (i == 4) and vk.VK_IMAGE_ASPECT_DEPTH_BIT or vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
        if i < 4 then post_g_bars[i].oldLayout, post_g_bars[i].srcAccessMask = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT 
        elseif i == 4 then post_g_bars[i].oldLayout, post_g_bars[i].srcAccessMask = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT 
        else post_g_bars[i].oldLayout, post_g_bars[i].srcAccessMask = vk.VK_IMAGE_LAYOUT_UNDEFINED, 0 end
        post_g_bars[i].newLayout, post_g_bars[i].dstAccessMask = vk.VK_IMAGE_LAYOUT_GENERAL, bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT)
    end
    vk.vkCmdPipelineBarrier(cb, bit.bor(vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT), vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 0, nil, 6, post_g_bars)

    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_layout, 1, 1, ffi.new("VkDescriptorSet[1]", {compute_set}), 0, nil)

    -- 4. SSAO
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, ssao.pipe); vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, ffi.sizeof("ScenePC"), pc); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 32), math.ceil(sw.extent.height / 32), 1)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, ssao.pipe_blur); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 32), math.ceil(sw.extent.height / 32), 1)

    -- 5. Lighting accumulating GI (if any)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_lighting); vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, ffi.sizeof("ScenePC"), pc); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)

    -- 6. Bloom & God Rays
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, bloom.pipe_bright); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 32), math.ceil(sw.extent.height / 32), 1)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, bloom.pipe_blur); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 32), math.ceil(sw.extent.height / 32), 1)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, bloom.pipe_composite); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)
    
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, vol.pipe); vk.vkCmdPushConstants(cb, pipe_layout, pc_stages, 0, ffi.sizeof("ScenePC"), pc); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 32), math.ceil(sw.extent.height / 32), 1)

    -- 7. Post processing
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_post); vk.vkCmdDispatch(cb, math.ceil(sw.extent.width / 16), math.ceil(sw.extent.height / 16), 1)

    -- 8. Final Blit to Swapchain
    local blit_bars = ffi.new("VkImageMemoryBarrier[2]")
    blit_bars[0].sType, blit_bars[0].oldLayout, blit_bars[0].newLayout, blit_bars[0].image, blit_bars[0].srcAccessMask, blit_bars[0].dstAccessMask, blit_bars[0].subresourceRange = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_GENERAL, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, hdr_color.handle, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_ACCESS_TRANSFER_READ_BIT, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    blit_bars[1].sType, blit_bars[1].oldLayout, blit_bars[1].newLayout, blit_bars[1].image, blit_bars[1].srcAccessMask, blit_bars[1].dstAccessMask, blit_bars[1].subresourceRange = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, vk.VK_IMAGE_LAYOUT_UNDEFINED, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), 0, vk.VK_ACCESS_TRANSFER_WRITE_BIT, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 2, blit_bars)
    
    local region = ffi.new("VkImageBlit[1]"); region[0].srcSubresource, region[0].srcOffsets[1], region[0].dstSubresource, region[0].dstOffsets[1] = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }, { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, mipLevel = 0, baseArrayLayer = 0, layerCount = 1 }, { x = sw.extent.width, y = sw.extent.height, z = 1 }
    vk.vkCmdBlitImage(cb, hdr_color.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, ffi.cast("VkImage", sw.images[idx]), vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region, vk.VK_FILTER_LINEAR)
    
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = ffi.cast("VkImage", sw.images[idx]), subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = 0 }}))
    
    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
