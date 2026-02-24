#version 450

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec3 vPos;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPosition;

void main() {
    // Grid settings
    float size = 1.0; // 1 meter grid
    float thickness = 0.02; // 2cm lines
    
    vec2 coord = vUV / size;
    vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
    float line = min(grid.x, grid.y);
    
    // Smooth anti-aliased lines
    float alpha = 1.0 - smoothstep(0.0, 1.0, line);
    
    // Fade out in distance
    float dist = length(vPos);
    alpha *= smoothstep(80.0, 20.0, dist);
    
    if (alpha < 0.01) discard;

    outColor = vec4(vec3(0.4, 0.4, 0.5) * alpha, alpha);
    outNormal = vec4(0, 0, 1, 1.0);
    outPosition = vec4(vPos, 1.0);
}
