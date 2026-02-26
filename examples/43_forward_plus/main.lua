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
local render_graph = require("vulkan.graph")

local M = { cam_pos = {0, 2, 5}, cam_rot = {0, 0}, current_time = 0, frame_count = 0, last_fps_time = os.clock() }
local device, queue, graphics_family, sw, graph
local bindless_set, cb, frame_fence, image_available
local model_data, v_buffer, i_buffer
local textures = {}

-- Constants
local CLUSTER_X, CLUSTER_Y, CLUSTER_Z = 16, 9, 24
local MAX_LIGHTS = 1024
local MAX_LIGHT_INDICES = 100 * CLUSTER_X * CLUSTER_Y * CLUSTER_Z

ffi.cdef[[
    typedef struct ClusterAABB { float min[4], max[4]; } ClusterAABB;
    typedef struct Light { float pos_radius[4], color[4]; } Light;
    typedef struct ClusterItem { uint32_t offset, count; } ClusterItem;

    typedef struct BuildPC {
        float inv_proj[16];
        float screen_size[2];
        float z_near, z_far;
        uint32_t cluster_x, cluster_y, cluster_z;
    } BuildPC;

    typedef struct CullPC {
        float view[16];
        uint32_t total_lights;
    } CullPC;

    typedef struct ForwardPC {
        float view_proj[16];
        float view[16];
        float cam_pos[4];
        float screen_size[2];
        float z_near, z_far;
        uint32_t cluster_x, cluster_y, cluster_z;
        uint32_t albedo_idx;
    } ForwardPC;
]]

local res = {}
local pipes = {}
local gpu_objs = {}

function M.init()
    math.randomseed(os.time())
    print("Example 43: Clustered Forward Rendering (Forward+)")
    local instance, physical_device = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)
    
    graph = render_graph.new(device)
    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()

    model_data = loader.load("examples/30_sponza_gltf/Sponza/glTF/Sponza.gltf")
    v_buffer = mc.buffer(model_data.vertex_count * 8 * 4, "vertex", model_data.vertices)
    i_buffer = mc.buffer(model_data.index_count * 4, "index", model_data.indices)

    local sampler = mc.gpu.sampler(vk.VK_FILTER_LINEAR)
    local staging = require("vulkan.staging").new(physical_device, device, mc.gpu.heaps.host, 64 * 1024 * 1024)
    
    -- Default Textures
    local white_pixels = ffi.new("uint8_t[4]", {255, 255, 255, 255})
    local default_img = mc.gpu.image(1, 1, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
    staging:upload_image(default_img.handle, 1, 1, white_pixels, queue, graphics_family, 4)
    for i = 0, 1023 do descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, default_img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, i) end

    -- Load Sponza Textures
    for i, tex in ipairs(model_data.textures or {}) do
        local img_info = model_data.images[tex.source + 1]; local tex_path = (model_data.base_dir .. img_info.uri)
        local pixels, tw, th = loader.load_image(tex_path)
        if pixels then 
            local gpu_img = mc.gpu.image(tw, th, vk.VK_FORMAT_R8G8B8A8_UNORM, "sampled")
            staging:upload_image(gpu_img.handle, tw, th, pixels, queue, graphics_family, tw * th * 4, gpu_img.mip_levels)
            descriptors.update_image_set(device, bindless_set, 1, vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, gpu_img.view, sampler, vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, i-1)
            textures[i] = gpu_img 
        end
    end

    -- GPU Resources
    gpu_objs.cluster_aabb = mc.gpu.buffer(ffi.sizeof("ClusterAABB") * CLUSTER_X * CLUSTER_Y * CLUSTER_Z, "storage")
    gpu_objs.lights = mc.gpu.buffer(ffi.sizeof("Light") * MAX_LIGHTS, "storage", nil, true) -- Host visible
    gpu_objs.cluster_items = mc.gpu.buffer(ffi.sizeof("ClusterItem") * CLUSTER_X * CLUSTER_Y * CLUSTER_Z, "storage")
    gpu_objs.light_indices = mc.gpu.buffer(4 * MAX_LIGHT_INDICES, "storage")
    gpu_objs.global_counter = mc.gpu.buffer(4, "storage")
    
    local w, h = sw.extent.width, sw.extent.height
    gpu_objs.depth = mc.gpu.image(w, h, vk.VK_FORMAT_D32_SFLOAT, "depth")
    gpu_objs.color = mc.gpu.image(w, h, vk.VK_FORMAT_R16G16B16A16_SFLOAT, "storage_color_attachment")

    res.cluster_aabb = graph:register_resource("ClusterAABB", render_graph.TYPE_BUFFER, gpu_objs.cluster_aabb.handle)
    res.lights = graph:register_resource("Lights", render_graph.TYPE_BUFFER, gpu_objs.lights.handle)
    res.cluster_items = graph:register_resource("ClusterItems", render_graph.TYPE_BUFFER, gpu_objs.cluster_items.handle)
    res.light_indices = graph:register_resource("LightIndices", render_graph.TYPE_BUFFER, gpu_objs.light_indices.handle)
    res.global_counter = graph:register_resource("GlobalCounter", render_graph.TYPE_BUFFER, gpu_objs.global_counter.handle)
    res.depth = graph:register_resource("DepthBuffer", render_graph.TYPE_IMAGE, gpu_objs.depth.handle)
    res.color = graph:register_resource("ColorBuffer", render_graph.TYPE_IMAGE, gpu_objs.color.handle)

    -- Descriptor Sets
    local cull_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
    })
    pipes.cull_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }}), {cull_layout})[1]
    descriptors.update_buffer_set(device, pipes.cull_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.cluster_aabb.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.cull_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.lights.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.cull_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.cluster_items.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.cull_set, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.light_indices.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.cull_set, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.global_counter.handle, 0, vk.VK_WHOLE_SIZE, 0)

    local forward_layout = descriptors.create_layout(device, {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_FRAGMENT_BIT },
    })
    pipes.forward_set = descriptors.allocate_sets(device, descriptors.create_pool(device, {{ type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, count = 10 }}), {forward_layout})[1]
    descriptors.update_buffer_set(device, pipes.forward_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.lights.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.forward_set, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.cluster_items.handle, 0, vk.VK_WHOLE_SIZE, 0)
    descriptors.update_buffer_set(device, pipes.forward_set, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, gpu_objs.light_indices.handle, 0, vk.VK_WHOLE_SIZE, 0)

    -- Pipelines
    local pc_stages = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT)
    pipes.layout_build = pipeline.create_layout(device, {cull_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_stages, offset = 0, size = ffi.sizeof("BuildPC") }}))
    pipes.build = pipeline.create_compute_pipeline(device, pipes.layout_build, shader.create_module(device, shader.compile_glsl(io.open("examples/43_forward_plus/shaders/cluster_build.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    pipes.layout_cull = pipeline.create_layout(device, {cull_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_stages, offset = 0, size = ffi.sizeof("CullPC") }}))
    pipes.cull = pipeline.create_compute_pipeline(device, pipes.layout_cull, shader.create_module(device, shader.compile_glsl(io.open("examples/43_forward_plus/shaders/light_cull.comp"):read("*all"), vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    pipes.layout_forward = pipeline.create_layout(device, {bl_layout, forward_layout}, ffi.new("VkPushConstantRange[1]", {{ stageFlags = pc_stages, offset = 0, size = ffi.sizeof("ForwardPC") }}))
    local v_binding = ffi.new("VkVertexInputBindingDescription[1]", {{ binding = 0, stride = 8 * 4, inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX }})
    local v_attribs = ffi.new("VkVertexInputAttributeDescription[3]", {
        { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 0 },
        { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32B32_SFLOAT, offset = 3 * 4 },
        { location = 2, binding = 0, format = vk.VK_FORMAT_R32G32_SFLOAT, offset = 6 * 4 }
    })
    pipes.forward = pipeline.create_graphics_pipeline(device, pipes.layout_forward, shader.create_module(device, shader.compile_glsl(io.open("examples/43_forward_plus/shaders/forward.vert"):read("*all"), vk.VK_SHADER_STAGE_VERTEX_BIT)), shader.create_module(device, shader.compile_glsl(io.open("examples/43_forward_plus/shaders/forward.frag"):read("*all"), vk.VK_SHADER_STAGE_FRAGMENT_BIT)), { 
        depth_test = true, depth_write = true, 
        color_formats = {vk.VK_FORMAT_R16G16B16A16_SFLOAT}, 
        vertex_binding = v_binding, vertex_attributes = v_attribs, vertex_attribute_count = 3 
    })

    cb = command.allocate_buffers(device, command.create_pool(device, graphics_family), 1)[1]
    frame_fence, image_available = ffi.new("VkFence[1]"), ffi.new("VkSemaphore[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT}), nil, frame_fence)
    vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", {sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO}), nil, image_available)
    frame_fence, image_available = frame_fence[0], image_available[0]

    -- Initialize Random Lights
    M.lights_data = ffi.new("Light[?]", MAX_LIGHTS)
    for i = 0, MAX_LIGHTS - 1 do
        local x, y, z = (math.random() - 0.5) * 40.0, math.random() * 10.0, (math.random() - 0.5) * 40.0
        M.lights_data[i].pos_radius[0], M.lights_data[i].pos_radius[1], M.lights_data[i].pos_radius[2] = x, y, z
        M.lights_data[i].pos_radius[3] = 2.0 + math.random() * 3.0 -- Radius
        M.lights_data[i].color[0], M.lights_data[i].color[1], M.lights_data[i].color[2] = math.random(), math.random(), math.random()
        M.lights_data[i].color[3] = 1.0 -- Intensity
    end
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local idx = sw:acquire_next_image(image_available); if idx == nil then return end
    input.tick(); M.current_time = M.current_time + 0.016
    M.frame_count = M.frame_count + 1
    if M.frame_count % 60 == 0 then
        local now = os.clock()
        local dt = now - M.last_fps_time
        print(string.format("Forward+ FPS: %.2f (%.2fms)", 60/dt, (dt/60)*1000))
        M.last_fps_time = now
    end

    -- Movement
    local speed, look_speed = (input.key_down(input.SCANCODE_LSHIFT) and 10.0 or 3.0) * 0.016, 1.5 * 0.016
    if input.key_down(input.SCANCODE_A) then M.cam_rot[1] = M.cam_rot[1] + look_speed end
    if input.key_down(input.SCANCODE_D) then M.cam_rot[1] = M.cam_rot[1] - look_speed end
    local fwd_x, fwd_z = math.sin(M.cam_rot[1]), -math.cos(M.cam_rot[1])
    if input.key_down(input.SCANCODE_W) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] + fwd_x*speed, M.cam_pos[3] + fwd_z*speed end
    if input.key_down(input.SCANCODE_S) then M.cam_pos[1], M.cam_pos[3] = M.cam_pos[1] - fwd_x*speed, M.cam_pos[3] - fwd_z*speed end

    -- Camera & PC
    local view = mc.math.mat4_look_at(M.cam_pos, { M.cam_pos[1] + fwd_x, M.cam_pos[2], M.cam_pos[3] + fwd_z }, {0, 1, 0})
    local proj = mc.math.mat4_perspective(mc.math.rad(70), sw.extent.width / sw.extent.height, 0.1, 100.0)
    local inv_proj = mc.math.mat4_inverse(proj)
    local vp = mc.math.mat4_multiply(proj, view)

    -- Update Lights to View Space
    local view_lights = ffi.new("Light[?]", MAX_LIGHTS)
    for i = 0, MAX_LIGHTS - 1 do
        local x = M.lights_data[i].pos_radius[0] + 2.0 * math.sin(M.current_time + i)
        local y = M.lights_data[i].pos_radius[1]
        local z = M.lights_data[i].pos_radius[2] + 2.0 * math.cos(M.current_time + i)
        local world_pos = { x, y, z, 1.0 }
        local v_pos = mc.math.mat4_vec4_multiply(view, world_pos)
        view_lights[i].pos_radius[0], view_lights[i].pos_radius[1], view_lights[i].pos_radius[2] = v_pos[1], v_pos[2], v_pos[3]
        view_lights[i].pos_radius[3] = M.lights_data[i].pos_radius[3]
        ffi.copy(view_lights[i].color, M.lights_data[i].color, 16)
    end
    gpu_objs.lights:upload(view_lights)

    local b_pc = ffi.new("BuildPC")
    ffi.copy(b_pc.inv_proj, inv_proj.m, 64)
    b_pc.screen_size[0], b_pc.screen_size[1] = sw.extent.width, sw.extent.height
    b_pc.z_near, b_pc.z_far = 0.1, 100.0
    b_pc.cluster_x, b_pc.cluster_y, b_pc.cluster_z = CLUSTER_X, CLUSTER_Y, CLUSTER_Z

    local c_pc = ffi.new("CullPC")
    ffi.copy(c_pc.view, view.m, 64)
    c_pc.total_lights = MAX_LIGHTS

    local f_pc = ffi.new("ForwardPC")
    ffi.copy(f_pc.view_proj, vp.m, 64)
    ffi.copy(f_pc.view, view.m, 64)
    f_pc.cam_pos[0], f_pc.cam_pos[1], f_pc.cam_pos[2] = M.cam_pos[1], M.cam_pos[2], M.cam_pos[3]
    f_pc.screen_size[0], f_pc.screen_size[1] = sw.extent.width, sw.extent.height
    f_pc.z_near, f_pc.z_far = 0.1, 100.0
    f_pc.cluster_x, f_pc.cluster_y, f_pc.cluster_z = CLUSTER_X, CLUSTER_Y, CLUSTER_Z

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    
    graph:reset()
    graph:add_pass("BuildClusters", function(cmd)
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipes.build)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipes.layout_build, 0, 1, ffi.new("VkDescriptorSet[1]", {pipes.cull_set}), 0, nil)
        vk.vkCmdPushConstants(cmd, pipes.layout_build, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("BuildPC"), b_pc)
        vk.vkCmdDispatch(cmd, CLUSTER_X, CLUSTER_Y, CLUSTER_Z)
    end):using(res.cluster_aabb, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

    graph:add_pass("LightCull", function(cmd)
        vk.vkCmdFillBuffer(cmd, ffi.cast("VkBuffer", res.global_counter.handle), 0, 4, 0)
        
        -- Barrier to ensure fill is done before atomicAdd in compute
        local bar = ffi.new("VkBufferMemoryBarrier[1]", {{
            sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
            srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT,
            dstAccessMask = bit.bor(vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_ACCESS_SHADER_WRITE_BIT),
            srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
            dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
            buffer = ffi.cast("VkBuffer", res.global_counter.handle),
            offset = 0,
            size = 4
        }})
        vk.vkCmdPipelineBarrier(cmd, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, nil, 1, bar, 0, nil)

        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipes.cull)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipes.layout_cull, 0, 1, ffi.new("VkDescriptorSet[1]", {pipes.cull_set}), 0, nil)
        vk.vkCmdPushConstants(cmd, pipes.layout_cull, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT), 0, ffi.sizeof("CullPC"), c_pc)
        vk.vkCmdDispatch(cmd, CLUSTER_X, CLUSTER_Y, CLUSTER_Z)
    end):using(res.cluster_aabb, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res.lights, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res.cluster_items, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res.light_indices, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
       :using(res.global_counter, vk.VK_ACCESS_TRANSFER_WRITE_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT)

    graph:add_pass("ForwardRender", function(cmd)
        local color_attach = ffi.new("VkRenderingAttachmentInfo[1]", {{ 
            sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, 
            imageView = gpu_objs.color.view, 
            imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, 
            loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, 
            clearValue = {color={float32={0.01,0.01,0.02,1}}} 
        }})
        vk.vkCmdBeginRendering(cmd, ffi.new("VkRenderingInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea = { extent = sw.extent }, layerCount = 1, colorAttachmentCount = 1, pColorAttachments = color_attach, pDepthAttachment = ffi.new("VkRenderingAttachmentInfo", { sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO, imageView = gpu_objs.depth.view, imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL, loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR, storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE, clearValue = {depthStencil = {depth=1.0}} }) }))
        vk.vkCmdBindPipeline(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipes.forward)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipes.layout_forward, 0, 1, ffi.new("VkDescriptorSet[1]", {bindless_set}), 0, nil)
        vk.vkCmdBindDescriptorSets(cmd, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipes.layout_forward, 1, 1, ffi.new("VkDescriptorSet[1]", {pipes.forward_set}), 0, nil)
        vk.vkCmdSetViewport(cmd, 0, 1, ffi.new("VkViewport", { x = 0, y = 0, width = sw.extent.width, height = sw.extent.height, minDepth = 0, maxDepth = 1 }))
        vk.vkCmdSetScissor(cmd, 0, 1, ffi.new("VkRect2D", { offset = {0,0}, extent = sw.extent }))
        vk.vkCmdBindVertexBuffers(cmd, 0, 1, ffi.new("VkBuffer[1]", {v_buffer.handle}), ffi.new("VkDeviceSize[1]", {0}))
        vk.vkCmdBindIndexBuffer(cmd, i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT32)
        
        local pc_stages = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT, vk.VK_SHADER_STAGE_COMPUTE_BIT)
        for i = 1, #model_data.draw_calls do 
            local dc = model_data.draw_calls[i]; local mat = model_data.materials[dc.material_idx + 1]; local pbr = mat.pbrMetallicRoughness or {}
            f_pc.albedo_idx = pbr.baseColorTexture and pbr.baseColorTexture.index or 0xFFFFFFFF
            vk.vkCmdPushConstants(cmd, pipes.layout_forward, pc_stages, 0, ffi.sizeof("ForwardPC"), f_pc)
            vk.vkCmdDrawIndexed(cmd, dc.index_count, 1, dc.index_offset, 0, 0) 
        end
        vk.vkCmdEndRendering(cmd)
    end):using(res.depth, vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL)
       :using(res.color, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
       :using(res.cluster_items, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT)
       :using(res.light_indices, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT)

    graph:execute(cb)

    local sw_img = ffi.cast("VkImage", sw.images[idx])
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nil, 0, nil, 2, ffi.new("VkImageMemoryBarrier[2]", {
        { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, image = gpu_objs.color.handle, srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_TRANSFER_READ_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } },
        { sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED, newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, image = sw_img, srcAccessMask = 0, dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 } }
    }))
    local region = ffi.new("VkImageBlit[1]", {{ srcSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, layerCount = 1 }, srcOffsets = {{0,0,0}, {sw.extent.width, sw.extent.height, 1}}, dstSubresource = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, layerCount = 1 }, dstOffsets = {{0,0,0}, {sw.extent.width, sw.extent.height, 1}} }})
    vk.vkCmdBlitImage(cb, gpu_objs.color.handle, vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, sw_img, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, region, vk.VK_FILTER_LINEAR)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, ffi.new("VkImageMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image = sw_img, subresourceRange = { aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT, dstAccessMask = 0 }}))

    vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores = ffi.new("VkSemaphore[1]", {image_available}), pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers = ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount = 1, pSignalSemaphores = ffi.new("VkSemaphore[1]", {sw.semaphores[idx]}) }), frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])
end

return M
