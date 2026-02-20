#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec3 vColor;
layout(location = 1) out float vIsNode;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint is_edge;
} pc;

void main() {
    uint idx = gl_VertexIndex;
    vec3 pos;
    vec3 color;
    float size = 10.0;
    vIsNode = 0.0;

    if (pc.is_edge == 1) {
        uint edge_idx = idx / 2;
        uint is_end = idx % 2;
        uint e_base = edge_idx * 2;
        uint node_idx = all_buffers[1].data[e_base + is_end];
        uint n_base = node_idx * 8;
        pos = vec3(uintBitsToFloat(all_buffers[0].data[n_base + 0]),
                   uintBitsToFloat(all_buffers[0].data[n_base + 1]),
                   uintBitsToFloat(all_buffers[0].data[n_base + 2]));
        color = vec3(1.0, 1.0, 1.2);
    } else {
        uint n_base = idx * 8;
        pos = vec3(uintBitsToFloat(all_buffers[0].data[n_base + 0]),
                   uintBitsToFloat(all_buffers[0].data[n_base + 1]),
                   uintBitsToFloat(all_buffers[0].data[n_base + 2]));
        color = vec3(uintBitsToFloat(all_buffers[0].data[n_base + 4]),
                     uintBitsToFloat(all_buffers[0].data[n_base + 5]),
                     uintBitsToFloat(all_buffers[0].data[n_base + 6]));
        size = 30.0;
        vIsNode = 1.0;
    }

    gl_Position = pc.mvp * vec4(pos, 1.0);
    vColor = color;
    gl_PointSize = size;
}
