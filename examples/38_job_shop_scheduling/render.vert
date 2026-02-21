#version 450

layout(set = 0, binding = 3) buffer RenderBuffer {
    vec4 rects[];
} render_data;

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  pop_size;
    uint  best_idx;
    float max_span;
} pc;

layout(location = 0) out vec3 vColor;

vec3 get_job_color(float id) {
    float phi = id * 3.14159 * 2.0;
    return 0.5 + 0.5 * cos(vec3(0, 2, 4) + phi);
}

void main() {
    // Instance ID = Operation Index
    uint op_idx = gl_InstanceIndex;
    vec4 data = render_data.rects[op_idx];
    
    float start = data.x;
    float machine = data.y;
    float duration = data.z;
    float job_id = data.w;

    // Quad Vertex Logic
    vec2 pos = vec2(0.0);
    // 0: TL, 1: BL, 2: TR, 3: BR (Triangle Strip)
    if (gl_VertexIndex == 0) pos = vec2(0, 0);
    else if (gl_VertexIndex == 1) pos = vec2(0, 1);
    else if (gl_VertexIndex == 2) pos = vec2(1, 0);
    else pos = vec2(1, 1);

    // Map Time to X [-0.9, 0.9]
    // Map Machine to Y [-0.9, 0.9]
    float span = max(100.0, pc.max_span);
    
    float x = (start + pos.x * duration) / span;
    // Map [0, 1] -> [-0.95, 0.95]
    x = -0.95 + x * 1.9;
    
    float y = (machine + pos.y * 0.8) / 16.0; // 16 machines
    // Flip Y and map to screen
    y = -0.9 + y * 1.8;

    gl_Position = vec4(x, y, 0.0, 1.0);
    vColor = get_job_color(job_id);
}
