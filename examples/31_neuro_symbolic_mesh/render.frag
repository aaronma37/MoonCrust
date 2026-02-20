#version 450
layout(location = 0) in vec3 inWorldPos;
layout(location = 1) in vec3 inNormal;

layout(push_constant) uniform ScenePC {
    mat4 view_proj;
    vec4 color;
    float time;
} pc;

layout(location = 0) out vec4 outColor;

#include "cost.glsl"

void main() {
    // 1. Calculate Normals from moving SDF
    float e = 0.01;
    float d = compute_shape_cost(inWorldPos, pc.time);
    vec3 normal = normalize(vec3(
        compute_shape_cost(inWorldPos + vec3(e, 0, 0), pc.time) - d,
        compute_shape_cost(inWorldPos + vec3(0, e, 0), pc.time) - d,
        compute_shape_cost(inWorldPos + vec3(0, 0, e), pc.time) - d
    ));
    
    // 2. Light Directions
    vec3 key_dir = normalize(vec3(5.0, 10.0, 5.0));
    vec3 fill_dir = normalize(vec3(-5.0, 2.0, 2.0));
    vec3 v_dir = normalize(vec3(0.0, 5.0, 10.0) - inWorldPos);

    // 3. Three-Point Lighting
    float key = max(dot(normal, key_dir), 0.0) * 0.8;
    float fill = max(dot(normal, fill_dir), 0.0) * 0.3;
    float rim = pow(1.0 - max(dot(normal, v_dir), 0.0), 4.0) * 0.6;
    float bounce = max(dot(normal, vec3(0, -1, 0)), 0.0) * 0.1;
    
    // 4. Color
    vec3 base_color = pc.color.rgb;
    if (inWorldPos.y < 0.01) base_color = vec3(0.1, 0.1, 0.12);
    
    vec3 light_color = (vec3(1.0, 0.9, 0.8) * key) + (vec3(0.7, 0.8, 1.0) * fill) + (vec3(1.0) * rim);
    vec3 final_rgb = base_color * (light_color + 0.05 + bounce);
    
    final_rgb = pow(final_rgb, vec3(1.0 / 2.2));
    outColor = vec4(final_rgb, 1.0);
}
