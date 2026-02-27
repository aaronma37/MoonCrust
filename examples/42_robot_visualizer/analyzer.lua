local ffi = require("ffi")

-- 1. Load the Bridge
local bridge_path = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local status, lib = pcall(ffi.load, bridge_path)
if not status then
    print("Error: Could not load bridge. Build it first.")
    return
end

ffi.cdef[[
    typedef struct McapMessage {
        uint64_t log_time;
        uint64_t publish_time;
        uint32_t channel_id;
        uint32_t sequence;
        const uint8_t* data;
        uint64_t data_size;
        uint32_t point_count;
        uint64_t offset;
    } McapMessage;

    typedef struct McapChannelInfo {
        uint32_t id;
        const char* topic;
        const char* message_encoding;
        const char* schema_name;
    } McapChannelInfo;

    typedef struct McapBridge McapBridge;
    McapBridge* mcap_open(const char* path);
    void mcap_close(McapBridge* bridge);
    uint32_t mcap_get_channel_count(McapBridge* bridge);
    bool mcap_get_channel_info(McapBridge* bridge, uint32_t index, McapChannelInfo* out_info);
    bool mcap_get_current(McapBridge* bridge, McapMessage* out);
    void mcap_advance(McapBridge* bridge);
    void mcap_rewind(McapBridge* bridge);
]]

local mcap_file = arg[1] or "test_robot.mcap"
local b = lib.mcap_open(mcap_file)
if not b then print("Failed to open " .. mcap_file); return end

local channels = {}
local count = lib.mcap_get_channel_count(b)
for i=0, count-1 do
    local info = ffi.new("McapChannelInfo")
    if lib.mcap_get_channel_info(b, i, info) then
        channels[info.id] = { topic = ffi.string(info.topic), schema = ffi.string(info.schema_name) }
    end
end

print("\n--- MOONCRUST TELEMETRY ANALYZER ---")
print("Scanning file: " .. mcap_file)

local msg = ffi.new("McapMessage")
local sampled = {}

while lib.mcap_get_current(b, msg) do
    local ch_id = msg.channel_id
    if not sampled[ch_id] then
        local sz = tonumber(msg.data_size)
        sampled[ch_id] = { data = ffi.new("uint8_t[?]", sz), size = sz }
        ffi.copy(sampled[ch_id].data, msg.data, sz)
    end
    
    local all_done = true
    for id in pairs(channels) do if not sampled[id] then all_done = false; break end end
    if all_done then break end
    lib.mcap_advance(b)
end

local function is_sane(val)
    local v = tonumber(val)
    if not v then return false end
    return math.abs(v) < 10000 and math.abs(v) > 0.000001
end

for id, info in pairs(channels) do
    local s = sampled[id]
    if s then
        print(string.format("\nTopic: %s (%s)", info.topic, info.schema))
        print(string.format("  Message Size: %d bytes", s.size))
        
        -- 1. Scan for Pose-like patterns
        local found_pose = false
        for off = 0, s.size - 24 do
            local p = ffi.cast("double*", s.data + off)
            if is_sane(p[0]) and is_sane(p[1]) and is_sane(p[2]) then
                if not found_pose then print("  [POSE CANDIDATES (Double)]"); found_pose = true end
                print(string.format("    Offset %d: %.3f, %.3f, %.3f", off, tonumber(p[0]), tonumber(p[1]), tonumber(p[2])))
                if off > 128 then break end -- Limit output
            end
        end
        
        local found_fpose = false
        for off = 0, s.size - 12 do
            local p = ffi.cast("float*", s.data + off)
            if is_sane(p[0]) and is_sane(p[1]) and is_sane(p[2]) then
                if not found_fpose then print("  [POSE CANDIDATES (Float)]"); found_fpose = true end
                print(string.format("    Offset %d: %.3f, %.3f, %.3f", off, tonumber(p[0]), tonumber(p[1]), tonumber(p[2])))
                if off > 128 then break end -- Limit output
            end
        end
        
        -- 2. Scan for Lidar-like patterns
        if info.topic:find("lidar") or info.topic:find("points") or s.size > 5000 then
            print("  [LIDAR STRIDE SCAN (Float)]")
            local strides = {12, 16, 18, 20, 22, 24, 28, 30, 32, 48, 64}
            for _, stride_val in ipairs(strides) do
                for off = 0, math.min(s.size - (5 * stride_val), 64) do
                    local sane_count = 0
                    for p_idx = 0, 4 do
                        local p_off = off + (p_idx * stride_val)
                        local p = ffi.cast("float*", s.data + p_off)
                        if is_sane(p[0]) and is_sane(p[1]) and is_sane(p[2]) then
                            sane_count = sane_count + 1
                        end
                    end
                    if sane_count >= 4 then
                        print(string.format("    Possible Lidar: Offset %d, Stride %d", off, stride_val))
                        break -- Found one for this stride
                    end
                end
            end
        end
    end
end

lib.mcap_close(b)
