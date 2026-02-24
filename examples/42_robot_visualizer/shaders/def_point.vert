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
    vec4 pose_offset; // [x, y, z, yaw]
} pc;

void main() {
    vec4 p = all_buffers[nonuniformEXT(pc.buf_idx)].pos[gl_VertexIndex];
    
    // Rotate and Translate if pose_offset is provided
    float s = sin(pc.pose_offset.w);
    float c = cos(pc.pose_offset.w);
    vec3 worldPos;
    worldPos.x = p.x * c - p.y * s + pc.pose_offset.x;
    worldPos.y = p.x * s + p.y * c + pc.pose_offset.y;
    worldPos.z = p.z + pc.pose_offset.z;

    gl_Position = pc.view_proj * vec4(worldPos, 1.0);
    gl_PointSize = pc.point_size;
    
    vColor = vec4(0.2, 0.5, 1.0, 1.0) * (p.z + 1.0);
    vPos = worldPos;
    vNormal = vec3(0.0, 0.0, 1.0);
}