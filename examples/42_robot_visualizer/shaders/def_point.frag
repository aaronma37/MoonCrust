#version 450

layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vPos;
layout(location = 2) in vec3 vNormal;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outPosition;

void main() {
    outColor = vColor;
    outNormal = vec4(vNormal, 1.0);
    outPosition = vec4(vPos, 1.0);
}