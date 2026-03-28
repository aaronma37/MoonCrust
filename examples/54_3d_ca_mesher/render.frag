#version 450
layout(location = 0) in vec3 in_norm;
layout(location = 1) in vec3 in_col;
layout(location = 0) out vec4 out_col;

void main() {
    vec3 L = normalize(vec3(0.5, 1.0, 0.3));
    float dif = clamp(dot(in_norm, L), 0.2, 1.0);
    out_col = vec4(in_col * dif, 1.0);
}
