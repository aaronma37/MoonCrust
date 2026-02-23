#version 450

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec4 vColor;

layout(push_constant) uniform PC {
    mat4 view_proj;
} pc;

void main() {
    gl_Position = pc.view_proj * vec4(inPos, 1.0);
    vColor = inColor;
}
