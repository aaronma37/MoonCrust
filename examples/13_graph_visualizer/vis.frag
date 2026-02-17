#version 450

layout(location = 0) in vec3 vColor;
layout(location = 1) in float vIsNode;
layout(location = 0) out vec4 outColor;

void main() {
    if (vIsNode > 0.5) {
        vec2 circ = gl_PointCoord * 2.0 - 1.0;
        float dist = dot(circ, circ);
        if (dist > 1.0) discard;
        float z = sqrt(1.0 - dist);
        outColor = vec4(vColor * (0.5 + 0.5 * z), 1.0);
    } else {
        outColor = vec4(vColor, 0.8);
    }
}
