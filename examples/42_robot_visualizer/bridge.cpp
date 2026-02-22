#define MCAP_IMPLEMENTATION
#include <mcap/reader.hpp>
#include <mcap/writer.hpp>
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <memory>
#include <cmath>

#define EXPORT extern "C" __attribute__((visibility("default")))

struct McapMessage {
    uint64_t log_time;
    uint64_t publish_time;
    uint32_t channel_id;
    uint32_t sequence;
    const uint8_t* data;
    uint64_t data_size;
};

struct McapBridge {
    mcap::McapReader reader;
    std::unique_ptr<mcap::LinearMessageView> message_view;
    std::unique_ptr<mcap::LinearMessageView::Iterator> it;
    bool valid;
};

EXPORT void mcap_generate_test_file(const char* path) {
    mcap::McapWriter writer;
    auto status = writer.open(path, mcap::McapWriterOptions("ros2"));
    if (!status.ok()) return;

    mcap::Schema schema("PointCloud2", "ros2msg", "binary");
    writer.addSchema(schema);

    mcap::Channel channel("lidar", "ros2", schema.id);
    writer.addChannel(channel);

    const int frames = 1000;
    const int points_per_frame = 10000;
    std::vector<float> points(points_per_frame * 3);

    for (int f = 0; f < frames; ++f) {
        for (int i = 0; i < points_per_frame; ++i) {
            float angle = (float)i / points_per_frame * 2.0f * M_PI;
            float rot = (float)f / frames * 2.0f * M_PI;
            float dist = 10.0f + std::sin(angle * 10.0f + rot) * 2.0f;
            points[i*3 + 0] = std::cos(angle + rot) * dist;
            points[i*3 + 1] = std::sin(angle + rot) * dist;
            points[i*3 + 2] = (float)f / 10.0f;
        }

        mcap::Message msg;
        msg.channelId = channel.id;
        msg.logTime = f * 100000000; // 100ms
        msg.publishTime = msg.logTime;
        msg.data = reinterpret_cast<const std::byte*>(points.data());
        msg.dataSize = points.size() * sizeof(float);
        writer.write(msg);
    }
    writer.close();
    std::cout << "Generated test MCAP: " << path << std::endl;
}

EXPORT McapBridge* mcap_open(const char* path) {
    auto bridge = new McapBridge();
    auto status = bridge->reader.open(path);
    if (!status.ok()) {
        std::cerr << "Failed to open MCAP: " << status.message << std::endl;
        delete bridge;
        return nullptr;
    }

    bridge->message_view = std::make_unique<mcap::LinearMessageView>(bridge->reader.readMessages());
    bridge->it = std::make_unique<mcap::LinearMessageView::Iterator>(bridge->message_view->begin());
    bridge->valid = true;
    return bridge;
}

EXPORT void mcap_close(McapBridge* bridge) {
    if (bridge) {
        bridge->reader.close();
        delete bridge;
    }
}

EXPORT bool mcap_next(McapBridge* bridge, McapMessage* out_msg) {
    if (!bridge || !bridge->it || *bridge->it == bridge->message_view->end()) {
        return false;
    }

    const auto& msg = **bridge->it;
    out_msg->log_time = msg.message.logTime;
    out_msg->publish_time = msg.message.publishTime;
    out_msg->channel_id = msg.message.channelId;
    out_msg->sequence = msg.message.sequence;
    out_msg->data = reinterpret_cast<const uint8_t*>(msg.message.data);
    out_msg->data_size = msg.message.dataSize;

    ++(*bridge->it);
    return true;
}

EXPORT void mcap_rewind(McapBridge* bridge) {
    if (bridge && bridge->message_view) {
        bridge->it = std::make_unique<mcap::LinearMessageView::Iterator>(bridge->message_view->begin());
    }
}

EXPORT uint64_t mcap_get_start_time(McapBridge* bridge) {
    if (!bridge || !bridge->message_view) return 0;
    auto it = bridge->message_view->begin();
    if (it == bridge->message_view->end()) return 0;
    return it->message.logTime;
}

EXPORT uint64_t mcap_get_end_time(McapBridge* bridge) {
    if (!bridge) return 0;
    auto stats = bridge->reader.statistics();
    if (stats) return stats->messageEndTime;
    return 0;
}

EXPORT void mcap_seek(McapBridge* bridge, uint64_t timestamp) {
    if (!bridge) return;
    bridge->message_view = std::make_unique<mcap::LinearMessageView>(bridge->reader.readMessages(timestamp));
    bridge->it = std::make_unique<mcap::LinearMessageView::Iterator>(bridge->message_view->begin());
}

EXPORT uint32_t mcap_get_channel_count(McapBridge* bridge) {
    if (!bridge) return 0;
    return bridge->reader.channels().size();
}

struct McapChannelInfo {
    uint32_t id;
    const char* topic;
    const char* message_encoding;
    const char* schema_name;
};

EXPORT bool mcap_get_channel_info(McapBridge* bridge, uint32_t index, McapChannelInfo* out_info) {
    if (!bridge) return false;
    auto channels = bridge->reader.channels();
    if (index >= channels.size()) return false;

    auto it = channels.begin();
    std::advance(it, index);
    const auto& channel = *it->second;

    out_info->id = channel.id;
    out_info->topic = channel.topic.c_str();
    out_info->message_encoding = channel.messageEncoding.c_str();
    
    auto schemas = bridge->reader.schemas();
    if (schemas.count(channel.schemaId)) {
        out_info->schema_name = schemas.at(channel.schemaId)->name.c_str();
    } else {
        out_info->schema_name = "unknown";
    }

    return true;
}
