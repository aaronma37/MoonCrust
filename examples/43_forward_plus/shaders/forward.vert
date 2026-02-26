#version 450

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

layout(location = 0) out vec3 outWorldPos;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec2 outUV;
layout(location = 3) out vec3 outViewPos;

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
    mat4 view;
    vec4 cam_pos;
} pc;

void main() {
    outWorldPos = inPos;
    outNormal = (pc.view * vec4(inNormal, 0.0)).xyz;
    outUV = inUV;
    outViewPos = (pc.view * vec4(inPos, 1.0)).xyz;
    gl_Position = pc.view_proj * vec4(inPos, 1.0);
}
