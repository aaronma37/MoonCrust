#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer GlobalBuffers { uint data[]; } world[];
layout(push_constant) uniform PushConstants {
    mat4 mvp;           // 0-63
    uint v_buf;         // 64-67
    uint light_img;     // 68-71
    uint grid_w;        // 72-75
    uint grid_h;        // 76-79
    uint grid_d;        // 80-83
    uint p0, p1, p2;    // 84-95 (Padding)
    vec3 cam_pos;       // 96-107
} pc;

layout(location = 0) out vec3 out_norm;
layout(location = 1) out vec3 out_col;
layout(location = 2) out vec3 out_world_pos;
layout(location = 3) out vec3 out_cam_pos;
layout(location = 4) flat out uint out_mat;

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

uint mat_to_col_idx(uint mat) {
    if (mat == 0) return 0;
    if (mat == 1) return 1;
    if (mat == 2) return 2;
    if (mat == 7) return 3;
    if (mat == 10) return 12; // Player
    if (mat == 20) return 5; // Wood (Brown)
    if (mat == 21) return 6; // Leaf (Green)
    if (mat == 30) return 14; // Seed (Bright Lime)
    if (mat >= 3 && mat <= 6) return 7 + (mat - 3);
    if (mat >= 8 && mat <= 9) return 11 + (mat - 8);
    return 1;
}

void main() {
    uint packed = world[nonuniformEXT(pc.v_buf)].data[gl_VertexIndex];
    ivec3 lp;
    lp.x = int(packed & 15);
    lp.y = int((packed >> 4) & 15);
    lp.z = int((packed >> 8) & 15);
    uint norm_idx = (packed >> 12) & 7;
    uint mat = (packed >> 15) & 255;
    uint ao = (packed >> 23) & 3;

    const uint MAX_VERTS_PER_CHUNK = 16384; // Corrected stride
    uint chunk_idx = gl_VertexIndex / MAX_VERTS_PER_CHUNK;
    uint chunks_per_row = pc.grid_w / 16;
    uint chunks_per_slice = (pc.grid_w / 16) * (pc.grid_h / 16);
    ivec3 chunk_origin;
    chunk_origin.z = int(chunk_idx / chunks_per_slice);
    chunk_origin.y = int((chunk_idx % chunks_per_slice) / chunks_per_row);
    chunk_origin.x = int(chunk_idx % chunks_per_row);
    chunk_origin *= 16;

    vec3 pos = vec3(chunk_origin + lp);
    vec3 corner = vec3(face_corners[norm_idx][gl_VertexIndex % 4]);
    vec3 world_pos = pos + corner;

    gl_Position = pc.mvp * vec4(world_pos, 1.0);
    out_norm = normals[norm_idx];
    out_world_pos = world_pos;
    out_cam_pos = pc.cam_pos;
    
    const vec3 palette[16] = {
        vec3(0.0),             // 0: Empty
        vec3(0.3, 0.3, 0.35),  // 1: Floor 1
        vec3(0.4, 0.4, 0.45),  // 2: Floor 2
        vec3(1.0, 0.2, 0.2),   // 3: Red Pillar
        vec3(0.2, 1.0, 0.2),   // 4: Green Pillar
        vec3(0.4, 0.25, 0.1),  // 5: Wood (Brown)
        vec3(0.1, 0.5, 0.1),   // 6: Leaf (Green)
        vec3(0.2, 0.2, 1.0),   // 7: Blue Pillar
        vec3(1.0, 1.0, 0.2),   // 8: Yellow Pillar
        vec3(0.8, 0.5, 0.2),   // 9: Orange
        vec3(0.5, 0.8, 0.2),   // 10: Lime
        vec3(0.2, 0.8, 0.5),   // 11: Aqua
        vec3(0.8, 0.0, 0.8),   // 12: Player (Purple)
        vec3(0.5, 0.2, 0.8),   // 13
        vec3(0.4, 1.0, 0.4),   // 14: Seed (Bright Lime)
        vec3(0.7)              // 15
    };

    float ao_mult = 0.4 + (float(ao) / 3.0) * 0.6;
    out_col = palette[mat_to_col_idx(mat)] * ao_mult;
    out_mat = mat;
}
