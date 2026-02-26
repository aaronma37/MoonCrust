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
}

function M.build(bridge)
    if not bridge then return end
    
    print("Indexer: Building message index...")
    local start_t = ffi.C.SDL_GetTicks()
    
    -- Reset index
    M.count = 0
    if not M.entries then
        M.entries = ffi.new("McapIndexEntry[?]", M.capacity)
    end
    
    robot.lib.mcap_rewind(bridge)
    local msg = ffi.new("McapMessage")
    
    while robot.lib.mcap_get_current(bridge, msg) do
        if M.count >= M.capacity then
            print("Indexer: Capacity reached, truncating index.")
            break
        end
        
        local entry = M.entries[M.count]
        entry.timestamp = msg.log_time
        entry.offset = msg.offset
        entry.size = msg.data_size
        entry.channel_id = msg.channel_id
        
        M.count = M.count + 1
        robot.lib.mcap_advance(bridge)
    end
    
    local end_t = ffi.C.SDL_GetTicks()
    print(string.format("Indexer: Indexed %d messages in %d ms", M.count, tonumber(end_t - start_t)))
    
    -- Rewind back for normal playback
    robot.lib.mcap_rewind(bridge)
end

function M.find_index_for_time(timestamp)
    if M.count == 0 then return 0 end
    
    -- Binary search
    local low = 0
    local high = M.count - 1
    local best = 0
    
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
