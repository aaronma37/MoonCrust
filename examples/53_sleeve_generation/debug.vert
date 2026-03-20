#version 460
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inColor;
layout(push_constant) uniform PC { mat4 projection_view; } pc;
layout(location = 0) out vec3 outColor;
void main() {
    gl_Position = pc.projection_view * vec4(inPos, 1.0);
    outColor = inColor;
}
