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

function M.build(bridge, path)
    if not bridge then return end
    
    local cache_path = path .. ".idx"
    local f = io.open(cache_path, "rb")
    if f then
        print("Indexer: Loading index from cache: " .. cache_path)
        local start_t = ffi.C.SDL_GetTicks()
        
        -- Read count
        local count_str = f:read(4)
        if count_str and #count_str == 4 then
            local count_ptr = ffi.cast("uint32_t*", count_str)
            M.count = count_ptr[0]
            
            if M.count > M.capacity then
                M.capacity = M.count + 100000
                M.entries = ffi.new("McapIndexEntry[?]", M.capacity)
            elseif not M.entries then
                M.entries = ffi.new("McapIndexEntry[?]", M.capacity)
            end
            
            -- Read entries
            local entries_size = M.count * ffi.sizeof("McapIndexEntry")
            local entries_data = f:read(entries_size)
            ffi.copy(M.entries, entries_data, entries_size)
            
            -- Read channel count
            local ch_count_str = f:read(4)
            local ch_count = ffi.cast("uint32_t*", ch_count_str)[0]
            
            M.channels = {}
            for i = 1, ch_count do
                local ch_hdr = f:read(8)
                local hdr_ptr = ffi.cast("uint32_t*", ch_hdr)
                local ch_id = hdr_ptr[0]
                local ch_n = hdr_ptr[1]
                
                local arr_size = ch_n * 4
                local arr_data = f:read(arr_size)
                local arr = ffi.new("uint32_t[?]", ch_n)
                ffi.copy(arr, arr_data, arr_size)
                
                M.channels[ch_id] = { indices = arr, count = ch_n }
            end
            
            f:close()
            local end_t = ffi.C.SDL_GetTicks()
            print(string.format("Indexer: Loaded %d messages (%d channels) from cache in %d ms", M.count, ch_count, tonumber(end_t - start_t)))
            return
        end
        f:close()
    end

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
        if M.count >= M.capacity then
            M.capacity = M.capacity * 2
            local new_entries = ffi.new("McapIndexEntry[?]", M.capacity)
            ffi.copy(new_entries, M.entries, M.count * ffi.sizeof("McapIndexEntry"))
            M.entries = new_entries
        end
        
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
    local ch_count = 0
    for ch_id, indices in pairs(temp_groups) do
        local n = #indices
        local arr = ffi.new("uint32_t[?]", n)
        for i=1, n do arr[i-1] = indices[i] end
        M.channels[ch_id] = { indices = arr, count = n }
        ch_count = ch_count + 1
    end
    
    local end_t = ffi.C.SDL_GetTicks()
    print(string.format("Indexer: Indexed %d messages (%d channels) in %d ms", M.count, ch_count, tonumber(end_t - start_t)))
    robot.lib.mcap_rewind(bridge)
    
    -- Save cache
    local fw = io.open(cache_path, "wb")
    if fw then
        print("Indexer: Saving index to cache: " .. cache_path)
        -- Write count
        local count_arr = ffi.new("uint32_t[1]", M.count)
        fw:write(ffi.string(count_arr, 4))
        
        -- Write entries
        fw:write(ffi.string(M.entries, M.count * ffi.sizeof("McapIndexEntry")))
        
        -- Write channel count
        local ch_count_arr = ffi.new("uint32_t[1]", ch_count)
        fw:write(ffi.string(ch_count_arr, 4))
        
        for ch_id, group in pairs(M.channels) do
            local hdr = ffi.new("uint32_t[2]", ch_id, group.count)
            fw:write(ffi.string(hdr, 8))
            fw:write(ffi.string(group.indices, group.count * 4))
        end
        fw:close()
    end
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
