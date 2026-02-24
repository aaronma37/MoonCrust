local ffi = require("ffi")

ffi.cdef[[
    typedef struct McapMessage {
        uint64_t log_time;
        uint64_t publish_time;
        uint32_t channel_id;
        uint32_t sequence;
        const uint8_t* data;
        uint64_t data_size;
    } McapMessage;

    typedef struct McapChannelInfo {
        uint32_t id;
        const char* topic;
        const char* message_encoding;
        const char* schema_name;
    } McapChannelInfo;

    typedef struct McapBridge McapBridge;

    void mcap_generate_test_file(const char* path);
    McapBridge* mcap_open(const char* path);
    void mcap_close(McapBridge* bridge);
    bool mcap_next(McapBridge* bridge, McapMessage* out_msg);
    void mcap_rewind(McapBridge* bridge);
    void mcap_seek(McapBridge* bridge, uint64_t timestamp);
    uint64_t mcap_get_start_time(McapBridge* bridge);
    uint64_t mcap_get_end_time(McapBridge* bridge);
    uint32_t mcap_get_channel_count(McapBridge* bridge);
    bool mcap_get_channel_info(McapBridge* bridge, uint32_t index, McapChannelInfo* out_info);
    const char* mcap_get_schema_content(McapBridge* bridge, uint32_t channel_id);
]]

-- Common ROS2 Message Structs (Silicon Aligned)
ffi.cdef[[
    typedef struct ros_header {
        uint64_t stamp_nanos;
        const char* frame_id; // This will actually be a CDR string, careful
    } ros_header;

    typedef struct ros_point32 {
        float x, y, z;
    } ros_point32;

    // Simplified PointCloud2 for CDR access
    typedef struct ros_point_cloud2 {
        // Header is usually first, but CDR has offsets
        uint32_t height;
        uint32_t width;
        // ...
    } ros_point_cloud2;
]]

local M = {}

function M.init_bridge()
    -- If imgui is already loaded with the robot lib, we can just use its handle
    local ok, imgui = pcall(require, "imgui")
    if ok and imgui.gui then
        M.lib = imgui.gui
    else
        M.lib = ffi.load("examples/42_robot_visualizer/build/mooncrust_robot.so")
    end
end

return M
