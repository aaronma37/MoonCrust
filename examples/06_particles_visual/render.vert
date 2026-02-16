#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Particle {
    vec2 pos;
    vec2 vel;
};

layout(set = 0, binding = 0) buffer ParticleBuffer {
    Particle particles[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    float dt; // Padding to match compute shader
    uint particle_buffer_id;
} pc;

void main() {
    gl_Position = vec4(all_buffers[pc.particle_buffer_id].particles[gl_VertexIndex].pos, 0.0, 1.0);
    gl_PointSize = 1.0;
}
