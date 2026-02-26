#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec3 inWorldPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec3 inViewPos;

layout(location = 0) out vec4 outColor;

struct Light {
    vec4 pos_radius; // view space
    vec4 color;
};

struct ClusterItem {
    uint offset;
    uint count;
};

layout(std430, set = 1, binding = 0) buffer LightBuffer { Light lights[]; };
layout(std430, set = 1, binding = 1) buffer ClusterItemBuffer { ClusterItem cluster_items[]; };
layout(std430, set = 1, binding = 2) buffer LightIndexBuffer { uint light_indices[]; };
layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
    mat4 view;
    vec4 cam_pos;
    vec2 screen_size;
    float z_near;
    float z_far;
    uint cluster_x;
    uint cluster_y;
    uint cluster_z;
    uint albedo_idx;
} pc;

void main() {
    vec3 albedo = vec3(1.0);
    if (pc.albedo_idx != 0xFFFFFFFF) {
        albedo = texture(all_textures[nonuniformEXT(pc.albedo_idx)], inUV).rgb;
    }

    // 1. Cluster Indexing
    uint x = uint(gl_FragCoord.x / (pc.screen_size.x / float(pc.cluster_x)));
    uint y = uint(gl_FragCoord.y / (pc.screen_size.y / float(pc.cluster_y)));
    
    float viewZ = -inViewPos.z;
    // Guard against points in front of near plane or precision issues
    uint z = 0;
    if (viewZ > pc.z_near) {
        z = uint(float(pc.cluster_z) * log(viewZ / pc.z_near) / log(pc.z_far / pc.z_near));
    }
    
    z = min(z, pc.cluster_z - 1);
    uint cluster_index = x + y * pc.cluster_x + z * pc.cluster_x * pc.cluster_y;

    ClusterItem item = cluster_items[cluster_index];

    vec3 N = normalize(inNormal);
    vec3 V = normalize(-inViewPos);
    vec3 total_light = vec3(0.02) * albedo; // Ambient

    for (uint i = 0; i < item.count; i++) {
        uint light_idx = light_indices[item.offset + i];
        Light l = lights[light_idx];
        
        vec3 L_vec = l.pos_radius.xyz - inViewPos;
        float dist = length(L_vec);
        float radius = l.pos_radius.w;
        
        if (dist < radius) {
            vec3 L = normalize(L_vec);
            float nDotL = max(dot(N, L), 0.0);
            
            float attenuation = clamp(1.0 - (dist * dist) / (radius * radius), 0.0, 1.0);
            attenuation *= attenuation;
            
            total_light += albedo * l.color.rgb * l.color.w * nDotL * attenuation;
        }
    }
    
    // DEBUG: Show cluster density (tint by light count)
    // total_light += vec3(float(item.count) / 10.0, 0.0, 0.0); 

    outColor = vec4(total_light, 1.0);
}
