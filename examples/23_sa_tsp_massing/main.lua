local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local bit = require("bit")

local M = {
    temp = 2.3,
    iter = 0,
    best_len = 0.0,
    current_len = 0.0,
    last_report = 0
}

local CITY_COUNT = 220
local CHAIN_COUNT = 512
local STEPS_PER_DISPATCH = 24
local INITIAL_TEMP = 2.3
local MIN_TEMP = 0.0007
local COOLING = 0.9996

local BUF_CITY_DRAW = 0
local BUF_CURR_DRAW = 1
local BUF_BEST_DRAW = 2
local BUF_TOUR_CURR = 3
local BUF_LEN_CURR = 4
local BUF_TOUR_BEST = 5
local BUF_LEN_BEST = 6
local BUF_RNG = 7

local device, queue, graphics_family, sw
local bindless_set, layout_graph, layout_compute
local pipe_points, pipe_lines, pipe_anneal
local image_available, cb, frame_fence

local cities = {}
local city_ptr, current_ptr, best_ptr
local tour_curr_ptr, tour_best_ptr, rng_ptr
local len_curr_ptr, len_best_ptr
local city_count, current_count, best_count = 0, 0, 0

local function read_text(path)
    local f = io.open(path, "r")
    if not f then
        error("Failed to read " .. tostring(path))
    end
    local t = f:read("*all")
    f:close()
    return t
end

local function set_draw_point(ptr, i, x, y, z, size, r, g, b, a)
    ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].size = x, y, z, size
    ptr[i].r, ptr[i].g, ptr[i].b, ptr[i].a = r, g, b, a
end

local function dist(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function tour_length_from_ptr(base, city_count_local)
    local total = 0.0
    for i = 0, city_count_local - 1 do
        local ia = tour_curr_ptr[base + i]
        local ib = tour_curr_ptr[base + ((i + 1) % city_count_local)]
        local a = cities[ia + 1]
        local b = cities[ib + 1]
        total = total + dist(a.x, a.y, b.x, b.y)
    end
    return total
end

local function build_route_draw(ptr, route_ptr, chain_idx, r, g, b, a)
    local base = chain_idx * CITY_COUNT
    for i = 0, CITY_COUNT do
        local city_idx = route_ptr[base + (i % CITY_COUNT)]
        local c = cities[city_idx + 1]
        set_draw_point(ptr, i, c.x, c.y, 0.0, 2.2, r, g, b, a)
    end
end

local function refresh_visual_routes()
    local best_idx = 0
    local current_idx = 0
    local best_len = len_best_ptr[0]
    local current_len = len_curr_ptr[0]
    for i = 1, CHAIN_COUNT - 1 do
        if len_best_ptr[i] < best_len then
            best_len = len_best_ptr[i]
            best_idx = i
        end
        if len_curr_ptr[i] < current_len then
            current_len = len_curr_ptr[i]
            current_idx = i
        end
    end

    M.best_len = best_len
    M.current_len = current_len
    build_route_draw(best_ptr, tour_best_ptr, best_idx, 0.25, 1.0, 0.45, 0.95)
    build_route_draw(current_ptr, tour_curr_ptr, current_idx, 1.0, 0.44, 0.25, 0.60)
    current_count = CITY_COUNT + 1
    best_count = CITY_COUNT + 1
end

local function init_problem()
    math.randomseed(os.time())
    cities = {}
    for i = 1, CITY_COUNT do
        cities[i] = {
            x = math.random() * 1.7 - 0.85,
            y = math.random() * 1.7 - 0.85
        }
    end

    city_count = CITY_COUNT
    for i = 1, CITY_COUNT do
        local c = cities[i]
        set_draw_point(city_ptr, i - 1, c.x, c.y, 0.0, 4.8, 0.92, 0.92, 0.95, 1.0)
    end

    local temp_route = {}
    for i = 1, CITY_COUNT do
        temp_route[i] = i - 1
    end

    for chain = 0, CHAIN_COUNT - 1 do
        for i = CITY_COUNT, 2, -1 do
            local j = math.random(1, i)
            temp_route[i], temp_route[j] = temp_route[j], temp_route[i]
        end
        local base = chain * CITY_COUNT
        for i = 0, CITY_COUNT - 1 do
            local city_idx = temp_route[i + 1]
            tour_curr_ptr[base + i] = city_idx
            tour_best_ptr[base + i] = city_idx
        end
        local l = tour_length_from_ptr(base, CITY_COUNT)
        len_curr_ptr[chain] = l
        len_best_ptr[chain] = l
        rng_ptr[chain] = bit.tobit(1469598103 + chain * 1103515245)
    end

    M.temp = INITIAL_TEMP
    refresh_visual_routes()
end

function M.init()
    print("Example 23: GPU Simulated Annealing TSP")

    local instance = vulkan.get_instance()
    local physical_device = vulkan.get_physical_device()
    device = vulkan.get_device()
    queue, graphics_family = vulkan.get_queue()
    sw = swapchain.new(instance, physical_device, device, _G._SDL_WINDOW)

    ffi.cdef[[
        typedef struct DrawPoint {
            float x, y, z, size;
            float r, g, b, a;
        } DrawPoint;
        typedef struct DrawPC {
            float mvp[16];
            uint32_t mode;
            uint32_t count;
            uint32_t start;
            uint32_t pad0;
        } DrawPC;
        typedef struct AnnealPC {
            float temp;
            uint32_t iter;
            uint32_t city_count;
            uint32_t chain_count;
            uint32_t steps;
        } AnnealPC;
    ]]

    local draw_type_size = ffi.sizeof("DrawPoint")
    local city_buf_obj = mc.buffer(draw_type_size * CITY_COUNT, "storage", nil, true)
    local current_buf_obj = mc.buffer(draw_type_size * (CITY_COUNT + 1), "storage", nil, true)
    local best_buf_obj = mc.buffer(draw_type_size * (CITY_COUNT + 1), "storage", nil, true)

    local tour_elem_count = CHAIN_COUNT * CITY_COUNT
    local tour_buf_size = tour_elem_count * ffi.sizeof("uint32_t")
    local len_buf_size = CHAIN_COUNT * ffi.sizeof("float")
    local rng_buf_size = CHAIN_COUNT * ffi.sizeof("uint32_t")
    local tour_curr_buf_obj = mc.buffer(tour_buf_size, "storage", nil, true)
    local len_curr_buf_obj = mc.buffer(len_buf_size, "storage", nil, true)
    local tour_best_buf_obj = mc.buffer(tour_buf_size, "storage", nil, true)
    local len_best_buf_obj = mc.buffer(len_buf_size, "storage", nil, true)
    local rng_buf_obj = mc.buffer(rng_buf_size, "storage", nil, true)

    city_ptr = ffi.cast("DrawPoint*", city_buf_obj.allocation.ptr)
    current_ptr = ffi.cast("DrawPoint*", current_buf_obj.allocation.ptr)
    best_ptr = ffi.cast("DrawPoint*", best_buf_obj.allocation.ptr)
    tour_curr_ptr = ffi.cast("uint32_t*", tour_curr_buf_obj.allocation.ptr)
    tour_best_ptr = ffi.cast("uint32_t*", tour_best_buf_obj.allocation.ptr)
    len_curr_ptr = ffi.cast("float*", len_curr_buf_obj.allocation.ptr)
    len_best_ptr = ffi.cast("float*", len_best_buf_obj.allocation.ptr)
    rng_ptr = ffi.cast("uint32_t*", rng_buf_obj.allocation.ptr)

    bindless_set = mc.gpu.get_bindless_set()
    local bl_layout = mc.gpu.get_bindless_layout()

    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, city_buf_obj.handle, 0, draw_type_size * CITY_COUNT, BUF_CITY_DRAW)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, current_buf_obj.handle, 0, draw_type_size * (CITY_COUNT + 1), BUF_CURR_DRAW)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, best_buf_obj.handle, 0, draw_type_size * (CITY_COUNT + 1), BUF_BEST_DRAW)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, tour_curr_buf_obj.handle, 0, tour_buf_size, BUF_TOUR_CURR)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, len_curr_buf_obj.handle, 0, len_buf_size, BUF_LEN_CURR)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, tour_best_buf_obj.handle, 0, tour_buf_size, BUF_TOUR_BEST)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, len_best_buf_obj.handle, 0, len_buf_size, BUF_LEN_BEST)
    descriptors.update_buffer_set(device, bindless_set, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, rng_buf_obj.handle, 0, rng_buf_size, BUF_RNG)

    layout_graph = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{
        stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT,
        offset = 0,
        size = ffi.sizeof("DrawPC")
    }}))
    layout_compute = pipeline.create_layout(device, { bl_layout }, ffi.new("VkPushConstantRange[1]", {{
        stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT,
        offset = 0,
        size = ffi.sizeof("AnnealPC")
    }}))

    local vert = shader.create_module(device, shader.compile_glsl(read_text("examples/23_sa_tsp_massing/route.vert"), vk.VK_SHADER_STAGE_VERTEX_BIT))
    local frag = shader.create_module(device, shader.compile_glsl(read_text("examples/23_sa_tsp_massing/route.frag"), vk.VK_SHADER_STAGE_FRAGMENT_BIT))
    local comp = shader.create_module(device, shader.compile_glsl(read_text("examples/23_sa_tsp_massing/anneal.comp"), vk.VK_SHADER_STAGE_COMPUTE_BIT))
    pipe_lines = pipeline.create_graphics_pipeline(device, layout_graph, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP, additive = true })
    pipe_points = pipeline.create_graphics_pipeline(device, layout_graph, vert, frag, { topology = vk.VK_PRIMITIVE_TOPOLOGY_POINT_LIST, additive = true })
    pipe_anneal = pipeline.create_compute_pipeline(device, layout_compute, comp)

    local p_sem = ffi.new("VkSemaphore[1]")
    local sem_info = ffi.new("VkSemaphoreCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO })
    vk.vkCreateSemaphore(device, sem_info, nil, p_sem)
    image_available = p_sem[0]

    local pool = command.create_pool(device, graphics_family)
    cb = command.allocate_buffers(device, pool, 1)[1]

    local p_fence = ffi.new("VkFence[1]")
    vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        flags = vk.VK_FENCE_CREATE_SIGNALED_BIT
    }), nil, p_fence)
    frame_fence = p_fence[0]

    init_problem()
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", { frame_fence }), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", { frame_fence }))

    refresh_visual_routes()
    if M.iter - M.last_report >= 200000 then
        M.last_report = M.iter
        print(string.format("iter=%d chains=%d temp=%.5f current=%.4f best=%.4f", M.iter, CHAIN_COUNT, M.temp, M.current_len, M.best_len))
    end

    local idx = sw:acquire_next_image(image_available)
    if idx == nil then
        return
    end

    vk.vkResetCommandBuffer(cb, 0)
    vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))

    local anneal_pc = ffi.new("AnnealPC")
    anneal_pc.temp = M.temp
    anneal_pc.iter = M.iter
    anneal_pc.city_count = CITY_COUNT
    anneal_pc.chain_count = CHAIN_COUNT
    anneal_pc.steps = STEPS_PER_DISPATCH

    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe_anneal)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout_compute, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)
    vk.vkCmdPushConstants(cb, layout_compute, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, ffi.sizeof("AnnealPC"), anneal_pc)
    vk.vkCmdDispatch(cb, math.ceil(CHAIN_COUNT / 64), 1, 1)

    local to_host_bar = ffi.new("VkMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
        srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT,
        dstAccessMask = vk.VK_ACCESS_HOST_READ_BIT
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_HOST_BIT, 0, 1, to_host_bar, 0, nil, 0, nil)

    local to_vertex_bar = ffi.new("VkMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER,
        srcAccessMask = vk.VK_ACCESS_HOST_WRITE_BIT,
        dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_HOST_BIT, vk.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, 0, 1, to_vertex_bar, 0, nil, 0, nil)

    local bar = ffi.new("VkImageMemoryBarrier[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        oldLayout = vk.VK_IMAGE_LAYOUT_UNDEFINED,
        newLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        image = ffi.cast("VkImage", sw.images[idx]),
        subresourceRange = {
            aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            levelCount = 1,
            layerCount = 1
        },
        dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0, nil, 0, nil, 1, bar)

    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO
    color_attach[0].imageView = ffi.cast("VkImageView", sw.views[idx])
    color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR
    color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE
    color_attach[0].clearValue.color.float32 = { 0.02, 0.02, 0.03, 1.0 }

    local render_info = ffi.new("VkRenderingInfo", {
        sType = vk.VK_STRUCTURE_TYPE_RENDERING_INFO,
        renderArea = { extent = sw.extent },
        layerCount = 1,
        colorAttachmentCount = 1,
        pColorAttachments = color_attach
    })
    vk.vkCmdBeginRendering(cb, render_info)
    vk.vkCmdSetViewport(cb, 0, 1, ffi.new("VkViewport", {
        width = sw.extent.width,
        height = sw.extent.height,
        minDepth = 0.0,
        maxDepth = 1.0
    }))
    vk.vkCmdSetScissor(cb, 0, 1, ffi.new("VkRect2D", { extent = sw.extent }))

    local mvp = mc.mat4_identity()
    local pc = ffi.new("DrawPC")
    for i = 1, 16 do
        pc.mvp[i - 1] = mvp.m[i - 1]
    end
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, layout_graph, 0, 1, ffi.new("VkDescriptorSet[1]", { bindless_set }), 0, nil)

    pc.mode = 2
    pc.count = best_count
    pc.start = 0
    vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
    vk.vkCmdDraw(cb, best_count, 1, 0, 0)

    pc.mode = 1
    pc.count = current_count
    pc.start = 0
    vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_lines)
    vk.vkCmdDraw(cb, current_count, 1, 0, 0)

    pc.mode = 0
    pc.count = city_count
    pc.start = 0
    vk.vkCmdPushConstants(cb, layout_graph, vk.VK_SHADER_STAGE_VERTEX_BIT, 0, ffi.sizeof("DrawPC"), pc)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_points)
    vk.vkCmdDraw(cb, city_count, 1, 0, 0)

    vk.vkCmdEndRendering(cb)

    bar[0].oldLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    bar[0].newLayout = vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    bar[0].srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
    bar[0].dstAccessMask = 0
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar)
    vk.vkEndCommandBuffer(cb)

    local submit_info = ffi.new("VkSubmitInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        waitSemaphoreCount = 1,
        pWaitSemaphores = ffi.new("VkSemaphore[1]", { image_available }),
        pWaitDstStageMask = ffi.new("VkPipelineStageFlags[1]", { vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT }),
        commandBufferCount = 1,
        pCommandBuffers = ffi.new("VkCommandBuffer[1]", { cb }),
        signalSemaphoreCount = 1,
        pSignalSemaphores = ffi.new("VkSemaphore[1]", { sw.semaphores[idx] })
    })
    vk.vkQueueSubmit(queue, 1, submit_info, frame_fence)
    sw:present(queue, idx, sw.semaphores[idx])

    M.iter = M.iter + STEPS_PER_DISPATCH * CHAIN_COUNT
    M.temp = M.temp * COOLING
    if M.temp < MIN_TEMP then
        M.temp = INITIAL_TEMP * 0.9
    end
end

return M
