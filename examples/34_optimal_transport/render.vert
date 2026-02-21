#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Particle {
    vec2 current_pos;
    vec2 source_pos;
    vec2 target_pos;
    float u;
    float v;
};

layout(set = 0, binding = 0) buffer ParticleBuffer {
    Particle p[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  buf_id;
    uint  num_particles;
    float epsilon;
    uint  mode;
} pc;

layout(location = 0) out vec3 vColor;

void main() {
    uint idx = gl_VertexIndex;
    uint bid = pc.buf_id;
    Particle part = all_buffers[bid].p[idx];

    gl_Position = vec4(part.current_pos, 0.0, 1.0);
    gl_PointSize = 4.0;

    float flow = distance(part.current_pos, part.source_pos) * 2.0;
    vColor = mix(vec3(0.1, 0.4, 1.0), vec3(1.0, 0.2, 0.5), clamp(flow, 0.0, 1.0));
    vColor *= 1.5; 
}
