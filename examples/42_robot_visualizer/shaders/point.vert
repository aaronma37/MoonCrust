#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;

layout(set = 0, binding = 0) buffer Data { vec4 pos[]; } all_buffers[];

layout(push_constant) uniform PC {
    mat4 view_proj;
    uint buf_idx;
    float point_size;
} pc;

void main() {
    vec4 p = all_buffers[nonuniformEXT(pc.buf_idx)].pos[gl_VertexIndex];
    gl_Position = pc.view_proj * vec4(p.xyz, 1.0);
    gl_PointSize = pc.point_size;
    
    // Simple height-based color with topological bands
    float h = 0.8 + 0.4 * fract(p.z * 0.5);
    vColor = vec4(0.4, 0.7, 1.0, 1.0) * h + vec4(0.1, 0.3, 0.6, 0.0);
}
