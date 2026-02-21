#version 450

layout(location = 0) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    // Soft circular particle
    float dist = length(gl_PointCoord - vec2(0.5));
    if (dist > 0.5) discard;
    
    float alpha = smoothstep(0.5, 0.2, dist);
    outColor = vec4(vColor, alpha);
}
