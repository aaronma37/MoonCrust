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

    uint base = idx * 5;
    float dist = uintBitsToFloat(all_buffers[2].data[base + 0]);
    float cost = uintBitsToFloat(all_buffers[2].data[base + 1]);
    float reward = uintBitsToFloat(all_buffers[2].data[base + 2]);

    if (dist > 1e8) {
        gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
        return;
    }

    float x = clamp((dist / 40.0) - 0.95, -0.95, 0.95);
    float y = clamp(-((cost / 40.0) - 0.95), -0.95, 0.95);
    float z = clamp((reward / 20.0) - 0.95, -0.95, 0.95);

    gl_Position = pc.mvp * vec4(x, y, z, 1.0);
    gl_PointSize = 9.0;

    float t = clamp((z + 0.95) * 0.5, 0.0, 1.0);
    vColor = mix(vec3(1.0, 0.8, 0.2), vec3(0.2, 1.0, 0.2), t);
}
