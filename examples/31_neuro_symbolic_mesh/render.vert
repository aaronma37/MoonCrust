#version 450
layout(location = 0) in vec4 inPosition;

layout(push_constant) uniform ScenePC {
    mat4 view_proj;
    vec4 color;
    float time;
} pc;

layout(location = 0) out vec3 outWorldPos;
layout(location = 1) out vec3 outNormal;

#include "cost.glsl"

void main() {
    outWorldPos = inPosition.xyz;
    
    // Calculate normal directly from moving SDF gradient
    float e = 0.01;
    float d = compute_shape_cost(inPosition.xyz, pc.time);
    vec3 n = vec3(
        compute_shape_cost(inPosition.xyz + vec3(e, 0, 0), pc.time) - d,
        compute_shape_cost(inPosition.xyz + vec3(0, e, 0), pc.time) - d,
        compute_shape_cost(inPosition.xyz + vec3(0, 0, e), pc.time) - d
    );
    outNormal = normalize(n);
    
    gl_Position = pc.view_proj * vec4(inPosition.xyz, 1.0);
}
