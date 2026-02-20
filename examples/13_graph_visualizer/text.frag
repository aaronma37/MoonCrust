#version 450

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint mode;
} pc;

// SDF for a line segment
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Simple procedural glyphs
float get_sdf(uint c, vec2 p) {
    float d = 1e9;
    p = (p - 0.5) * 1.5 + 0.5; // Scale character slightly
    
    if (c == 0) { // 'P'
        d = min(d, sdSegment(p, vec2(0.3, 0.2), vec2(0.3, 0.8)));
        d = min(d, sdSegment(p, vec2(0.3, 0.8), vec2(0.6, 0.8)));
        d = min(d, sdSegment(p, vec2(0.6, 0.8), vec2(0.6, 0.5)));
        d = min(d, sdSegment(p, vec2(0.6, 0.5), vec2(0.3, 0.5)));
    } else if (c == 1) { // 'R'
        d = min(d, sdSegment(p, vec2(0.3, 0.2), vec2(0.3, 0.8)));
        d = min(d, sdSegment(p, vec2(0.3, 0.8), vec2(0.6, 0.8)));
        d = min(d, sdSegment(p, vec2(0.6, 0.8), vec2(0.6, 0.5)));
        d = min(d, sdSegment(p, vec2(0.6, 0.5), vec2(0.3, 0.5)));
        d = min(d, sdSegment(p, vec2(0.4, 0.5), vec2(0.7, 0.2)));
    } else if (c == 2) { // 'G'
        d = min(d, sdSegment(p, vec2(0.7, 0.7), vec2(0.3, 0.7)));
        d = min(d, sdSegment(p, vec2(0.3, 0.7), vec2(0.3, 0.3)));
        d = min(d, sdSegment(p, vec2(0.3, 0.3), vec2(0.7, 0.3)));
        d = min(d, sdSegment(p, vec2(0.7, 0.3), vec2(0.7, 0.5)));
        d = min(d, sdSegment(p, vec2(0.7, 0.5), vec2(0.5, 0.5)));
    }
    return d;
}

void main() {
    float d = get_sdf(pc.mode, vUV);
    
    // SDF antialiasing
    float thickness = 0.05;
    float edge = 0.01;
    float alpha = smoothstep(thickness + edge, thickness - edge, d);
    
    if (alpha < 0.01) discard;
    
    outColor = vec4(1.0, 1.0, 1.0, alpha);
}
