#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    uint img_idx;
} pc;

void main() {
    vec3 col = texture(all_textures[pc.img_idx], vUV).rgb;
    
    // Tonemapping & Gamma Correction
    col = col / (col + vec3(1.0));
    col = pow(col, vec3(1.0/2.2));
    
    outColor = vec4(col, 1.0);
}
