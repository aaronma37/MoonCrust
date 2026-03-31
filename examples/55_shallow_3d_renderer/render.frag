#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 in_norm;
layout(location = 1) in vec3 in_col;
layout(location = 2) in vec3 in_world_pos;
layout(location = 3) in vec3 in_cam_pos;
layout(location = 4) flat in uint in_mat;
layout(location = 0) out vec4 out_col;

layout(set = 0, binding = 2, r32ui) uniform uimage3D all_storage_images[];

// MUST MATCH main.lua RenderPC byte-for-byte
layout(push_constant) uniform PushConstants {
    mat4 mvp;           // 0-63
    uint v_buf;         // 64-67
    uint light_img;     // 68-71
    uint grid_w;        // 72-75
    uint grid_h;        // 76-79
    uint grid_d;        // 80-83
    uint macro_w, macro_h, macro_d; // 84-95
    vec3 cam_pos;       // 96-107
} pc;

vec3 unpack_light(uint raw) {
    if (raw == 0) return vec3(0.0);
    return vec3(float(raw & 0xFF), float((raw >> 8) & 0xFF), float((raw >> 16) & 0xFF)) / 255.0;
}

vec3 sample_macro_light(vec3 world_pos) {
    vec3 p = (world_pos / 8.0) - vec3(0.5);
    ivec3 p0 = ivec3(floor(p));
    vec3 f = fract(p);
    
    vec3 c000 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(0,0,0), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c100 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(1,0,0), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c010 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(0,1,0), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c110 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(1,1,0), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c001 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(0,0,1), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c101 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(1,0,1), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c011 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(0,1,1), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    vec3 c111 = unpack_light(imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p0 + ivec3(1,1,1), ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r);
    
    vec3 c00 = mix(c000, c100, f.x);
    vec3 c01 = mix(c001, c101, f.x);
    vec3 c10 = mix(c010, c110, f.x);
    vec3 c11 = mix(c011, c111, f.x);
    
    vec3 c0 = mix(c00, c10, f.y);
    vec3 c1 = mix(c01, c11, f.y);
    
    return mix(c0, c1, f.z);
}

void main() {
    vec3 L = normalize(vec3(0.5, 1.0, 0.3));
    float dif = clamp(dot(in_norm, L), 0.2, 1.0);
    
    // Sample macro light volume with trilinear interpolation
    vec3 light_color = sample_macro_light(in_world_pos + in_norm * 0.5);
    
    // Smooth ambient floor to avoid dark ring artifacts
    light_color = max(light_color, vec3(0.05));
    
    vec3 base_col = in_col * dif;
    base_col *= light_color * 2.5; // Boost light intensity for visibility
    
    // Emissive Override
    if (in_mat == 3) {
        base_col = in_col * 2.0; // Glow brightly, ignore shadows
    }
    
    vec3 sky_color = vec3(0.5, 0.7, 0.9);
    float dist = distance(in_world_pos, pc.cam_pos);
    float fog = clamp((dist - 100.0) / 300.0, 0.0, 1.0);
    
    vec3 final_col = mix(base_col, sky_color, fog);
    out_col = vec4(final_col, 1.0);
}
