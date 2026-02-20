#version 450

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;

layout(location = 0) out vec3 outNormal;
layout(location = 1) out vec2 outUV;
layout(location = 2) out vec3 outWorldPos;

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
    vec4 cam_pos;
    vec4 light_pos;
    vec4 base_color;
    mat4 light_space;
} pc;

void main() {
    outNormal = inNormal;
    outUV = inUV;
    outWorldPos = inPos;
    gl_Position = pc.light_space * vec4(inPos, 1.0);
}
