#version 450

layout(location = 0) in float vSample;
layout(location = 0) out vec4 outColor;

void main() {
    float intensity = abs(vSample);
    outColor = vec4(0.2, 0.8 * intensity, 1.0, 1.0);
}
