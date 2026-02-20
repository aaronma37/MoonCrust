#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inWorldPos;

layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outMRA;
layout(location = 3) out vec4 outWorldPos;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
    vec4 cam_pos;
    vec4 light_pos;
    vec4 base_color;
    mat4 light_space;
    float time;
    uint albedo_idx;
    uint normal_idx;
    uint mra_idx;
} pc;

void main() {
    vec4 albedo = pc.base_color;
    if (pc.albedo_idx != 0xFFFFFFFF) {
        albedo *= texture(all_textures[nonuniformEXT(pc.albedo_idx)], inUV);
    }
    if (albedo.a < 0.5) discard;

    float metallic = 0.0;
    float roughness = 0.8;
    if (pc.mra_idx != 0xFFFFFFFF) {
        vec4 mra = texture(all_textures[nonuniformEXT(pc.mra_idx)], inUV);
        roughness = mra.g;
        metallic = mra.b;
    }

    outAlbedo = vec4(albedo.rgb, 1.0);
    outNormal = vec4(normalize(inNormal) * 0.5 + 0.5, 1.0);
    outMRA = vec4(metallic, roughness, 0.0, 1.0);
    outWorldPos = vec4(inWorldPos, 1.0);
}
