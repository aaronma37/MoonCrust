local ffi = require("ffi")
local robot = require("mc.robot")

ffi.cdef[[
    typedef struct McapIndexEntry {
        uint64_t timestamp;
        uint64_t offset;
        uint32_t size;
        uint32_t channel_id;
    } McapIndexEntry;
]]

local M = {
    entries = nil,
    count = 0,
    capacity = 1000000,
    
    -- Per-channel indices for fast "last-state" reconstruction
    channels = {}, -- [ch_id] = { indices = uint32_array, count = N }
}

function M.build(bridge)
    if not bridge then return end
    
    print("Indexer: Building message index...")
    local start_t = ffi.C.SDL_GetTicks()
    
    M.count = 0
    M.channels = {}
    if not M.entries then
        M.entries = ffi.new("McapIndexEntry[?]", M.capacity)
    end
    
    robot.lib.mcap_rewind(bridge)
    local msg = ffi.new("McapMessage")
    
    -- Temporary Lua tables for grouping (will be packed into FFI after)
    local temp_groups = {}
    
    while robot.lib.mcap_get_current(bridge, msg) do
        if M.count >= M.capacity then break end
        
        local entry = M.entries[M.count]
        entry.timestamp = msg.log_time
        entry.offset = msg.offset
        entry.size = msg.data_size
        entry.channel_id = msg.channel_id
        
        if not temp_groups[msg.channel_id] then temp_groups[msg.channel_id] = {} end
        table.insert(temp_groups[msg.channel_id], M.count)
        
        M.count = M.count + 1
        robot.lib.mcap_advance(bridge)
    end
    
    -- Pack groups into efficient FFI arrays
    for ch_id, indices in pairs(temp_groups) do
        local n = #indices
        local arr = ffi.new("uint32_t[?]", n)
        for i=1, n do arr[i-1] = indices[i] end
        M.channels[ch_id] = { indices = arr, count = n }
    end
    
    local end_t = ffi.C.SDL_GetTicks()
    print(string.format("Indexer: Indexed %d messages (%d channels) in %d ms", M.count, #M.channels, tonumber(end_t - start_t)))
    robot.lib.mcap_rewind(bridge)
end

function M.find_latest_for_channel(ch_id, timestamp)
    local group = M.channels[ch_id]
    if not group or group.count == 0 then return nil end
    
    -- Binary search within the channel's specific timeline
    local low = 0
    local high = group.count - 1
    local best_idx = -1
    
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local msg_idx = group.indices[mid]
        if M.entries[msg_idx].timestamp <= timestamp then
            best_idx = msg_idx
            low = mid + 1
        else
            high = mid - 1
        end
    end
    
    if best_idx == -1 then return nil end
    return M.entries[best_idx]
end

function M.find_index_for_time(timestamp)
    if M.count == 0 then return 0 end
    local low, high, best = 0, M.count - 1, 0
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if M.entries[mid].timestamp <= timestamp then
            best = mid
            low = mid + 1
        else
            high = mid - 1
        end
    end
    return best
end

function M.get_entry(idx)
    if idx < 0 or idx >= M.count then return nil end
    return M.entries[idx]
end

return M
