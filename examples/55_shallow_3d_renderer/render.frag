#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 in_norm;
layout(location = 1) in vec3 in_col;
layout(location = 2) in vec3 in_world_pos;
layout(location = 3) in vec3 in_cam_pos;
layout(location = 0) out vec4 out_col;

layout(set = 0, binding = 2, r32ui) uniform uimage3D all_storage_images[];

// MUST MATCH main.lua RenderPC byte-for-byte
layout(push_constant) uniform PushConstants {
    mat4 mvp;           // 0-63
    uint v_buf;         // 64-67
    uint signal_img;    // 68-71
    uint grid_w;        // 72-75
    uint grid_h;        // 76-79
    uint grid_d;        // 80-83
    uint p0, p1, p2;    // 84-95 (Padding)
    vec3 cam_pos;       // 96-107
} pc;

void main() {
    vec3 L = normalize(vec3(0.5, 1.0, 0.3));
    float dif = clamp(dot(in_norm, L), 0.2, 1.0);
    
    // Fixed Sampling: Go slightly INSIDE the voxel face to avoid row artifacts
    ivec3 p = ivec3(floor(in_world_pos - in_norm * 0.1));
    uint sig_raw = 0;
    if (all(greaterThanEqual(p, ivec3(0))) && all(lessThan(p, ivec3(pc.grid_w, pc.grid_h, pc.grid_d)))) {
        sig_raw = imageLoad(all_storage_images[nonuniformEXT(pc.signal_img)], p).r;
    }
    
    vec3 base_col = in_col * dif;
    if (sig_raw > 0) {
        base_col = mix(base_col, vec3(0.0, 1.0, 0.0), 0.5);
    }
    
    vec3 sky_color = vec3(0.5, 0.7, 0.9);
    float dist = distance(in_world_pos, pc.cam_pos);
    float fog = clamp((dist - 100.0) / 300.0, 0.0, 1.0);
    
    vec3 final_col = mix(base_col, sky_color, fog);
    out_col = vec4(final_col, 1.0);
}
