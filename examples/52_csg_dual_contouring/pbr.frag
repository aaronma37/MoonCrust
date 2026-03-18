#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 inNormal;
layout(location = 1) flat in vec4 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) flat in uint inID;
layout(location = 4) flat in uvec4 inBoneIds;
layout(location = 5) in vec4 inBoneWeights;

layout(location = 0) out vec4 outFragColor;

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec4 cam_pos;
    uint bone_count;
    uint bones_idx;
    float outline_thickness;
    uint outline_mode;
    uint debug_mode;
    uint debug_bone;
} pc;

vec3 hash_color(uint id) {
    uint x = id * 123456789;
    x = (x ^ (x >> 16)) * 0x7feb352d;
    x = (x ^ (x >> 16)) * 0x846ca68b;
    x = (x ^ (x >> 16));
    return vec3(float(x & 0xFF) / 255.0, float((x >> 8) & 0xFF) / 255.0, float((x >> 16) & 0xFF) / 255.0);
}

void main() {
    if (pc.debug_mode == 1) { // SINGLE BONE HEATMAP
        float weight = 0.0;
        if (inBoneIds.x == pc.debug_bone) weight += inBoneWeights.x;
        if (inBoneIds.y == pc.debug_bone) weight += inBoneWeights.y;
        if (inBoneIds.z == pc.debug_bone) weight += inBoneWeights.z;
        if (inBoneIds.w == pc.debug_bone) weight += inBoneWeights.w;
        
        // Heatmap: Blue (0) -> Green (0.5) -> Red (1.0)
        vec3 color = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), smoothstep(0.0, 0.5, weight));
        color = mix(color, vec3(1.0, 0.0, 0.0), smoothstep(0.5, 1.0, weight));
        
        outFragColor = vec4(color, 1.0);
        return;
    }
    
    if (pc.debug_mode == 2) { // MULTI-BONE WEIGHT VIZ
        vec3 color = vec3(0.0);
        color += hash_color(inBoneIds.x) * inBoneWeights.x;
        color += hash_color(inBoneIds.y) * inBoneWeights.y;
        color += hash_color(inBoneIds.z) * inBoneWeights.z;
        color += hash_color(inBoneIds.w) * inBoneWeights.w;
        outFragColor = vec4(color, 1.0);
        return;
    }

    vec3 N = normalize(inNormal);
    vec3 L = normalize(vec3(1.0, 1.0, 1.5)); // Main Directional Light
    vec3 V = normalize(pc.cam_pos.xyz - inWorldPos);
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
    float spec = smoothstep(0.96, 0.98, pow(ndh, 128.0)); // Even sharper, smaller "Hotspot"

    // --- ANIME RIM LIGHTING ---
    float rim_dot = 1.0 - max(dot(N, V), 0.0);
    float rim = smoothstep(0.75, 0.8, rim_dot);
    rim *= max(0.0, dot(N, L) + 0.2); // Tighten mask

    vec3 baseColor = inColor.rgb;
    
    // Material Tweaks based on ID
    float final_spec = 0.0;
    float final_rim = rim * 0.2; // Soft default rim

    if (inID >= 10) { // Metallic parts (Sword/Helmet)
        baseColor *= 1.1;
        final_spec = spec * 1.2;
        final_rim = rim * 0.5; // Brighter rim for metal
    } else if (inID == 4) { // EYES
        diff = 1.0; // Unlit / Constant brightness
        baseColor *= 1.2;
        // Static Eye Highlight
        vec3 eye_dir = normalize(vec3(0.1, 0.2, 0.8));
        float eye_spec = smoothstep(0.99, 1.0, dot(N, eye_dir));
        final_spec = eye_spec * 1.5;
        final_rim = 0.0;
    } else if (inID == 5) { // HAIR
        // Anisotropic-style sheen (Angel Ring)
        // For a horizontal halo, the tangent should be vertical (strand direction)
        vec3 T = vec3(0, 1, 0); 
        float dotTH = dot(T, H);
        float sinTH = sqrt(1.0 - dotTH * dotTH);
        float sheen = pow(sinTH, 128.0) * 0.8;
        
        final_spec = sheen * smoothstep(0.1, 0.2, ndl); // Only in light
        final_rim = rim * 0.3;
        baseColor *= 1.1; // Saturated hair
    } else {
        // Skin/Fabric is matte
        final_spec = 0.0; 
    }

    // Final Composite
    vec3 color = baseColor * diff;
    color += vec3(1.0) * final_spec; // White Specular Glint
    color += baseColor * final_rim;  // Color-matched Rim
    
    // Subtle Ambient
    color += baseColor * 0.15;

    // Linear to Gamma (2.2)
    outFragColor = vec4(pow(color, vec3(1.0/2.2)), 1.0);
}
