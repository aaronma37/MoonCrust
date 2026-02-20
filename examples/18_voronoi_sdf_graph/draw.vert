#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec4 vColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint mode;
    uint count;
    uint pad0;
    uint pad1;
} pc;

void main() {
    uint idx = gl_VertexIndex;
    if (idx >= pc.count) {
        gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
        gl_PointSize = 1.0;
        vColor = vec4(0.0);
        return;
    }

    uint b = 0u;
    if (pc.mode == 1u) b = 1u;
    if (pc.mode == 2u) b = 2u;

    uint base = idx * 8u;
    vec3 p = vec3(
        uintBitsToFloat(all_buffers[b].data[base + 0]),
        uintBitsToFloat(all_buffers[b].data[base + 1]),
        uintBitsToFloat(all_buffers[b].data[base + 2])
    );
    float size = uintBitsToFloat(all_buffers[b].data[base + 3]);
    vColor = vec4(
        uintBitsToFloat(all_buffers[b].data[base + 4]),
        uintBitsToFloat(all_buffers[b].data[base + 5]),
        uintBitsToFloat(all_buffers[b].data[base + 6]),
        uintBitsToFloat(all_buffers[b].data[base + 7])
    );

    gl_Position = pc.mvp * vec4(p, 1.0);
    gl_PointSize = size / max(gl_Position.w * 0.1, 0.1);
}
