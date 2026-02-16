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
    float time;
    uint particle_buffer_id;
    uint texture_id;
} pc;

layout(location = 0) out float vSpeed;

void main() {
    uint bid = pc.particle_buffer_id;
    vec3 world_pos = all_buffers[bid].particles[gl_VertexIndex].pos;
    
    // 3D Offset: Move everything back by 2 units so it's always in front of camera
    vec3 view_pos = world_pos + vec3(0.0, 0.0, 2.5);
    
    // Standard perspective: x' = x/z, y' = y/z
    // We use a small FOV multiplier (1.5)
    float fov = 1.5;
    gl_Position = vec4(view_pos.xy * fov, view_pos.z * 0.1, view_pos.z);
    
    // Correct Vulkan Depth mapping (z/w will be in [0, 1])
    // The view_pos.z in the 'w' component handles the perspective divide.
    
    // Scale point size inversely with distance (w)
    gl_PointSize = 4.0 / view_pos.z; 
    
    vSpeed = length(all_buffers[bid].particles[gl_VertexIndex].vel);
}
