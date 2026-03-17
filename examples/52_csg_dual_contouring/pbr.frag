#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 inNormal;
layout(location = 1) flat in vec4 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) flat in uint inID;

layout(location = 0) out vec4 outFragColor;

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec3 cam_pos;
    uint bone_count;
    uint bones_idx;
} pc;

void main() {
    vec3 N = normalize(inNormal);
    vec3 L = normalize(vec3(1.0, 1.0, 1.5)); // Main Directional Light
    vec3 V = normalize(pc.cam_pos - inWorldPos);
    vec3 H = normalize(L + V);

    // --- STEP-TONE DIFFUSE ---
    float ndl = dot(N, L);
    float diff = 0.0;
    
    // 3-Tone Quantization (High, Mid, Shadow)
    if (ndl > 0.4) {
        diff = 1.0;
    } else if (ndl > -0.1) {
        diff = 0.6;
    } else {
        diff = 0.3;
    }

    // --- STYLIZED SPECULAR ---
    float ndh = max(dot(N, H), 0.0);
    float spec = smoothstep(0.9, 0.95, pow(ndh, 64.0)); // Sharp "Glint"

    // --- ANIME RIM LIGHTING ---
    float rim_dot = 1.0 - max(dot(N, V), 0.0);
    float rim = smoothstep(0.7, 0.75, rim_dot);
    rim *= max(0.0, dot(N, L) + 0.5); // Mask rim by light to prevent "Glow-in-the-dark" look

    vec3 baseColor = inColor.rgb;
    
    // Material Tweaks based on ID
    if (inID >= 10) { // Metallic parts (Sword/Helmet)
        baseColor *= 1.1;
        spec *= 1.5;
    }

    // Final Composite
    vec3 color = baseColor * diff;
    color += vec3(1.0) * spec * 0.8; // White Specular Glint
    color += baseColor * rim * 0.4;  // Soft Color-matched Rim
    
    // Subtle Ambient
    color += baseColor * 0.15;

    // Linear to Gamma (2.2)
    outFragColor = vec4(pow(color, vec3(1.0/2.2)), 1.0);
}
