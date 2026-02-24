#version 450

layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vPos;
layout(location = 2) in float vLineDist;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPosition;

void main() {
    // 1. Calculate AA Coverage
    // vLineDist goes from -1 to 1 across the width of the line.
    // distance is 0 at center, 1 at edge.
    float dist = abs(vLineDist);
    
    // Smoothstep based on screen-space derivatives for pixel-perfect AA
    float delta = fwidth(dist);
    float alpha = smoothstep(1.0, 1.0 - delta, dist);
    
    if (alpha < 0.01) discard;

    // 2. Output with glow boost
    outColor = vec4(vColor.rgb * 1.5, vColor.a * alpha);
    outNormal = vec4(0, 0, 1, 1.0);
    outPosition = vec4(vPos, 1.0);
}
