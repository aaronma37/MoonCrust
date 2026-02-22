#version 450
layout(location = 0) in vec4 vColor;
layout(location = 0) out vec4 oColor;

void main() {
    oColor = vColor;
    
    // Circular points
    vec2 circ = gl_PointCoord * 2.0 - 1.0;
    if (dot(circ, circ) > 1.0) discard;
}
