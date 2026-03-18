#version 450

layout(location = 0) in vec4 inPos;

layout(location = 0) out vec3 outWorldPos;

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec3 cam_pos;
} pc;

void main() {
    // scale floor
    vec3 pos = inPos.xyz * 20.0;
    outWorldPos = pos;
    gl_Position = pc.projection * pc.view * vec4(pos, 1.0);
}
