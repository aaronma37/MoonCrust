#version 450

layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vPos;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec3 vLitColor;

layout(location = 0) out vec4 outColor;

void main() {
    // SDF Circle
    float d = length(vUV);
    if (d > 1.0) discard;
    
    // Anti-aliased edge
    float alpha = 1.0 - smoothstep(0.9, 1.0, d);
    
    outColor = vec4(vLitColor, alpha);
}
