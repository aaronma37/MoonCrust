#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer GlobalBuffers { uint data[]; } world[];

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint v_buf;
} pc;

layout(location = 0) out vec3 out_norm;
layout(location = 1) out vec3 out_col;

const ivec3 face_corners[6][4] = {
    {ivec3(1,0,1), ivec3(1,1,1), ivec3(1,1,0), ivec3(1,0,0)}, // +X
    {ivec3(0,0,0), ivec3(0,1,0), ivec3(0,1,1), ivec3(0,0,1)}, // -X
    {ivec3(0,1,0), ivec3(1,1,0), ivec3(1,1,1), ivec3(0,1,1)}, // +Y
    {ivec3(0,0,1), ivec3(1,0,1), ivec3(1,0,0), ivec3(0,0,0)}, // -Y
    {ivec3(0,0,1), ivec3(0,1,1), ivec3(1,1,1), ivec3(1,0,1)}, // +Z
    {ivec3(1,0,0), ivec3(1,1,0), ivec3(0,1,0), ivec3(0,0,0)}  // -Z
};

const vec3 normals[6] = {
    vec3(1,0,0), vec3(-1,0,0), vec3(0,1,0), vec3(0,-1,0), vec3(0,0,1), vec3(0,0,-1)
};

void main() {
    uint packed = world[nonuniformEXT(pc.v_buf)].data[gl_VertexIndex];
    vec3 pos = vec3(packed & 255, (packed >> 8) & 255, (packed >> 16) & 255);
    uint norm_idx = (packed >> 24) & 7;
    uint type = (packed >> 27) & 15;

    vec3 corner = vec3(face_corners[norm_idx][gl_VertexIndex % 4]);
    vec3 world_pos = pos + corner;

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    out_norm = normals[norm_idx];
    
    // Color based on height + variation
    vec3 base_col = mix(vec3(0.2, 0.7, 0.3), vec3(0.8, 0.9, 1.0), pos.y / 128.0);
    out_col = base_col;
}
