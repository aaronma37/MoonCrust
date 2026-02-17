#version 450

layout(location = 0) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    vec2 circ = gl_PointCoord * 2.0 - 1.0;
    float r2 = dot(circ, circ);
    if (r2 > 1.0) discard;

    float z = sqrt(1.0 - r2);
    vec3 normal = vec3(circ, z);
    vec3 light_dir = normalize(vec3(0.4, 0.7, 1.0));
    float diff = max(dot(normal, light_dir), 0.15);
    outColor = vec4(vColor * diff, 1.0);
}
