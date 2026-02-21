#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Particle {
    vec3 pos;
    float p1;
    vec3 vel;
    float p2;
};

layout(set = 0, binding = 0) buffer ParticleBuffer {
    Particle particles[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    float dt;
    uint  buf_id;
    uint  attr_id;
    uint  tex_id;
} pc;

layout(location = 0) out float vSpeed;

void main() {
    uint bid = pc.buf_id;
    vec3 world_pos = all_buffers[bid].particles[gl_VertexIndex].pos;
    vec3 vel = all_buffers[bid].particles[gl_VertexIndex].vel;

    vec3 view_pos = world_pos + vec3(0.0, 0.0, 4.5);
    float fov = 1.5;
    gl_Position = vec4(view_pos.xy * fov, view_pos.z * 0.1, view_pos.z);
    gl_PointSize = 4.0; 
    
    vSpeed = length(vel);
}
