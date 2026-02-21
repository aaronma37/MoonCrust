#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  buf_id;
    uint  tex_id;
} pc;

layout(location = 0) in float vSpeed;
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(all_textures[pc.tex_id], gl_PointCoord);
    
    // Three-step "Heat Map" Ramp
    vec3 cLow  = vec3(1.0, 0.05, 0.0); // Red
    vec3 cMid  = vec3(0.1, 1.0, 0.1); // Green
    vec3 cHigh = vec3(0.0, 0.3, 1.0); // Blue
    
    // Balanced factor (Speed usually ranges 0.0 to 3.0+ now)
    float f = clamp(vSpeed * 0.3, 0.0, 1.0);
    
    vec3 finalRGB;
    if (f < 0.5) {
        finalRGB = mix(cLow, cMid, f * 2.0);
    } else {
        finalRGB = mix(cMid, cHigh, (f - 0.5) * 2.0);
    }
    
    // Toned down intensity and included alpha in color for additive blend
    outColor = vec4(tex.rgb * finalRGB * (tex.a * tex.a) * 0.7, tex.a);
}
