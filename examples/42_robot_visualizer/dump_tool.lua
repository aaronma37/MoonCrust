local ffi = require("ffi")

-- 1. Locate the bridge
local bridge_path = "examples/42_robot_visualizer/build/mooncrust_robot.so"
local status, lib = pcall(ffi.load, bridge_path)
if not status then
    print("Error: Could not load bridge at " .. bridge_path)
    print("Please build it first: cd examples/42_robot_visualizer/build && cmake .. && make")
    return
end

-- 2. Define the minimal FFI needed for dumping
ffi.cdef[[
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
    const char* mcap_get_schema_content(McapBridge* bridge, uint32_t channel_id);
]]

-- 3. Parse Args
local mcap_file = arg[1]
if not mcap_file then
    print("Usage: luajit examples/42_robot_visualizer/dump_tool.lua <file.mcap>")
    os.exit(1)
end

-- 4. Dump Logic
local b = lib.mcap_open(mcap_file)
if b == nil then
    print("Error: Failed to open MCAP file: " .. mcap_file)
    os.exit(1)
end

local count = lib.mcap_get_channel_count(b)
print("MCAP_SCHEMA_DUMP_START")
print("File: " .. mcap_file)
print("Total Channels: " .. count)

for i=0, count-1 do
    local info = ffi.new("McapChannelInfo")
    if lib.mcap_get_channel_info(b, i, info) then
        local topic = ffi.string(info.topic)
        print("\nTOPIC: " .. topic)
        print("SCHEMA_NAME: " .. ffi.string(info.schema_name))
        
        local raw = lib.mcap_get_schema_content(b, info.id)
        if raw ~= nil then
            print("DEFINITION_START")
            print(ffi.string(raw))
            print("DEFINITION_END")
        else
            print("NO_DEFINITION")
        end
    end
end

lib.mcap_close(b)
print("\nMCAP_SCHEMA_DUMP_END")
