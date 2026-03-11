#version 450

layout(location = 0) in vec3 fragNormal;
layout(location = 1) in vec3 fragColor;
layout(location = 2) in vec3 fragPos;

layout(location = 0) out vec4 outColor;

void main() {
    // Re-normalize interpolated normals for per-pixel accuracy
    vec3 N = normalize(fragNormal);
    
    // Light 1: Main Sun (Top-Right-Front)
    vec3 L1 = normalize(vec3(0.5, 1.0, 0.5));
    float diff1 = max(dot(N, L1), 0.0);
    
    // Light 2: Fill Light (Bottom-Left-Back)
    vec3 L2 = normalize(vec3(-0.5, -0.5, -0.5));
    float diff2 = max(dot(N, L2), 0.0) * 0.3;
    
    // Light 3: Rim Light (Back-Top)
    vec3 L3 = normalize(vec3(0.0, 0.5, -1.0));
    float diff3 = max(dot(N, L3), 0.0) * 0.5;

    // Ambient
    float ambient = 0.35;
    
    // Total Lighting
    vec3 lighting = (ambient + diff1 * 0.8 + diff2 + diff3) * vec3(1.0, 0.98, 0.9);
    
    // Base color
    vec3 result = fragColor * lighting;

    // Magical Glow (Gem/Trim)
    if (fragColor.g > 0.8 && fragColor.b > 0.8) {
        result += fragColor * 0.6;
    }

    outColor = vec4(result, 1.0);
}
