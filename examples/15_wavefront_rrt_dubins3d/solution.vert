#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec3 vColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    float goal_x, goal_y, goal_z, goal_r;
    float sim_t;
    float pad_a, pad_b, pad_c;
    uint node_count;
    uint mode;
    uint obs_count;
    float solution_blend;
} pc;

void main() {
    uint idx = gl_VertexIndex;
    uint buf_idx = (pc.mode == 3u) ? 5u : 4u;
    uint base = idx * 4u;

    vec3 p = vec3(
        uintBitsToFloat(all_buffers[buf_idx].data[base + 0]),
        uintBitsToFloat(all_buffers[buf_idx].data[base + 1]),
        uintBitsToFloat(all_buffers[buf_idx].data[base + 2])
    );

    if (pc.mode == 3u) {
        float fade = 1.0 - clamp(pc.solution_blend, 0.0, 1.0);
        vColor = vec3(0.12, 0.22, 0.48) * (0.2 + 0.8 * fade);
        gl_PointSize = 5.0;
    } else {
        vColor = vec3(3.8, 2.8, 0.35);
        gl_PointSize = 9.0;
    }

    gl_Position = pc.mvp * vec4(p, 1.0);
}
