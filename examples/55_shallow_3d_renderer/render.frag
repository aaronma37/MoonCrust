#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 in_norm;
layout(location = 1) in vec3 in_col;
layout(location = 2) in vec3 in_world_pos;
layout(location = 3) in vec3 in_cam_pos;
layout(location = 4) flat in uint in_mat;
layout(location = 0) out vec4 out_col;

layout(set = 0, binding = 2, r32ui) uniform uimage3D all_storage_images[];
layout(set = 0, binding = 1) uniform sampler2D all_textures[];
layout(set = 0, binding = 1) uniform sampler3D all_volumes[];

// MUST MATCH main.lua RenderPC byte-for-byte
layout(push_constant) uniform PushConstants {
    mat4 mvp;           // 0-63
    mat4 light_mvp;     // 64-127
    uint v_buf;         // 128-131
    uint light_img;     // 132-135
    uint grid_w;        // 136-139
    uint grid_h;        // 140-143
    uint grid_d;        // 144-147
    uint macro_w, macro_h, macro_d; // 148-159
    uint shadow_idx;    // 160-163 (legacy)
    uint shadow_vol_idx; // 164-167
    float p0, p1;   
    vec3 cam_pos;       // 176-187
} pc;

vec3 unpack_light(uint raw) {
    if (raw == 0) return vec3(0.0);
    return vec3(float(raw & 0xFF), float((raw >> 8) & 0xFF), float((raw >> 16) & 0xFF)) / 255.0;
}

// Fast lookup for volumetric march
vec3 sample_macro_light_fast(vec3 world_pos) {
    ivec3 p = ivec3(world_pos / 8.0);
    uint raw = imageLoad(all_storage_images[nonuniformEXT(pc.light_img)], clamp(p, ivec3(0), ivec3(pc.macro_w-1, pc.macro_h-1, pc.macro_d-1))).r;
    return unpack_light(raw);
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

float get_shadow(vec3 world_pos) {
    vec3 uvw = world_pos / vec3(pc.grid_w, pc.grid_h, pc.grid_d);
    if (any(lessThan(uvw, vec3(0.0))) || any(greaterThanEqual(uvw, vec3(1.0)))) return 1.0;
    return texture(all_volumes[nonuniformEXT(pc.shadow_vol_idx)], uvw).r;
}

void main() {
    vec3 sun_dir = normalize(vec3(0.5, 1.0, 0.3));
    vec3 sky_color = vec3(0.5, 0.7, 0.9);

    float dif = clamp(dot(in_norm, sun_dir), 0.2, 1.0);
    float shadow = get_shadow(in_world_pos + in_norm * 0.1);
    
    // GI Indirect Light (Surface)
    vec3 indirect_light = sample_macro_light(in_world_pos + in_norm * 0.5);
    indirect_light = max(indirect_light, vec3(0.05));
    
    vec3 base_col = in_col * dif * (shadow * 0.8 + 0.2); 
    base_col += in_col * indirect_light * 1.5; 
    
    if (in_mat == 3) base_col = in_col * 2.0; 
    
    // --- GI-Aware Volumetric Fog ---
    vec3 ray_start = pc.cam_pos;
    vec3 ray_end = in_world_pos;
    vec3 ray_dir = ray_end - ray_start;
    float ray_dist = length(ray_dir);
    ray_dir /= ray_dist;
    
    float max_fog_dist = min(ray_dist, 200.0);
    int steps = 10; // Slightly lower steps to compensate for GI lookup
    vec3 volumetric_glow = vec3(0.0);
    
    for (int i = 0; i < steps; i++) {
        float t = (float(i) + 0.5) / float(steps) * max_fog_dist;
        vec3 p = ray_start + ray_dir * t;
        
        // Tie GI and Shadows together:
        // Use the actual GI color (sun + crystal + bounce)
        // Mask it with the crisp shadow volume for sharp rays
        float s = get_shadow(p);
        vec3 light_at_p = sample_macro_light_fast(p);
        
        volumetric_glow += (light_at_p * s) * 0.15;
    }
    volumetric_glow /= float(steps);
    volumetric_glow *= (max_fog_dist / 60.0); // Intensity scale
    
    float fog_factor = clamp((ray_dist - 100.0) / 300.0, 0.0, 1.0);
    vec3 final_col = mix(base_col, sky_color, fog_factor) + volumetric_glow;
    
    out_col = vec4(final_col, 1.0);
}
