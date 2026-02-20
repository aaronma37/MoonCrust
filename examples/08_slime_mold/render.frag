#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    uint texture_id;
} pc;

layout(location = 0) in vec2 inUV;
layout(location = 0) out vec4 outColor;

void main() {
    vec4 val = texture(all_textures[pc.texture_id], inUV);
    
    vec3 c1 = vec3(0.0, 0.0, 0.2); // Dark Blue
    vec3 c2 = vec3(0.0, 1.0, 0.5); // Teal/Green
    vec3 c3 = vec3(1.0, 1.0, 1.0); // White
    
    vec3 col;
    if (val.r < 0.5) {
        col = mix(c1, c2, val.r * 2.0);
    } else {
        col = mix(c2, c3, (val.r - 0.5) * 2.0);
    }
    
    outColor = vec4(col, 1.0);
}
