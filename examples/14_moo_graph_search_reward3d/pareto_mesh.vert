#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec3 vColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    float obs_x, obs_y, obs_z, obs_r;
    float rew1_x, rew1_y, rew1_z, rew1_r;
    float rew2_x, rew2_y, rew2_z, rew2_r;
    float rew3_x, rew3_y, rew3_z, rew3_r;
    float rew4_x, rew4_y, rew4_z, rew4_r;
    uint mode;
} pc;

void main() {
    uint idx = gl_VertexIndex;
    uint base = idx * 8;

    vec3 pos = vec3(
        uintBitsToFloat(all_buffers[4].data[base + 0]),
        uintBitsToFloat(all_buffers[4].data[base + 1]),
        uintBitsToFloat(all_buffers[4].data[base + 2])
    );

    vColor = vec3(
        uintBitsToFloat(all_buffers[4].data[base + 4]),
        uintBitsToFloat(all_buffers[4].data[base + 5]),
        uintBitsToFloat(all_buffers[4].data[base + 6])
    );

    gl_Position = pc.mvp * vec4(pos, 1.0);
}
