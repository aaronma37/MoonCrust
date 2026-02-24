#version 450

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec3 vPos;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPosition;

float grid(vec2 uv, float res) {
    vec2 coord = uv * res;
    vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
    float line = min(grid.x, grid.y);
    return 1.0 - smoothstep(0.0, 1.0, line);
}

void main() {
    vec2 uv = vUV;
    
    // Multi-level grid
    float g1 = grid(uv, 1.0);  // 1m grid
    float g2 = grid(uv, 0.1);  // 10m grid
    
    // Base colors
    vec3 col1 = vec3(0.3, 0.3, 0.35); // Minor lines
    vec3 col2 = vec3(0.5, 0.5, 0.6);  // Major lines
    
    // Radial fade for the whole grid
    float dist = length(vPos);
    float mask = smoothstep(100.0, 20.0, dist);
    
    // Axial highlights (X and Y axes)
    float ax = 1.0 - smoothstep(0.0, 0.1, abs(uv.x));
    float ay = 1.0 - smoothstep(0.0, 0.1, abs(uv.y));
    vec3 axisCol = vec3(0);
    if (ax > 0.1) axisCol = vec3(0.2, 0.6, 0.2) * ax; // Y axis is Green in many conventions (or X is Red)
    if (ay > 0.1) axisCol = vec3(0.6, 0.2, 0.2) * ay; // X axis is Red
    
    vec3 finalCol = mix(col1 * g1, col2, g2);
    float finalAlpha = max(g1 * 0.5, g2) * mask;
    
    if (ax > 0.0 || ay > 0.0) {
        finalCol = mix(finalCol, axisCol, max(ax, ay));
        finalAlpha = max(finalAlpha, max(ax, ay) * mask);
    }

    if (finalAlpha < 0.01) discard;

    outColor = vec4(finalCol, finalAlpha * 0.5);
    outNormal = vec4(0, 0, 1, 1.0);
    outPosition = vec4(vPos, 1.0);
}
