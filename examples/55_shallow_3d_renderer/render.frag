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
    uint shadow_idx;    // 160-163
    float p0, p1, p2;   // Padding to keep vec3 aligned
    vec3 cam_pos;       // 176-187
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

float get_shadow(vec3 world_pos) {
    vec4 shadow_pos = pc.light_mvp * vec4(world_pos, 1.0);
    vec3 proj_coords = shadow_pos.xyz / shadow_pos.w;
    proj_coords.xy = proj_coords.xy * 0.5 + 0.5;
    
    // Boundary check: if outside light frustum, it's lit
    if (proj_coords.z > 1.0 || proj_coords.z < 0.0 || 
        proj_coords.x < 0.0 || proj_coords.x > 1.0 || 
        proj_coords.y < 0.0 || proj_coords.y > 1.0) return 1.0;
    
    float shadow = 0.0;
    vec2 texel_size = 1.0 / textureSize(all_textures[nonuniformEXT(pc.shadow_idx)], 0);
    float bias = 0.0005; 
    
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            float pcf_depth = texture(all_textures[nonuniformEXT(pc.shadow_idx)], proj_coords.xy + vec2(x, y) * texel_size).r;
            shadow += proj_coords.z - bias > pcf_depth ? 0.0 : 1.0;
        }
    }
    return shadow / 9.0;
}

void main() {
    vec3 L = normalize(vec3(0.5, 1.0, 0.3));
    float dif = clamp(dot(in_norm, L), 0.2, 1.0);
    
    float shadow = get_shadow(in_world_pos + in_norm * 0.1);
    
    // Sample macro light volume for indirect bounce
    vec3 indirect_light = sample_macro_light(in_world_pos + in_norm * 0.5);
    indirect_light = max(indirect_light, vec3(0.05));
    
    vec3 base_col = in_col * dif * (shadow * 0.8 + 0.2); // Sun contribution
    base_col += in_col * indirect_light * 1.5; // Ambient/Bounce contribution
    
    // Emissive Override
    if (in_mat == 3) {
        base_col = in_col * 2.0; 
    }
    
    vec3 sky_color = vec3(0.5, 0.7, 0.9);
    float dist = distance(in_world_pos, pc.cam_pos);
    float fog = clamp((dist - 100.0) / 300.0, 0.0, 1.0);
    
    vec3 final_col = mix(base_col, sky_color, fog);
    out_col = vec4(final_col, 1.0);
}

