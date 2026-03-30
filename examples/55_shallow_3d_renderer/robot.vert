#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in uint packed_v;

layout(push_constant) uniform PC {
    mat4 mvp;
    vec3 pos;
    float yaw;
} pc;

layout(location = 0) out vec3 out_norm;
layout(location = 1) out vec3 out_col;
layout(location = 2) out vec3 out_world_pos;
layout(location = 3) out vec3 out_cam_pos;

const vec3 normals[6] = {
    vec3(1,0,0), vec3(-1,0,0), vec3(0,1,0), vec3(0,-1,0), vec3(0,0,1), vec3(0,0,-1)
};

const ivec3 face_corners[6][4] = {
    {ivec3(1,0,0), ivec3(1,1,0), ivec3(1,1,1), ivec3(1,0,1)}, // +X
    {ivec3(0,0,1), ivec3(0,1,1), ivec3(0,1,0), ivec3(0,0,0)}, // -X
    {ivec3(0,1,1), ivec3(1,1,1), ivec3(1,1,0), ivec3(0,1,0)}, // +Y
    {ivec3(0,0,0), ivec3(1,0,0), ivec3(1,0,1), ivec3(0,0,1)}, // -Y
    {ivec3(1,0,1), ivec3(1,1,1), ivec3(0,1,1), ivec3(0,0,1)}, // +Z
    {ivec3(0,0,0), ivec3(0,1,0), ivec3(1,1,0), ivec3(1,0,0)}  // -Z
};

void main() {
    // Unpack: lp.x(4), lp.y(4), lp.z(4), norm(3), mat(8), ao(2)
    vec3 lp = vec3(packed_v & 15, (packed_v >> 4) & 15, (packed_v >> 8) & 15);
    uint norm_idx = (packed_v >> 12) & 7;
    uint mat = (packed_v >> 15) & 255;
    uint ao = (packed_v >> 23) & 3;

    // Robot Pivot (Centered X/Z, Bottom Y)
    vec3 local_pivot = vec3(1.0, 0.0, 1.0);
    vec3 p = lp - local_pivot;
    vec3 corner = vec3(face_corners[norm_idx][gl_VertexIndex % 4]);
    p += corner;

    // Smooth Yaw Rotation
    float s = sin(pc.yaw);
    float c = cos(pc.yaw);
    vec3 rotated_p = vec3(p.x * c - p.z * s, p.y, p.x * s + p.z * c);
    
    vec3 world_pos = pc.pos + rotated_p;
    gl_Position = pc.mvp * vec4(world_pos, 1.0);

    vec3 n = normals[norm_idx];
    out_norm = vec3(n.x * c - n.z * s, n.y, n.x * s + n.z * c);
    out_col = vec3(0.8, 0.3, 0.8); // Purple Robot
    out_world_pos = world_pos;
    out_cam_pos = pc.pos; // Approximate
}
