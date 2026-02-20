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

float hash11(float x) {
    return fract(sin(x * 127.1 + 311.7) * 43758.5453123);
}

vec3 obstacle_pos(uint i, float t, vec3 start, vec3 goal) {
    vec3 dir = normalize(goal - start);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 u = normalize(cross(dir, up));
    vec3 v = normalize(cross(dir, u));

    float lane = 0.08 + 0.84 * hash11(float(i) + 1.0);
    float phase_a = 1.37 * float(i) + 0.7;
    float phase_b = 2.11 * float(i) + 1.9;
    float w1 = 0.35 + 0.07 * float(i);
    float w2 = 0.47 + 0.05 * float(i);
    float along_jitter = 0.12 * sin(t * (0.28 + 0.04 * float(i)) + phase_b);

    float along = clamp(lane + along_jitter, 0.08, 0.92);
    float path_len = length(goal - start);
    vec3 center = start + dir * (path_len * along);
    float off_u = sin(t * w1 + phase_a) * (1.1 + 0.2 * float(i % 2u));
    float off_v = cos(t * w2 + phase_b) * (1.0 + 0.15 * float((i + 1u) % 2u));
    return center + u * off_u + v * off_v;
}

float obstacle_radius(uint i) {
    return 0.58 + 0.06 * float(i % 6u);
}

bool on_goal_path(uint idx, uint goal_idx) {
    uint cur = goal_idx;
    for (int i = 0; i < 256; i++) {
        if (cur == idx) return true;
        if (cur == 0u || cur == 0xFFFFFFFFu) break;
        uint base = cur * 8u;
        cur = all_buffers[0].data[base + 6];
    }
    return false;
}

void main() {
    uint idx = gl_VertexIndex;
    vec3 world_pos;
    vec3 color;
    float size;

    if (pc.mode == 1u) {
        if (idx == 0u) {
            world_pos = vec3(pc.goal_x, pc.goal_y, pc.goal_z);
            color = vec3(1.2, 1.2, 0.2);
            size = pc.goal_r * 45.0;
        } else {
            uint oi = idx - 1u;
            vec3 start = vec3(-8.5, -2.0, -8.5);
            vec3 goal = vec3(pc.goal_x, pc.goal_y, pc.goal_z);
            world_pos = obstacle_pos(oi, pc.sim_t, start, goal);
            color = vec3(1.1, 0.15, 0.15);
            size = obstacle_radius(oi) * 42.0;
        }
    } else {
        if (idx >= pc.node_count) {
            gl_Position = vec4(3.0, 3.0, 3.0, 1.0);
            vColor = vec3(0.0);
            gl_PointSize = 1.0;
            return;
        }

        uint base = idx * 8u;
        world_pos = vec3(
            uintBitsToFloat(all_buffers[0].data[base + 0]),
            uintBitsToFloat(all_buffers[0].data[base + 1]),
            uintBitsToFloat(all_buffers[0].data[base + 2])
        );

        color = vec3(0.10, 0.32, 0.75);
        size = 2.5;

        uint goal_idx = all_buffers[3].data[3];
        if (idx == 0u) {
            color = vec3(0.2, 1.2, 0.3);
            size = 8.0;
        } else if (goal_idx != 0xFFFFFFFFu && on_goal_path(idx, goal_idx)) {
            color = vec3(2.8, 2.2, 0.25);
            size = 14.0;
        } else if (goal_idx != 0xFFFFFFFFu) {
            color = vec3(0.04, 0.10, 0.24);
            size = 2.0;
        }
    }

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    vColor = color;
    gl_PointSize = size / max(gl_Position.w * 0.1, 0.1);
}
