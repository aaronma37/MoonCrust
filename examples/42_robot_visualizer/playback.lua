local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local robot = require("mc.robot")
local mc = require("mc")

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
    pose_ch_id = 0,
    robot_pose = { x = 0, y = 0, z = 0, yaw = 0 },
    message_buffers = {},
    plot_history = {}, 
    last_lidar_points = 0,
    
    -- GTB (Global Telemetry Buffer)
    -- Increased to 512MB to handle 1000-message history for 64 channels
    gtb = nil,
    HISTORY_MAX = 1000, 
    MSG_SIZE_MAX = 8192, -- 8KB max per telemetry msg
}

function M.init()
    if not M.gtb then
        print("Playback: Allocating Global Telemetry Buffer (512MB)...")
        M.gtb = mc.buffer(512 * 1024 * 1024, "storage", nil, true)
    end
end

function M.request_field_history(ch_id, offset, is_double)
    if not M.plot_history[ch_id] then M.plot_history[ch_id] = {} end
    if not M.plot_history[ch_id][offset] then
        M.plot_history[ch_id][offset] = { 
            data = ffi.new("float[1000]"), 
            head = 0, 
            count = 0,
            is_double = is_double or false
        }
    end
    return M.plot_history[ch_id][offset]
end

function M.load_mcap(path)
    M.init()
    print("Playback: Attempting to load MCAP: " .. path)
    if M.bridge then robot.lib.mcap_close(M.bridge); M.bridge = nil end
    M.mcap_path = path
    M.bridge = robot.lib.mcap_open(M.mcap_path)
    if M.bridge == nil then return false end
    
    robot.lib.mcap_set_gtb(M.bridge, ffi.cast("uint8_t*", M.gtb.allocation.ptr), M.gtb.size)
    
    M.start_time = robot.lib.mcap_get_start_time(M.bridge)
    M.end_time = robot.lib.mcap_get_end_time(M.bridge)
    M.current_time_ns = M.start_time
    M.playback_time_ns = M.start_time
    M.paused = true 
    
    M.discover_topics()
    robot.lib.mcap_next(M.bridge, M.current_msg)
    return true
end

function M.discover_topics()
    local count = robot.lib.mcap_get_channel_count(M.bridge)
    print("Playback: Discovered " .. count .. " channels in bridge.")
    M.channels = {}
    local info = ffi.new("McapChannelInfo")
    local slot_size = M.MSG_SIZE_MAX * M.HISTORY_MAX
    
    for i=0, count-1 do
        if robot.lib.mcap_get_channel_info(M.bridge, i, info) then
            if info.topic ~= nil then
                local t = ffi.string(info.topic)
                local enc = info.message_encoding ~= nil and ffi.string(info.message_encoding) or "unknown"
                local sch = info.schema_name ~= nil and ffi.string(info.schema_name) or "unknown"
                table.insert(M.channels, { id = info.id, topic = t, encoding = enc, schema = sch, active = true })
                
                -- Configure Circular GTB Slot
                local offset = i * slot_size
                if offset + slot_size <= M.gtb.size then
                    robot.lib.mcap_set_gtb(M.bridge, ffi.cast("uint8_t*", M.gtb.allocation.ptr), M.gtb.size)
                    robot.lib.mcap_configure_gtb_slot(M.bridge, info.id, offset, M.MSG_SIZE_MAX, M.HISTORY_MAX)
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
    if M.seek_to then
        robot.lib.mcap_seek(M.bridge, M.seek_to)
        M.playback_time_ns = M.seek_to
        M.seek_to = nil
        robot.lib.mcap_next(M.bridge, M.current_msg)
    elseif not M.paused then
        M.playback_time_ns = M.playback_time_ns + ffi.cast("uint64_t", dt * 1e9 * M.speed)
    end

    while (not M.paused or M.seek_to) and M.current_msg.log_time < M.playback_time_ns do
        local ch_id = M.current_msg.channel_id
        if M.current_msg.data ~= nil then 
            local buf = M.message_buffers[ch_id]
            if not buf then 
                buf = { data = ffi.new("uint8_t[1048576]"), size = 0 } 
                M.message_buffers[ch_id] = buf 
            end
            local sz = math.min(tonumber(M.current_msg.data_size), 1048576)
            ffi.copy(buf.data, M.current_msg.data, sz)
            buf.size = sz
            
            local channel_history = M.plot_history[ch_id]
            if channel_history then
                for offset, h in pairs(channel_history) do
                    if sz >= offset + (h.is_double and 8 or 4) then
                        local ptr = ffi.cast(h.is_double and "double*" or "float*", M.current_msg.data + offset)
                        h.data[h.head] = tonumber(ptr[0])
                        h.head = (h.head + 1) % 1000
                        if h.count < 1000 then h.count = h.count + 1 end
                    end
                end
            end
        end
        
        if ch_id == M.lidar_ch_id and raw_buffer and raw_buffer.allocation.ptr ~= nil then 
            local sz = math.min(tonumber(M.current_msg.data_size), raw_buffer.size)
            ffi.copy(raw_buffer.allocation.ptr, M.current_msg.data, sz)
            if M.current_msg.data_size > 32 and ffi.string(M.current_msg.data + 4, 5) == "livox" then
                M.last_lidar_points = ffi.cast("uint32_t*", M.current_msg.data + 24)[0]
            else
                M.last_lidar_points = math.floor(sz / 12)
            end
        end
        
        if not robot.lib.mcap_next(M.bridge, M.current_msg) then
            robot.lib.mcap_rewind(M.bridge)
            M.playback_time_ns = M.start_time
            robot.lib.mcap_next(M.bridge, M.current_msg)
            break
        end
    end
    M.current_time_ns = M.playback_time_ns
end

return M
