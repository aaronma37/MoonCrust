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
    vec3 world_pos;
    vec3 color;
    float size;

    if (pc.mode == 1) {
        world_pos = vec3(pc.obs_x, pc.obs_y, pc.obs_z);
        color = vec3(1.2, 0.1, 0.1);
        size = pc.obs_r * 40.0;
    } else if (pc.mode == 2) {
        if (idx == 0) {
            world_pos = vec3(pc.rew1_x, pc.rew1_y, pc.rew1_z);
            size = pc.rew1_r * 34.0;
        } else if (idx == 1) {
            world_pos = vec3(pc.rew2_x, pc.rew2_y, pc.rew2_z);
            size = pc.rew2_r * 34.0;
        } else if (idx == 2) {
            world_pos = vec3(pc.rew3_x, pc.rew3_y, pc.rew3_z);
            size = pc.rew3_r * 34.0;
        } else {
            world_pos = vec3(pc.rew4_x, pc.rew4_y, pc.rew4_z);
            size = pc.rew4_r * 34.0;
        }
        color = vec3(0.2, 1.3, 0.2);
    } else {
        uint n_base = idx * 8;
        world_pos = vec3(
            uintBitsToFloat(all_buffers[0].data[n_base + 0]),
            uintBitsToFloat(all_buffers[0].data[n_base + 1]),
            uintBitsToFloat(all_buffers[0].data[n_base + 2])
        );

        color = vec3(
            uintBitsToFloat(all_buffers[0].data[n_base + 4]),
            uintBitsToFloat(all_buffers[0].data[n_base + 5]),
            uintBitsToFloat(all_buffers[0].data[n_base + 6])
        );
        size = 3.0;
    }

    uint target_node = all_buffers[3].data[2];
    uint target_sol = all_buffers[3].data[3];

    if (pc.mode == 0 && target_node != 0xFFFFFFFF) {
        uint curr_n = target_node;
        uint curr_s = target_sol;
        for (int i = 0; i < 64; i++) {
            if (curr_n == idx) {
                color = vec3(2.0, 1.8, 0.2);
                size = 12.0;
                break;
            }
            if (curr_n == 0xFFFFFFFF || curr_n == 0) {
                break;
            }
            uint s_base = (curr_n * 8 + curr_s) * 5;
            uint next_n = all_buffers[2].data[s_base + 3];
            uint next_s = all_buffers[2].data[s_base + 4];
            curr_n = next_n;
            curr_s = next_s;
        }
    }

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    vColor = color;
    gl_PointSize = size / (gl_Position.w * 0.1);
}
