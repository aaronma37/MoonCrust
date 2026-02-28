#version 450
layout(location = 0) in vec2 inUV;
layout(location = 0) out vec4 outColor;

layout(push_constant) uniform PC {
    float time;
    float width;
    float height;
} pc;

void main() {
    vec2 uv = inUV;
    // Calculate aspect ratio
    float aspect = pc.width / pc.height;
    
    // Create a modern, dark gradient background
    vec3 colorTop = vec3(0.02, 0.02, 0.04);
    vec3 colorBottom = vec3(0.05, 0.07, 0.12);
    vec3 baseColor = mix(colorTop, colorBottom, uv.y);
    
    // Create a subtle, moving "tech" grid
    vec2 gridUV = uv * vec2(aspect, 1.0) * 15.0; // Scale of grid
    gridUV.y += pc.time * 0.1; // Slowly pan grid down
    gridUV.x += sin(pc.time * 0.05) * 0.2; // Slight horizontal sway
    
    // Grid lines using fwidth for anti-aliasing
    vec2 grid = abs(fract(gridUV - 0.5) - 0.5) / fwidth(gridUV);
    float line = min(grid.x, grid.y);
    
    // Add glowing intersections
    vec2 gridCells = floor(gridUV);
    float glow = sin(gridCells.x * 13.0 + gridCells.y * 7.0 + pc.time) * 0.5 + 0.5;
    glow = pow(glow, 5.0) * 0.3; // Make it pop only in spots
    
    // Combine grid and background
    float gridLineFactor = 1.0 - clamp(line, 0.0, 1.0);
    vec3 gridColor = vec3(0.1, 0.3, 0.6) * 0.5;
    
    // Add some larger, slow-moving blobs of light
    float blob1 = length(uv - vec2(0.3 + sin(pc.time*0.2)*0.2, 0.4 + cos(pc.time*0.3)*0.2));
    float blob2 = length(uv - vec2(0.7 + cos(pc.time*0.1)*0.3, 0.6 + sin(pc.time*0.2)*0.3));
    vec3 lightBlob = vec3(0.0, 0.2, 0.4) * (0.05 / (blob1 * blob1)) + vec3(0.2, 0.0, 0.3) * (0.05 / (blob2 * blob2));
    
    vec3 finalColor = baseColor + (gridColor * gridLineFactor) + vec3(0.2, 0.5, 1.0) * glow + lightBlob;
    
    outColor = vec4(finalColor, 1.0);
}
