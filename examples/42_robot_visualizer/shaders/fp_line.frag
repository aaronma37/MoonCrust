#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vPos;
layout(location = 2) in float vLineDist;
layout(location = 3) in float vLineWidth;
layout(location = 4) in vec3 vViewPos;

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

layout(push_constant) uniform PC
{
  mat4 view_proj;
  mat4 view;
  float vw, vh;
  float z_near, z_far;
  uint cluster_x, cluster_y, cluster_z;
  uint buf_idx;
  float point_size;
  float pose_x, pose_y, pose_z, pose_yaw;
} pc;

void main() {
    float alpha = 1.0 - smoothstep(1.0 - 2.0/vLineWidth, 1.0, abs(vLineDist));
    if (alpha <= 0.0) discard;

    // 1. Cluster Indexing
    uint x = uint(gl_FragCoord.x / (pc.vw / float(pc.cluster_x)));
    uint y = uint(gl_FragCoord.y / (pc.vh / float(pc.cluster_y)));
    
    float viewZ = -vViewPos.z;
    uint z = 0;
    if (viewZ > pc.z_near) {
        z = uint(float(pc.cluster_z) * log(viewZ / pc.z_near) / log(pc.z_far / pc.z_near));
    }
    z = min(z, pc.cluster_z - 1);
    uint cluster_index = x + y * pc.cluster_x + z * pc.cluster_x * pc.cluster_y;

    ClusterItem item = cluster_items[cluster_index];

    vec3 N = vec3(0.0, 0.0, 1.0); // Simple normal
    vec3 V = normalize(-vViewPos);
    vec3 albedo = vColor.rgb;
    vec3 total_light = vec3(0.5) * albedo; // Higher ambient for lines/ui

    for (uint i = 0; i < item.count; i++) {
        uint light_idx = light_indices[item.offset + i];
        Light l = lights[light_idx];
        
        vec3 L_vec = l.pos_radius.xyz - vViewPos;
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

    outColor = vec4(total_light, vColor.a * alpha);
}
