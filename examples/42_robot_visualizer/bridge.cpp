#define MCAP_IMPLEMENTATION
#include <mcap/reader.hpp>
#include <mcap/writer.hpp>
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <memory>
#include <cmath>
#include <algorithm>

#define EXPORT extern "C" __attribute__((visibility("default")))

struct McapMessage {
    uint64_t log_time;
    uint64_t publish_time;
    uint32_t channel_id;
    uint32_t sequence;
    const uint8_t* data;
    uint64_t data_size;
};

struct McapChannelInfoInternal {
    uint32_t id;
    std::string topic;
    std::string encoding;
    std::string schema;
};

struct McapBridge {
    mcap::McapReader reader;
    std::unique_ptr<mcap::LinearMessageView> message_view;
    std::unique_ptr<mcap::LinearMessageView::Iterator> it;
    std::vector<McapChannelInfoInternal> channels;
    uint64_t start_time = 0;
    uint64_t end_time = 0;
};

EXPORT void mcap_generate_test_file(const char* path) {
    mcap::McapWriter writer;
    auto status = writer.open(path, mcap::McapWriterOptions("ros2"));
    if (!status.ok()) {
        std::cerr << "MCAP Writer failed to open: " << status.message << std::endl;
        return;
    }

    // 1. Schemas
    mcap::Schema s_lidar("PointCloud2", "ros2msg", "binary");
    writer.addSchema(s_lidar);
    mcap::Schema s_float("Float32", "ros2msg", "binary");
    writer.addSchema(s_float);
    mcap::Schema s_pose("Pose", "ros2msg", "binary");
    writer.addSchema(s_pose);

    // 2. Channels (Explicitly link to schemas)
    mcap::Channel c_lidar("lidar", "ros2", s_lidar.id);
    writer.addChannel(c_lidar);
    mcap::Channel c_pose("pose", "ros2", s_pose.id);
    writer.addChannel(c_pose);
    mcap::Channel c_batt("battery_voltage", "ros2", s_float.id);
    writer.addChannel(c_batt);
    mcap::Channel c_vel("motor_velocity", "ros2", s_float.id);
    writer.addChannel(c_vel);
    mcap::Channel c_imu("imu_pitch", "ros2", s_float.id);
    writer.addChannel(c_imu);

    std::vector<float> points(10000000 * 3);
    for (int f = 0; f < 200; ++f) {
        uint64_t t = f * 100000000ULL;
        
        // Lidar
        for (int i=0; i<10000000; ++i) {
            float a = (float)i / 10000.0f * 6.283185f; // Wrap around to create thickness
            float r = 10.0f + ((float)(i % 1000) / 1000.0f) * 2.0f - 1.0f; // Radial noise
            points[i*3+0] = cos(a) * r; 
            points[i*3+1] = sin(a) * r; 
            points[i*3+2] = (float)f * 0.05f + ((float)(i % 100) / 100.0f) * 0.5f; // Vertical noise
        }
        mcap::Message m1; m1.channelId = c_lidar.id; m1.logTime = t; m1.publishTime = t;
        m1.data = reinterpret_cast<const std::byte*>(points.data()); m1.dataSize = points.size() * sizeof(float);
        if (!writer.write(m1).ok()) std::cerr << "Write lidar failed" << std::endl;

        // Pose (Circular path)
        struct { float x, y, z, yaw; } val_pose;
        float angle = (float)f * 0.05f;
        val_pose.x = cos(angle) * 5.0f;
        val_pose.y = sin(angle) * 5.0f;
        val_pose.z = 0.0f;
        val_pose.yaw = angle + 1.570796f;
        mcap::Message m_pose; m_pose.channelId = c_pose.id; m_pose.logTime = t; m_pose.publishTime = t;
        m_pose.data = reinterpret_cast<const std::byte*>(&val_pose); m_pose.dataSize = sizeof(val_pose);
        writer.write(m_pose);

        // Battery
        float val_batt = 12.0f - (f * 0.005f);
        mcap::Message m2; m2.channelId = c_batt.id; m2.logTime = t; m2.publishTime = t;
        m2.data = reinterpret_cast<const std::byte*>(&val_batt); m2.dataSize = sizeof(float);
        writer.write(m2);

        // Velocity
        float val_vel = sin(f * 0.1f) * 5.0f;
        mcap::Message m3; m3.channelId = c_vel.id; m3.logTime = t; m3.publishTime = t;
        m3.data = reinterpret_cast<const std::byte*>(&val_vel); m3.dataSize = sizeof(float);
        writer.write(m3);

        // IMU
        float val_imu = (float)(rand() % 100) / 100.0f;
        mcap::Message m4; m4.channelId = c_imu.id; m4.logTime = t; m4.publishTime = t;
        m4.data = reinterpret_cast<const std::byte*>(&val_imu); m4.dataSize = sizeof(float);
        writer.write(m4);
    }
    writer.close();
    std::cout << "MCAP Generation Complete." << std::endl;
}

EXPORT McapBridge* mcap_open(const char* path) {
    auto b = new McapBridge();
    auto status = b->reader.open(path);
    if (!status.ok()) {
        std::cerr << "Bridge failed to open " << path << ": " << status.message << std::endl;
        delete b;
        return nullptr;
    }

    // Force scan to discover all channels
    b->message_view = std::make_unique<mcap::LinearMessageView>(b->reader.readMessages());
    b->it = std::make_unique<mcap::LinearMessageView::Iterator>(b->message_view->begin());
    
    // Iterate once to populate metadata (inefficient but safe for test)
    // In real app we would use readSummary
    bool first = true;
    for (auto const& msg : *b->message_view) { 
        if (first) { b->start_time = msg.message.logTime; first = false; }
        b->end_time = msg.message.logTime;
    }
    
    // Now copy channels into stable storage
    const auto& channel_map = b->reader.channels();
    const auto& schema_map = b->reader.schemas();
    
    for (auto const& [id, ch_ptr] : channel_map) {
        McapChannelInfoInternal info;
        info.id = ch_ptr->id;
        info.topic = ch_ptr->topic;
        info.encoding = ch_ptr->messageEncoding;
        if (schema_map.count(ch_ptr->schemaId)) {
            info.schema = schema_map.at(ch_ptr->schemaId)->name;
        } else {
            info.schema = "unknown";
        }
        b->channels.push_back(info);
    }
    
    // Reset iterator for Lua usage
    b->it = std::make_unique<mcap::LinearMessageView::Iterator>(b->message_view->begin());
    
    return b;
}

EXPORT void mcap_close(McapBridge* b) {
    if (b) {
        b->reader.close();
        delete b;
    }
}

EXPORT bool mcap_next(McapBridge* b, McapMessage* out) {
    if (!b || !b->it || *b->it == b->message_view->end()) return false;
    const auto& m = **b->it;
    out->log_time = m.message.logTime;
    out->publish_time = m.message.publishTime;
    out->channel_id = m.message.channelId;
    out->sequence = m.message.sequence;
    out->data = reinterpret_cast<const uint8_t*>(m.message.data);
    out->data_size = m.message.dataSize;
    ++(*b->it);
    return true;
}

EXPORT void mcap_rewind(McapBridge* b) {
    if (b && b->message_view) {
        b->it = std::make_unique<mcap::LinearMessageView::Iterator>(b->message_view->begin());
    }
}

EXPORT uint64_t mcap_get_start_time(McapBridge* b) {
    return b ? b->start_time : 0;
}

EXPORT uint64_t mcap_get_end_time(McapBridge* b) {
    return b ? b->end_time : 0;
}

EXPORT void mcap_seek(McapBridge* b, uint64_t timestamp) {
    if (!b) return;
    b->message_view = std::make_unique<mcap::LinearMessageView>(b->reader.readMessages(timestamp));
    b->it = std::make_unique<mcap::LinearMessageView::Iterator>(b->message_view->begin());
}

EXPORT uint32_t mcap_get_channel_count(McapBridge* b) {
    return b ? static_cast<uint32_t>(b->channels.size()) : 0;
}

struct McapChannelInfo {
    uint32_t id;
    const char* topic;
    const char* message_encoding;
    const char* schema_name;
};

EXPORT bool mcap_get_channel_info(McapBridge* b, uint32_t index, McapChannelInfo* out) {
    if (!b || index >= b->channels.size()) return false;
    const auto& ch = b->channels[index];
    out->id = ch.id;
    out->topic = ch.topic.c_str();
    out->message_encoding = ch.encoding.c_str();
    out->schema_name = ch.schema.c_str();
    return true;
}

EXPORT const char* mcap_get_schema_content(McapBridge* b, uint32_t channel_id) {
    if (!b) return nullptr;
    const auto& channel_map = b->reader.channels();
    if (channel_map.count(channel_id)) {
        auto schema_id = channel_map.at(channel_id)->schemaId;
        const auto& schema_map = b->reader.schemas();
        if (schema_map.count(schema_id)) {
            return reinterpret_cast<const char*>(schema_map.at(schema_id)->data.data());
        }
    }
    return nullptr;
}
