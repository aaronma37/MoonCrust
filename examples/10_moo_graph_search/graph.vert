#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec3 vColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    float obs_x, obs_y, obs_z, obs_r;
    uint mode; // 0 = Nodes, 1 = Obstacle
} pc;

void main() {
    uint idx = gl_VertexIndex;
    vec3 world_pos;
    vec3 color;
    float size;

    if (pc.mode == 1) { // Obstacle Pass
        world_pos = vec3(pc.obs_x, pc.obs_y, pc.obs_z);
        color = vec3(1.2, 0.1, 0.1);
        size = pc.obs_r * 40.0;
    } else {
        uint n_base = idx * 8;
        world_pos = vec3(uintBitsToFloat(all_buffers[0].data[n_base + 0]),
                         uintBitsToFloat(all_buffers[0].data[n_base + 1]),
                         uintBitsToFloat(all_buffers[0].data[n_base + 2]));
        
        color = vec3(uintBitsToFloat(all_buffers[0].data[n_base+4]), 
                     uintBitsToFloat(all_buffers[0].data[n_base+5]), 
                     uintBitsToFloat(all_buffers[0].data[n_base+6]));
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
            if (curr_n == 0xFFFFFFFF || curr_n == 0) break;
            uint s_base = (curr_n * 8 + curr_s) * 4;
            uint next_n = all_buffers[2].data[s_base + 2];
            uint next_s = all_buffers[2].data[s_base + 3];
            curr_n = next_n;
            curr_s = next_s;
        }
    }

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    vColor = color;
    gl_PointSize = size / (gl_Position.w * 0.1);
}
