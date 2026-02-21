#version 450

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  max_nodes;
    uint  num_items;
    float capacity;
    uint  start_idx;
    uint  num_to_process;
    uint  mode;
} pc;

layout(location = 0) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    if (pc.mode == 0) {
        float d = length(gl_PointCoord - vec2(0.5));
        if (d > 0.5) discard;
        float alpha = smoothstep(0.5, 0.2, d);
        outColor = vec4(vColor, alpha);
    } else {
        outColor = vec4(vColor, 0.5);
    }
}
