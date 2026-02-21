#version 450

layout(location = 0) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    // Boost intensity for additive glow
    outColor = vec4(vColor * 1.5, 1.0);
}
