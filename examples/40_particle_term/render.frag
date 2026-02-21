#version 450

layout(location = 0) in vec3 in_color;

layout(location = 0) out vec4 out_frag_color;

void main() {
    // Circle point
    float dist = length(gl_PointCoord - vec2(0.5));
    if (dist > 0.5) discard;
    
    // Additive glow
    float glow = 1.0 - (dist * 2.0);
    out_frag_color = vec4(in_color * glow, 1.0);
}
