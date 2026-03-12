#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct SplatData {
    vec4 pos_radius; // xyz, radius
    vec4 color_alpha; // rgb, opacity
};

layout(set = 0, binding = 0) buffer B0 { SplatData s[]; } all_splats[];

layout(push_constant) uniform PushConstants {
    mat4 view;
    mat4 proj;
    uint s_id;
} pc;

layout(location = 0) out vec2 out_uv;
layout(location = 1) out vec4 out_color;

void main() {
    SplatData splat = all_splats[pc.s_id].s[gl_InstanceIndex];
    
    vec4 view_pos = pc.view * vec4(splat.pos_radius.xyz, 1.0);
    float radius = splat.pos_radius.w;

    vec2 offsets[4] = vec2[](vec2(-1,-1), vec2(1,-1), vec2(-1,1), vec2(1,1));
    vec2 offset = offsets[gl_VertexIndex % 4] * radius * 3.0; // 3-sigma

    // Billboard in view space
    view_pos.xy += offset;
    gl_Position = pc.proj * view_pos;

    out_uv = offsets[gl_VertexIndex % 4] * 3.0;
    out_color = splat.color_alpha;
}
