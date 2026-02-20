#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inWorldPos;

layout(location = 0) out vec4 outFlux;   // RSM Flux (Color)
layout(location = 1) out vec4 outNormal; // RSM Normal

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

    outFlux = vec4(albedo.rgb, 1.0);
    outNormal = vec4(normalize(inNormal) * 0.5 + 0.5, 1.0);
}
