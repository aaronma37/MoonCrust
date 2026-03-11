#version 450

layout(location = 0) in vec3 fragGouraudColor;

layout(location = 0) out vec4 outColor;

void main() {
    // Just output the pre-calculated per-vertex color (Gouraud style)
    outColor = vec4(fragGouraudColor, 1.0);
}
