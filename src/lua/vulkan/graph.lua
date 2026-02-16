local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

-- Resource types
M.TYPE_BUFFER = 1
M.TYPE_IMAGE = 2

local Resource = {}
Resource.__index = Resource

function Resource.new(id, type, handle, initial_access, initial_stage)
    return setmetatable({
        id = id,
        type = type,
        handle = handle,
        access = initial_access or 0,
        stage = initial_stage or vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT,
        layout = vk.VK_IMAGE_LAYOUT_UNDEFINED -- Only for images
    }, Resource)
end

local Pass = {}
Pass.__index = Pass

function Pass.new(name, callback)
    return setmetatable({
        name = name,
        callback = callback,
        reads = {},
        writes = {}
    }, Pass)
end

function Pass:read(resource, access, stage)
    table.insert(self.reads, { res = resource, access = access, stage = stage })
    return self
end

function Pass:write(resource, access, stage)
    table.insert(self.writes, { res = resource, access = access, stage = stage })
    return self
end

local Graph = {}
Graph.__index = Graph

function M.new(device)
    return setmetatable({
        device = device,
        resources = {},
        passes = {}
    }, Graph)
end

function Graph:add_resource(id, type, handle, initial_access, initial_stage)
    local res = Resource.new(id, type, handle, initial_access, initial_stage)
    self.resources[id] = res
    return res
end

function Graph:add_pass(name, callback)
    local pass = Pass.new(name, callback)
    table.insert(self.passes, pass)
    return pass
end

function Graph:execute(cb, encoder)
    for _, pass in ipairs(self.passes) do
        -- 1. Generate Barriers
        local buffer_barriers = {}
        local src_stages = 0
        local dst_stages = 0
        
        local function process_res(req, is_write)
            local res = req.res
            if res.type == M.TYPE_BUFFER then
                table.insert(buffer_barriers, ffi.new("VkBufferMemoryBarrier", {
                    sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
                    srcAccessMask = res.access,
                    dstAccessMask = req.access,
                    srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                    dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                    buffer = res.handle,
                    offset = 0,
                    size = vk.VK_WHOLE_SIZE
                }))
                src_stages = bit.bor(src_stages, res.stage)
                dst_stages = bit.bor(dst_stages, req.stage)
            end
            
            res.stage = req.stage
            res.access = req.access
        end

        for _, req in ipairs(pass.reads) do process_res(req, false) end
        for _, req in ipairs(pass.writes) do process_res(req, true) end

        -- 2. Apply Barriers
        if #buffer_barriers > 0 then
            if src_stages == 0 then src_stages = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT end
            
            local pBufs = ffi.new("VkBufferMemoryBarrier[?]", #buffer_barriers)
            for i, b in ipairs(buffer_barriers) do pBufs[i-1] = b end

            vk.vkCmdPipelineBarrier(
                cb,
                src_stages,
                dst_stages,
                0,
                0, nil,
                #buffer_barriers, pBufs,
                0, nil
            )
        end

        -- 3. Execute Pass
        pass.callback(encoder)
    end
end

return M
