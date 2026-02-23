#version 450

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out vec3 vNormal;

layout(push_constant) uniform PC {
    mat4 view_proj;
} pc;

void main() {
    vec4 worldPos = vec4(inPos, 1.0);
    gl_Position = pc.view_proj * worldPos;
    vColor = inColor;
    vPos = worldPos.xyz;
    vNormal = vec3(0.0, 0.0, 1.0); // Default up normal for lines
}