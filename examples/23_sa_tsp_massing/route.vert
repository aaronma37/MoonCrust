#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec4 vColor;

layout(push_constant) uniform DrawPC {
    mat4 mvp;
    uint mode;
    uint count;
    uint start;
    uint pad0;
} pc;

void main() {
    uint local_idx = gl_VertexIndex - pc.start;
    if (local_idx >= pc.count) {
        gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
        gl_PointSize = 1.0;
        vColor = vec4(0.0);
        return;
    }
    uint idx = gl_VertexIndex;

    uint b = 0u;
    if (pc.mode == 1u) b = 1u;
    if (pc.mode == 2u) b = 2u;

    uint base = idx * 8u;
    vec3 p = vec3(
        uintBitsToFloat(all_buffers[b].data[base + 0u]),
        uintBitsToFloat(all_buffers[b].data[base + 1u]),
        uintBitsToFloat(all_buffers[b].data[base + 2u])
    );
    float size = uintBitsToFloat(all_buffers[b].data[base + 3u]);
    vColor = vec4(
        uintBitsToFloat(all_buffers[b].data[base + 4u]),
        uintBitsToFloat(all_buffers[b].data[base + 5u]),
        uintBitsToFloat(all_buffers[b].data[base + 6u]),
        uintBitsToFloat(all_buffers[b].data[base + 7u])
    );

    gl_Position = pc.mvp * vec4(p, 1.0);
    gl_PointSize = size;
}
