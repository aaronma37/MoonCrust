#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 vNormal;
layout(location = 1) in vec3 vColor;
layout(location = 2) in vec3 vWorldPos;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) buffer VoxelGrid { uint color_mask[]; } grids[];

float hash(vec3 p) {
    p  = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

// Procedural Stone Noise
float stone_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i+vec3(0,0,0)), hash(i+vec3(1,0,0)), f.x),
                   mix(hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)), f.x),
                   mix(hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)), f.x), f.y), f.z);
}

uint get_voxel_raw(vec3 p) {
    vec3 vox_p = (p + vec3(2000.0, 200.0, 1200.0)) / vec3(4000.0, 1600.0, 2400.0);
    if (any(lessThan(vox_p, vec3(0))) || any(greaterThan(vox_p, vec3(1)))) return 0;
    ivec3 v = ivec3(vox_p * 32.0);
    uint g_idx = v.z * 1024 + v.y * 32 + v.x;
    return grids[1].color_mask[g_idx];
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 p = vWorldPos;
    
    // 1. TRIPLANAR PROCEDURAL TEXTURE
    // This removes the "solid plastic" look by projecting noise onto the stone
    float stone = stone_noise(p * 0.05) * 0.5 + stone_noise(p * 0.5) * 0.2;
    vec3 base_color = vColor * (0.8 + 0.4 * stone);
    
    // 2. Direct Lighting
    vec3 ld = normalize(vec3(0.3, 1.0, 0.4));
    float dif = max(dot(n, ld), 0.0);
    
    // 3. Voxel Global Illumination & Soft AO
    vec3 indirect = vec3(0.0);
    float occ = 0.0;
    for (int i = 1; i <= 4; i++) {
        float dist = float(i) * 150.0;
        uint vox = get_voxel_raw(p + n * dist);
        if ((vox & 0xFF000000) != 0) {
            occ += 1.0 / float(i);
            // Sample color from the voxel for bounce light
            vec3 vcol = vec3(float((vox >> 16) & 0xFF), float((vox >> 8) & 0xFF), float(vox & 0xFF)) / 255.0;
            indirect += vcol * (0.2 / float(i));
        }
    }
    float ao = exp(-occ * 0.5);
    
    // 4. Final Composite
    vec3 ambient = vec3(0.04, 0.05, 0.08) * ao;
    vec3 col = base_color * (dif * ao + ambient + indirect * ao);
    
    // Subtle Fog for Depth
    float fog = exp(-length(p - vec3(0, 200, 0)) * 0.0002);
    col = mix(vec3(0.02, 0.02, 0.05), col, fog);

    // Tone Map + Gamma
    col = col * 1.3;
    col = col / (col + vec3(1.0));
    col = pow(col, vec3(1.0/2.2));
    
    outColor = vec4(col, 1.0);
}
