#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out vec3 vNormal;

layout(set = 0, binding = 0) buffer Data { vec4 pos[]; } all_buffers[];

layout(push_constant) uniform PC {
    mat4 view_proj;
    uint buf_idx;
    float point_size;
} pc;

void main() {
    vec4 p = all_buffers[nonuniformEXT(pc.buf_idx)].pos[gl_VertexIndex];
    vec4 worldPos = vec4(p.xyz, 1.0);
    gl_Position = pc.view_proj * worldPos;
    gl_PointSize = pc.point_size;
    
    // Simple height-based color
    vColor = vec4(0.2, 0.5, 1.0, 1.0) * (p.z + 1.0);
    vPos = worldPos.xyz;
    vNormal = vec3(0.0, 0.0, 1.0); // Default normal for points
}