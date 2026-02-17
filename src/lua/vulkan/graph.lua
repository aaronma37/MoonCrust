local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- Resource types
M.TYPE_BUFFER = 1
M.TYPE_IMAGE = 2

local Resource = {}
Resource.__index = Resource

function Resource.new(id, type, handle, initial_state)
    local self = setmetatable({
        id = id,
        type = type,
        handle = handle,
        access = initial_state and initial_state.access or 0,
        stage = initial_state and initial_state.stage or vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
        layout = initial_state and initial_state.layout or vk.VK_IMAGE_LAYOUT_UNDEFINED, -- Only for images
    }, Resource)
    return self
end

local Pass = {}
Pass.__index = Pass

function Pass.new(name, callback)
    return setmetatable({
        name = name,
        callback = callback,
        requirements = {}
    }, Pass)
end

-- unified requirement registration
function Pass:using(resource, access, stage, layout)
    table.insert(self.requirements, {
        res = resource,
        access = access,
        stage = stage,
        layout = layout or vk.VK_IMAGE_LAYOUT_GENERAL
    })
    return self
end

local Graph = {}
Graph.__index = Graph

function M.new(device)
    return setmetatable({
        device = device,
        resources = {},
        passes = {},
        registry = {} -- persistence across frames
    }, Graph)
end

function Graph:register_resource(id, type, handle, initial_state)
    local res = Resource.new(id, type, handle, initial_state)
    self.registry[id] = res
    return res
end

function Graph:add_pass(name, callback)
    local pass = Pass.new(name, callback)
    table.insert(self.passes, pass)
    return pass
end

function Graph:reset()
    self.passes = {}
end

function Graph:get_introspection_data()
    local data = { passes = {}, resources = {} }
    for _, pass in ipairs(self.passes) do
        local p = { name = pass.name, deps = {} }
        for _, req in ipairs(pass.requirements) do
            table.insert(p.deps, {
                res_id = req.res.id,
                access = req.access,
                stage = req.stage,
                layout = req.layout
            })
        end
        table.insert(data.passes, p)
    end
    for id, res in pairs(self.registry) do
        data.resources[id] = { type = res.type }
    end
    return data
end

function Graph:execute(cb)
    for _, pass in ipairs(self.passes) do
        local buffer_barriers = {}
        local image_barriers = {}
        local src_stages = 0
        local dst_stages = 0
        
        -- 1. Analyze requirements and build barriers
        for _, req in ipairs(pass.requirements) do
            local res = req.res
            local needs_barrier = false
            
            -- Check if state changed
            if res.type == M.TYPE_BUFFER then
                if res.access ~= req.access or res.stage ~= req.stage then
                    needs_barrier = true
                    table.insert(buffer_barriers, ffi.new("VkBufferMemoryBarrier", {
                        sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
                        srcAccessMask = res.access,
                        dstAccessMask = req.access,
                                            srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                                            dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                                            buffer = ffi.cast("VkBuffer", res.handle),
                                            offset = 0,
                        
                        size = vk.VK_WHOLE_SIZE
                    }))
                end
            elseif res.type == M.TYPE_IMAGE then
                if res.layout ~= req.layout or res.access ~= req.access or res.stage ~= req.stage then
                    needs_barrier = true
                    table.insert(image_barriers, ffi.new("VkImageMemoryBarrier", {
                        sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                        srcAccessMask = res.access,
                        dstAccessMask = req.access,
                        oldLayout = res.layout,
                        newLayout = req.layout,
                        srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                        dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                        image = ffi.cast("VkImage", res.handle),
                        subresourceRange = {
                            aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
                            baseMipLevel = 0,
                            levelCount = 1,
                            baseArrayLayer = 0,
                            layerCount = 1
                        }
                    }))
                end
            end
            
            if needs_barrier then
                src_stages = bit.bor(src_stages, res.stage)
                dst_stages = bit.bor(dst_stages, req.stage)
                
                -- Update tracking state
                res.access = req.access
                res.stage = req.stage
                res.layout = req.layout
            end
        end

        -- 2. Emit barriers if needed
        if #buffer_barriers > 0 or #image_barriers > 0 then
            -- Sanitize stages
            if src_stages == 0 then src_stages = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT end
            if dst_stages == 0 then dst_stages = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT end

            local pBufs = nil
            if #buffer_barriers > 0 then
                pBufs = ffi.new("VkBufferMemoryBarrier[?]", #buffer_barriers, buffer_barriers)
            end

            local pImgs = nil
            if #image_barriers > 0 then
                pImgs = ffi.new("VkImageMemoryBarrier[?]", #image_barriers, image_barriers)
            end

            vk.vkCmdPipelineBarrier(
                cb,
                src_stages,
                dst_stages,
                0,
                0, nil,
                #buffer_barriers, pBufs,
                #image_barriers, pImgs
            )
        end

        -- 3. Execute pass
        pass.callback(cb)
    end
end

return M
