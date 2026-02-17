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
    uint edge_idx = idx / 2;
    uint is_end = idx % 2;

    uint e_base = edge_idx * 4;
    uint nodeA = all_buffers[1].data[e_base + 0];
    uint nodeB = all_buffers[1].data[e_base + 1];
    uint node_idx = all_buffers[1].data[e_base + is_end];

    uint n_base = node_idx * 8;
    float x = uintBitsToFloat(all_buffers[0].data[n_base + 0]);
    float y = uintBitsToFloat(all_buffers[0].data[n_base + 1]);
    float z = uintBitsToFloat(all_buffers[0].data[n_base + 2]);

    vec3 color = vec3(0.1, 0.1, 0.2);
    uint target_node = all_buffers[3].data[2];
    uint target_sol = all_buffers[3].data[3];

    bool on_path = false;
    if (target_node != 0xFFFFFFFF) {
        uint curr_n = target_node;
        uint curr_s = target_sol;
        for (int i = 0; i < 64; i++) {
            uint s_base = (curr_n * 8 + curr_s) * 5;
            uint next_n = all_buffers[2].data[s_base + 3];
            uint next_s = all_buffers[2].data[s_base + 4];

            if (next_n != 0xFFFFFFFF && ((curr_n == nodeA && next_n == nodeB) || (curr_n == nodeB && next_n == nodeA))) {
                color = vec3(2.0, 1.6, 0.0);
                on_path = true;
                break;
            }
            if (curr_n == 0 || curr_n == 0xFFFFFFFF) {
                break;
            }
            curr_n = next_n;
            curr_s = next_s;
        }

        if (!on_path) {
            color = vec3(0.0);
        }
    }

    gl_Position = pc.mvp * vec4(x, y, z, 1.0);
    vColor = color;
}
