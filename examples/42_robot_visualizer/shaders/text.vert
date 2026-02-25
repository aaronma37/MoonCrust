#version 450
#extension GL_EXT_nonuniform_qualifier : enable

struct TextInstance {
    vec2 pos;
    vec2 size;
    vec2 uv;
    vec2 uv_size;
    uint color;
};

layout(set = 0, binding = 0) readonly buffer TEXT_SSBO {
    TextInstance instances[];
} text_data[];

layout(push_constant) uniform PC {
    uint ssbo_idx;
    uint padding;
    vec2 screen_size;
} pc;

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec4 vColor;

void main() {
    TextInstance inst = text_data[nonuniformEXT(pc.ssbo_idx)].instances[gl_InstanceIndex];
    
    vec2 quad[4] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );
    
    vec2 p = quad[gl_VertexIndex];
    vUV = inst.uv + p * inst.uv_size;
    
    // Unpack color (RGBA8_UNORM)
    vColor = vec4(
        float(inst.color & 0xFF) / 255.0,
        float((inst.color >> 8) & 0xFF) / 255.0,
        float((inst.color >> 16) & 0xFF) / 255.0,
        float((inst.color >> 24) & 0xFF) / 255.0
    );
    
    vec2 pixel_pos = inst.pos + p * inst.size;
    vec2 ndc = (pixel_pos / pc.screen_size) * 2.0 - 1.0;
    
    gl_Position = vec4(ndc, 0.0, 1.0);
}
