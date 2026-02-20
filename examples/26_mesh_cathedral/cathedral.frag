#version 450

layout(location = 0) in vec3 vNormal;
layout(location = 1) in vec3 vColor;
layout(location = 2) in vec3 vWorldPos;
layout(location = 0) out vec4 outColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    float time;
} pc;

void main() {
    vec3 n = normalize(vNormal);
    vec3 p = vWorldPos;
    
    // 1. Moving Light Sources (The Torches)
    vec3 lp1 = vec3(sin(pc.time * 0.5) * 8.0, 4.0, cos(pc.time * 0.3) * 10.0);
    vec3 ld1 = normalize(lp1 - p);
    float dif1 = max(dot(n, ld1), 0.0) * (5.0 / length(lp1 - p));
    
    // 2. High-Quality Mirror Floor
    float floor_mask = smoothstep(0.1, 0.0, p.y);
    vec3 reflection = vec3(0);
    if (p.y < 0.1) {
        // Pseudo GI: Sample light from above
        reflection = vec3(0.1, 0.15, 0.2) * clamp(n.y, 0.0, 1.0);
    }

    // 3. Ambient Occlusion (Corners)
    float ao = 1.0 - smoothstep(7.0, 10.0, abs(p.x)) * 0.5;
    
    vec3 col = vColor * (dif1 * vec3(1.0, 0.8, 0.5) + reflection + 0.05);
    col *= ao;

    // 4. Atmospheric Fog (Depth)
    float fog = exp(-abs(p.z) * 0.05);
    col = mix(vec3(0.02, 0.02, 0.05), col, fog);

    outColor = vec4(col, 1.0);
}
