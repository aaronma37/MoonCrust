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
    {ivec3(1,0,0), ivec3(1,1,0), ivec3(1,1,1), ivec3(1,0,1)}, // +X
    {ivec3(0,0,1), ivec3(0,1,1), ivec3(0,1,0), ivec3(0,0,0)}, // -X
    {ivec3(0,1,1), ivec3(1,1,1), ivec3(1,1,0), ivec3(0,1,0)}, // +Y
    {ivec3(0,0,0), ivec3(1,0,0), ivec3(1,0,1), ivec3(0,0,1)}, // -Y
    {ivec3(1,0,1), ivec3(1,1,1), ivec3(0,1,1), ivec3(0,0,1)}, // +Z
    {ivec3(0,0,0), ivec3(0,1,0), ivec3(1,1,0), ivec3(1,0,0)}  // -Z
};

const vec3 normals[6] = {
    vec3(1,0,0), vec3(-1,0,0), vec3(0,1,0), vec3(0,-1,0), vec3(0,0,1), vec3(0,0,-1)
};

void main() {
    uint packed = world[nonuniformEXT(pc.v_buf)].data[gl_VertexIndex];
    // Unpacking: X(9), Y(7), Z(9), Norm(3), Col(4)
    vec3 pos;
    pos.x = float(packed & 511);
    pos.y = float((packed >> 9) & 127);
    pos.z = float((packed >> 16) & 511);
    uint norm_idx = (packed >> 25) & 7;
    uint type = (packed >> 28) & 15;

    vec3 corner = vec3(face_corners[norm_idx][gl_VertexIndex % 4]);
    vec3 world_pos = pos + corner;

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    out_norm = normals[norm_idx];
    
    const vec3 palette[16] = {
        vec3(0.0),             // 0: Empty
        vec3(0.3, 0.3, 0.35),  // 1: Floor 1
        vec3(0.4, 0.4, 0.45),  // 2: Floor 2
        vec3(1.0, 0.2, 0.2),   // 3: Red Pillar
        vec3(0.2, 1.0, 0.2),   // 4: Green Pillar
        vec3(0.2, 0.2, 1.0),   // 5: Blue Pillar
        vec3(1.0, 1.0, 0.2),   // 6: Yellow Pillar
        vec3(0.8, 0.5, 0.2),   // 7: Orange
        vec3(0.5, 0.8, 0.2),   // 8: Lime
        vec3(0.2, 0.8, 0.5),   // 9: Aqua
        vec3(0.8, 0.0, 0.8),   // 10: Player (Purple)
        vec3(0.5, 0.2, 0.8),   // 11
        vec3(0.8, 0.2, 0.5),   // 12
        vec3(0.5),             // 13
        vec3(0.7),             // 14
        vec3(1.0)              // 15
    };

    out_col = palette[type];
}
