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

bool edge_on_goal_path(uint node_idx, uint parent_idx, uint goal_idx) {
    uint cur = goal_idx;
    for (int i = 0; i < 256; i++) {
        if (cur == 0u || cur == 0xFFFFFFFFu) break;
        uint base = cur * 8u;
        uint p = all_buffers[0].data[base + 6];
        if (cur == node_idx && p == parent_idx) return true;
        cur = p;
    }
    return false;
}

void main() {
    uint vidx = gl_VertexIndex;
    uint eidx = vidx / 2u;
    uint endpoint = vidx % 2u;

    uint node_idx = eidx + 1u;
    if (node_idx >= pc.node_count) {
        gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
        vColor = vec3(0.0);
        return;
    }

    uint nbase = node_idx * 8u;
    uint parent_idx = all_buffers[0].data[nbase + 6];
    uint draw_idx = endpoint == 0u ? node_idx : parent_idx;

    uint dbase = draw_idx * 8u;
    vec3 p = vec3(
        uintBitsToFloat(all_buffers[0].data[dbase + 0]),
        uintBitsToFloat(all_buffers[0].data[dbase + 1]),
        uintBitsToFloat(all_buffers[0].data[dbase + 2])
    );

    vec3 color = vec3(0.006, 0.012, 0.026);
    uint goal_idx = all_buffers[3].data[3];
    if (goal_idx != 0xFFFFFFFFu) {
        if (edge_on_goal_path(node_idx, parent_idx, goal_idx)) {
            color = vec3(3.2, 2.4, 0.3);
        } else {
            color = vec3(0.0025, 0.005, 0.012);
        }
    }

    gl_Position = pc.mvp * vec4(p, 1.0);
    vColor = color;
}
