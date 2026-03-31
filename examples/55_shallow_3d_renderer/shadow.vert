#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer GlobalBuffers { uint data[]; } world[];
layout(push_constant) uniform PushConstants {
    mat4 mvp;           
    uint v_buf;         
    uint light_img;     
    uint grid_w;        
    uint grid_h;        
    uint grid_d;
    uint p0, p1, p2;
} pc;

const ivec3 face_corners[6][4] = {
    {ivec3(1,0,0), ivec3(1,1,0), ivec3(1,1,1), ivec3(1,0,1)}, // +X
    {ivec3(0,0,1), ivec3(0,1,1), ivec3(0,1,0), ivec3(0,0,0)}, // -X
    {ivec3(0,1,1), ivec3(1,1,1), ivec3(1,1,0), ivec3(0,1,0)}, // +Y
    {ivec3(0,0,0), ivec3(1,0,0), ivec3(1,0,1), ivec3(0,0,1)}, // -Y
    {ivec3(1,0,1), ivec3(1,1,1), ivec3(0,1,1), ivec3(0,0,1)}, // +Z
    {ivec3(0,0,0), ivec3(0,1,0), ivec3(1,1,0), ivec3(1,0,0)}  // -Z
};

void main() {
    uint packed = world[nonuniformEXT(pc.v_buf)].data[gl_VertexIndex];
    ivec3 lp;
    lp.x = int(packed & 15);
    lp.y = int((packed >> 4) & 15);
    lp.z = int((packed >> 8) & 15);
    uint norm_idx = (packed >> 12) & 7;

    const uint MAX_VERTS_PER_CHUNK = 16384; 
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
}
