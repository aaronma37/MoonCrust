local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
local heap = require("vulkan.heap")
local resource = require("vulkan.resource")
local image = require("vulkan.image")
local pipeline = require("vulkan.pipeline")
local descriptors = require("vulkan.descriptors")
local staging = require("vulkan.staging")

local M = {}

-- Internal State
M.heaps = {}
local state = {
    bindless = {
        layout = nil,
        pool = nil,
        set = nil,
    },
    objects = {},
    initialized = false
}

local function ensure_init()
    if state.initialized then return end
    
    -- Check for glslc once
    local have_glslc = os.execute("command -v glslc >/dev/null 2>&1")
    if not (have_glslc == true or have_glslc == 0) then
        print("WARNING: 'glslc' not found in PATH. Shader compilation will fail.")
    end

    local pd = vulkan.get_physical_device()
    local d = vulkan.get_device()
    
    -- Initialize Bindless System
    state.bindless.layout = descriptors.create_bindless_layout(d)
    state.bindless.pool = descriptors.create_bindless_pool(d)
    state.bindless.set = descriptors.allocate_sets(d, state.bindless.pool, {state.bindless.layout})[1]
    
    -- Default Heaps (Vulkan Page sizes are usually big, 256MB/128MB is a safe starting point)
    M.heaps.device = heap.new(pd, d, heap.find_memory_type(pd, 0xFFFFFFFF, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), 1024 * 1024 * 1024)
    M.heaps.host = heap.new(pd, d, heap.find_memory_type(pd, 0xFFFFFFFF, bit.bor(vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)), 1024 * 1024 * 1024)
    
    resource.init(d)
    state.initialized = true
end

local function track(obj)
    table.insert(state.objects, obj)
    return obj
end

-- 1. High-level Buffer Factory
function M.buffer(size, usage_type, initial_data, host_visible)
    ensure_init()
    local d = vulkan.get_device()
    local pd = vulkan.get_physical_device()
    local q, family = vulkan.get_queue()
    
    local usage = bit.bor(vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
    if usage_type == "vertex" then usage = bit.bor(usage, vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
    elseif usage_type == "index" then usage = bit.bor(usage, vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT)
    elseif usage_type == "indirect" then usage = bit.bor(usage, vk.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT, vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) end
    
    local info = ffi.new("VkBufferCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        size = size,
        usage = usage,
        sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE
    })
    
    local pB = ffi.new("VkBuffer[1]")
    vk.vkCreateBuffer(d, info, nil, pB)
    local handle = pB[0]
    
    local heap_obj = host_visible and M.heaps.host or M.heaps.device
    local alloc = heap_obj:malloc(size)
    if not alloc then error("mc.gpu: Buffer malloc failed for size " .. size) end
    vk.vkBindBufferMemory(d, handle, alloc.memory, alloc.offset)
    
    local obj = {
        handle = handle,
        size = size,
        allocation = alloc,
        type = "buffer",
        destroy = function(self)
            resource.free(self.handle, resource.TYPE_BUFFER)
            heap_obj:free(self.allocation)
        end
    }
    
    if initial_data then
        local st = staging.new(pd, d, M.heaps.host, size + 1024)
        st:upload_buffer(handle, initial_data, 0, q, family, size)
    end
    
    return track(obj)
end

-- 2. Image Factory
function M.image(width, height, format, usage_type)
    ensure_init()
    print("mc.gpu.image: creating " .. width .. "x" .. height .. " type=" .. usage_type)
    local d = vulkan.get_device()
    
    local is_sampled = usage_type:find("sampled") ~= nil
    local mip_levels = 1
    if is_sampled and not usage_type:find("attachment") then
        mip_levels = math.floor(math.log(math.max(width, height), 2)) + 1
    end

    local usage = bit.bor(vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT, vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
    if is_sampled then usage = bit.bor(usage, vk.VK_IMAGE_USAGE_SAMPLED_BIT) end
    if usage_type:find("storage") then usage = bit.bor(usage, vk.VK_IMAGE_USAGE_STORAGE_BIT) end
    if usage_type:find("depth") then usage = bit.bor(usage, vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) end
    if usage_type:find("color_attachment") then usage = bit.bor(usage, vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) end
    
    local handle = image.create_2d(d, width, height, format, usage, mip_levels)
    local mem_req = ffi.new("VkMemoryRequirements[1]")
    vk.vkGetImageMemoryRequirements(d, handle, mem_req)
    
    local alloc_info = ffi.new("VkMemoryAllocateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        allocationSize = mem_req[0].size,
        memoryTypeIndex = M.heaps.device.memory_type_index
    })
    local pMemory = ffi.new("VkDeviceMemory[1]")
    vk.vkAllocateMemory(d, alloc_info, nil, pMemory)
    vk.vkBindImageMemory(d, handle, pMemory[0], 0)
    
    local alloc = { memory = pMemory[0], offset = 0, is_dedicated = true }
    
    local view = image.create_view(d, handle, format, (usage_type:find("depth")) and vk.VK_IMAGE_ASPECT_DEPTH_BIT or vk.VK_IMAGE_ASPECT_COLOR_BIT, false, mip_levels)
    
    local obj = {
        handle = handle,
        view = view,
        width = width,
        height = height,
        mip_levels = mip_levels,
        allocation = alloc,
        type = "image",
        destroy = function(self)
            resource.free(self.view, resource.TYPE_VIEW)
            resource.free(self.handle, resource.TYPE_IMAGE)
            if self.allocation.is_dedicated then
                vk.vkFreeMemory(vulkan.get_device(), self.allocation.memory, nil)
            else
                M.heaps.device:free(self.allocation)
            end
        end
    }
    return track(obj)
end

function M.image_3d(width, height, depth, format, usage_type)
    ensure_init()
    local d = vulkan.get_device()
    
    local usage = bit.bor(vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT)
    if usage_type:find("storage") then usage = bit.bor(usage, vk.VK_IMAGE_USAGE_STORAGE_BIT) end
    
    local handle = image.create_3d(d, width, height, depth, format, usage)
    local mem_req = ffi.new("VkMemoryRequirements[1]")
    vk.vkGetImageMemoryRequirements(d, handle, mem_req)
    
    local alloc = M.heaps.device:malloc(tonumber(mem_req[0].size))
    if not alloc then error("mc.gpu: Image 3D malloc failed") end
    vk.vkBindImageMemory(d, handle, alloc.memory, alloc.offset)
    
    local view = image.create_view(d, handle, format, vk.VK_IMAGE_ASPECT_COLOR_BIT, true)
    
    local obj = {
        handle = handle,
        view = view,
        width = width,
        height = height,
        depth = depth,
        allocation = alloc,
        type = "image_3d",
        destroy = function(self)
            resource.free(self.view, resource.TYPE_VIEW)
            resource.free(self.handle, resource.TYPE_IMAGE)
            M.heaps.device:free(self.allocation)
        end
    }
    return track(obj)
end

-- 3. Pipeline Factory
function M.compute_pipeline(shader_path, push_const_size)
    ensure_init()
    local d = vulkan.get_device()
    
    local pc_range = nil
    if push_const_size and push_const_size > 0 then
        pc_range = ffi.new("VkPushConstantRange[1]", {{
            stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT,
            offset = 0,
            size = push_const_size
        }})
    end
    
    local layout = pipeline.create_layout(d, {state.bindless.layout}, pc_range)
    local cache = pipeline.new_cache(d)
    cache:add_compute_from_file("main", shader_path, layout)
    
    local obj = {
        handle = cache.pipelines["main"],
        layout = layout,
        cache = cache,
        type = "pipeline"
    }
    return track(obj)
end

-- 4. Sampler Factory
function M.sampler(filter_type, address_mode)
    ensure_init()
    local d = vulkan.get_device()
    return image.create_sampler(d, filter_type or vk.VK_FILTER_LINEAR, address_mode)
end

function M.get_bindless_set() ensure_init(); return state.bindless.set end
function M.get_bindless_layout() ensure_init(); return state.bindless.layout end

-- 5. Indirect Draw Helpers
function M.draw_indirect(cb, buffer_handle, offset, draw_count, stride)
    vk.vkCmdDrawIndirect(cb, buffer_handle, offset or 0, draw_count or 1, stride or 16)
end

function M.draw_indexed_indirect(cb, buffer_handle, offset, draw_count, stride)
    vk.vkCmdDrawIndexedIndirect(cb, buffer_handle, offset or 0, draw_count or 1, stride or 20)
end

function M.tick()
    resource.tick()
end

return M
