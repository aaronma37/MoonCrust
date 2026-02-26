#version 450

layout(location = 0) in vec4 vColor;
layout(location = 0) out vec4 oColor;

void main() {
    // Faint grey background (0.1) plus the line color
    oColor = vec4(0.1, 0.1, 0.1, 1.0) + vColor;
}
