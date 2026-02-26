local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local robot = require("mc.robot")
local mc = require("mc")
local indexer = require("examples.42_robot_visualizer.indexer")

local M = {
    mcap_path = "test_robot.mcap",
    bridge = nil,
    start_time = 0ULL,
    end_time = 0ULL,
    current_time_ns = 0ULL,
    playback_time_ns = 0ULL,
    paused = false,
    seek_to = nil,
    speed = 1.0,
    current_msg = ffi.new("McapMessage"),
    channels = {},
    lidar_ch_id = 0,
    lidar_topic = "/livox/lidar",
    pose_ch_id = 0,
    robot_pose = { x = 0, y = 0, z = 0, yaw = 0 },
    plot_history = {}, 
    last_lidar_points = 0,
    last_seek_time = 0ULL, -- Throttle seeks
    just_sought = false,
    bytes_processed = 0,
    throughput_mbs = 0,
    
    -- GTB (Global Telemetry Buffer)
    gtb = nil,
    _gtb_ref = nil, -- Anchor to prevent GC
    _persistence = {}, -- Global FFI anchor
    _msg_anchor = nil,
    HISTORY_MAX = 1000, 
    MSG_SIZE_MAX = 8192, 
    
    -- STATIC MESSAGE POOL (The "Crash Killer")
    MAX_TOPICS = 128,
    MSG_BUF_SIZE = 1048576,
    message_buffers = {},
    buffers_by_id = {}, -- O(1) lookup
    channels_by_id = {}, -- O(1) lookup
}

function M.init()
    if not M.gtb then
        print("Playback: Allocating Global Telemetry Buffer (512MB)...")
        M.gtb = mc.buffer(512 * 1024 * 1024, "storage", nil, true)
        M._gtb_ref = M.gtb -- Hold reference
    end
    
    if #M.message_buffers == 0 then
        print("Playback: Allocating Static Message Pool (128 x 1MB)...")
        for i=1, M.MAX_TOPICS do
            M.message_buffers[i] = {
                data = ffi.new("uint8_t[1048576]"),
                size = 0,
                active_ch = -1
            }
        end
    end
end

function M.get_msg_buffer(ch_id)
    local existing = M.buffers_by_id[ch_id]
    if existing then return existing end
    
    -- Assign new slot
    for i=1, M.MAX_TOPICS do
        if M.message_buffers[i].active_ch == -1 then
            M.message_buffers[i].active_ch = ch_id
            M.buffers_by_id[ch_id] = M.message_buffers[i]
            return M.message_buffers[i]
        end
    end
    return nil -- Pool exhausted
end

function M.request_field_history(ch_id, offset, is_double)
    if not M.plot_history[ch_id] then M.plot_history[ch_id] = {} end
    if not M.plot_history[ch_id][offset] then
        local data = ffi.new("float[1000]")
        table.insert(M._persistence, data) -- Anchor
        M.plot_history[ch_id][offset] = { 
            data = data, 
            head = 0, 
            count = 0,
            is_double = is_double or false
        }
    end
    return M.plot_history[ch_id][offset]
end

function M.load_mcap(path)
    M.init()
    if M.bridge then robot.lib.mcap_close(M.bridge); M.bridge = nil end
    for i=1, M.MAX_TOPICS do M.message_buffers[i].active_ch = -1 end -- Reset pool
    
    M.mcap_path = path
    M.bridge = robot.lib.mcap_open(M.mcap_path)
    if M.bridge == nil then return false end
    
    local gtb_ptr = ffi.cast("uint8_t*", M.gtb.allocation.ptr)
    table.insert(M._persistence, gtb_ptr) -- Anchor ptr
    robot.lib.mcap_set_gtb(M.bridge, gtb_ptr, M.gtb.size)
    M.start_time = robot.lib.mcap_get_start_time(M.bridge)
    M.end_time = robot.lib.mcap_get_end_time(M.bridge)
    M.current_time_ns, M.playback_time_ns, M.paused = M.start_time, M.start_time, true 
    
    indexer.build(M.bridge)
    M.discover_topics()
    
    M._msg_anchor = ffi.new("McapMessage")
    M.current_msg = M._msg_anchor
    if robot.lib.mcap_get_current(M.bridge, M.current_msg) then
        -- initial msg loaded
    end
    return true
end

function M.discover_topics()
    local count = robot.lib.mcap_get_channel_count(M.bridge)
    M.channels = {}
    M.channels_by_id = {}
    local info = ffi.new("McapChannelInfo")
    local slot_size = M.MSG_SIZE_MAX * M.HISTORY_MAX
    
    local configured_count = 0
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(M.bridge, i, info) then
                local t = ffi.string(info.topic)
                if t == M.lidar_topic then M.lidar_ch_id = info.id end
            if info.topic ~= nil then
                local t = ffi.string(info.topic)
                local ch = { id = info.id, topic = t, encoding = ffi.string(info.message_encoding or "u"), schema = ffi.string(info.schema_name or "u"), active = true, gtb_offset = nil }
                table.insert(M.channels, ch)
                M.channels_by_id[ch.id] = ch
                
                -- Only configure if we have space in GTB
                local offset = configured_count * slot_size
                if offset + slot_size <= M.gtb.size then
                    robot.lib.mcap_configure_gtb_slot(M.bridge, info.id, offset, M.MSG_SIZE_MAX, M.HISTORY_MAX)
                    ch.gtb_offset = offset
                    configured_count = configured_count + 1
                end
            end
        end
    end
end

function M.get_gtb_slot_index(ch_id)
    if not M.bridge then return 0 end
    return robot.lib.mcap_get_gtb_slot_index(M.bridge, ch_id)
end

function M.update(dt, raw_buffer)
    if not M.bridge then return end
    
    local now_ms = ffi.C.SDL_GetTicks()
    M.bytes_processed = 0
    if M.seek_to then
        -- Throttle seeks to 60Hz (once every 16ms)
        if tonumber(now_ms - M.last_seek_time) > 16 then
            local idx = indexer.find_index_for_time(M.seek_to)
            local entry = indexer.get_entry(idx)
            if entry then
                robot.lib.mcap_seek_offset(M.bridge, entry.offset)
                M.playback_time_ns, M.seek_to = M.seek_to, nil
                
                -- Full-State Reconstruction: Load latest for EVERY active channel
                for _, ch in ipairs(M.channels) do
                    local latest = indexer.find_latest_for_channel(ch.id, M.playback_time_ns)
                    if latest then
                        -- 1. Load into GPU (GTB)
                        robot.lib.mcap_load_into_gtb(M.bridge, latest.offset, latest.size, ch.id)
                        
                        -- 2. Load into CPU (message_buffers for Pretty Viewer)
                        local buf = M.get_msg_buffer(ch.id)
                        if buf then
                            local sz = math.min(tonumber(latest.size), M.MSG_BUF_SIZE)
                            robot.lib.mcap_load_into_buffer(M.bridge, latest.offset, sz, buf.data)
                            buf.size = sz
                        end
                    end
                end
                
                robot.lib.mcap_get_current(M.bridge, M.current_msg)
                M.last_seek_time = now_ms
                M.just_sought = true
            end
        end
    elseif not M.paused then
        M.playback_time_ns = M.playback_time_ns + ffi.cast("uint64_t", dt * 1e9 * M.speed)
    end

    local msgs_processed = 0
    local last_msg_for_ch = {} -- Track the last message seen this frame for each channel

    -- Condition: Process if live, or if we JUST sought (to update the frame)
    while (not M.paused or M.just_sought) and M.current_msg.log_time <= M.playback_time_ns do
        if msgs_processed > 20000 then break end 
        local ch_id = M.current_msg.channel_id
        
        -- LiDAR point count (ZERO-COPY Silicon Extraction)
        if ch_id == M.lidar_ch_id then 
            M.last_lidar_points = M.current_msg.point_count
        end

        -- Record that we saw a message for this channel
        last_msg_for_ch[ch_id] = true
        M.bytes_processed = M.bytes_processed + tonumber(M.current_msg.data_size)
        
        robot.lib.mcap_advance(M.bridge)
        
        -- If the NEXT message is for a different time or we hit the end, 
        -- we should capture the data for the UI if needed. 
        -- But actually, it's simpler: just capture the "current" data into the buffer 
        -- only for the VERY LAST message processed in this loop.
        
        if not robot.lib.mcap_get_current(M.bridge, M.current_msg) then
            robot.lib.mcap_rewind(M.bridge)
            M.playback_time_ns = M.start_time
            robot.lib.mcap_get_current(M.bridge, M.current_msg)
            break
        end
        msgs_processed = msgs_processed + 1
        M.just_sought = false 
    end

    -- POST-LOOP: Synchronize the CPU buffers only for the channels that actually changed.
    -- This ensures we only do ONE ffi.copy per active channel per frame,
    -- instead of 5,000+ copies.
    for ch_id, _ in pairs(last_msg_for_ch) do
        local buf = M.get_msg_buffer(ch_id)
        if buf then
            -- We need to get the "latest" for this channel specifically
            -- because the global iterator has already moved past it.
            local latest = indexer.find_latest_for_channel(ch_id, M.playback_time_ns)
            if latest then
                local sz = math.min(tonumber(latest.size), M.MSG_BUF_SIZE)
                robot.lib.mcap_load_into_buffer(M.bridge, latest.offset, sz, buf.data)
                buf.size = sz
            end
        end
    end
    
    local current_mbs = (M.bytes_processed / 1024 / 1024) / (dt > 0 and dt or 0.016)
    M.throughput_mbs = M.throughput_mbs * 0.9 + current_mbs * 0.1
    
    M.current_time_ns = M.playback_time_ns
end

if jit then
    jit.off(M.update)
end

return M
