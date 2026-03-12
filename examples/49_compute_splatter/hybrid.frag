#version 450
layout(location = 0) in vec2 in_uv;
layout(location = 1) in vec4 in_color;
layout(location = 0) out vec4 out_frag;

void main() {
    float power = -0.5 * dot(in_uv, in_uv);
    if (power < -8.0) discard;
    float alpha = in_color.a * exp(power);
    out_frag = vec4(in_color.rgb * alpha, alpha);
}
