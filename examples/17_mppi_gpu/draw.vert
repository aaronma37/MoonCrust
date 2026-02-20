#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vWorld;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint mode;
    uint count;
    uint pad0;
    uint pad1;
    float plane_x;
    float plane_y;
    float plane_z;
    float plane_hy;
    float plane_hz;
    float plane_pad0;
    float plane_pad1;
    float plane_pad2;
    float cam_x;
    float cam_y;
    float cam_z;
    float occ_pad0;
    float occ1_x;
    float occ1_y;
    float occ1_z;
    float occ1_hy;
    float occ1_hz;
    float occ1_pad0;
    float occ1_pad1;
    float occ1_pad2;
    float occ2_x;
    float occ2_y;
    float occ2_z;
    float occ2_hy;
    float occ2_hz;
    float occ2_pad0;
    float occ2_pad1;
    float occ2_pad2;
} pc;

void main() {
    uint idx = gl_VertexIndex;
    if (idx >= pc.count) {
        gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
        gl_PointSize = 1.0;
        vColor = vec4(0.0);
        vWorld = vec3(0.0);
        return;
    }

    uint b = 5u;
    if (pc.mode == 1u) b = 6u;
    if (pc.mode == 2u) b = 7u;

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
    vWorld = p;
    gl_PointSize = size / max(gl_Position.w * 0.1, 0.1);
}
