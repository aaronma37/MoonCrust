#version 450
#extension GL_EXT_nonuniform_qualifier : enable

struct Particle {
    vec4 pos;
    vec4 vel;
    float temp;
    uint cell_id;
    uint char_id;
    uint pad;
};

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint p_buf_id;
    uint t_buf_id;
    uint sdf_tex_id;
    uint term_w;
    uint term_h;
    uint particles_per_char;
} pc;

layout(set = 0, binding = 0) buffer ParticleBuffer { Particle p[]; } particles_heap[];

layout(location = 0) out vec3 out_color;

void main() {
    Particle p = particles_heap[nonuniformEXT(pc.p_buf_id)].p[gl_VertexIndex];
    
    gl_Position = vec4(p.pos.xyz, 1.0);
    gl_PointSize = 1.5;

    // Visibility: Based on p.pos.w (0 = stroke, 1 = void)
    float visibility = 1.0 - smoothstep(0.0, 0.5, p.pos.w);
    
    out_color = vec3(0.1, 0.8, 0.2) * visibility;
    out_color += vec3(1.0, 0.4, 0.1) * p.temp;
}
