#version 450

struct Particle {
    vec2 pos;
    vec2 vel;
};

layout(set = 0, binding = 0) buffer ParticleBuffer {
    Particle particles[];
};

void main() {
    gl_Position = vec4(particles[gl_VertexIndex].pos, 0.0, 1.0);
    gl_PointSize = 1.0;
}
