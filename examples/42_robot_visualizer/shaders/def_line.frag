#version 450

layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vPos;
layout(location = 2) in float vLineDist; // -expanded/orig to expanded/orig
layout(location = 3) in float vLineWidth; // thickness in pixels

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPosition;

void main() {
    // Distance from center in pixels
    float dist_pixels = abs(vLineDist) * (vLineWidth * 0.5);
    
    // Smooth AA over 1 pixel
    float half_width = vLineWidth * 0.5;
    float alpha = smoothstep(half_width + 1.0, half_width, dist_pixels);
    
    if (alpha < 0.01) discard;

    // Emissive boost for thin lines
    float emissive = 1.0 + (1.0 / max(1.0, vLineWidth));
    
    outColor = vec4(vColor.rgb * emissive, vColor.a * alpha);
    outNormal = vec4(0, 0, 1, 1.0);
    outPosition = vec4(vPos, 1.0);
}
