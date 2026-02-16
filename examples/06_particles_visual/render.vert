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
    float dt;
    float time;
    uint particle_buffer_id;
    uint texture_id;
} pc;

layout(location = 0) out float vSpeed;

void main() {
    uint bid = pc.particle_buffer_id;
    vec2 pos = all_buffers[bid].particles[gl_VertexIndex].pos;
    vec2 vel = all_buffers[bid].particles[gl_VertexIndex].vel;
    
    gl_Position = vec4(pos, 0.0, 1.0);
    gl_PointSize = 2.5; 
    
    // Pass speed to fragment shader for coloring
    vSpeed = length(vel);
}
