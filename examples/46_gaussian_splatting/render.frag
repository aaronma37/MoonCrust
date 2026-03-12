#version 450
layout(location = 0) in vec2 in_uv;
layout(location = 1) in vec4 in_color;
layout(location = 2) in vec3 in_cov;

layout(location = 0) out vec4 out_frag_color;

void main() {
    // 2D covariance matrix is:
    // [ x2 xy ]
    // [ xy y2 ]
    // Determinant: det = x2 * y2 - xy * xy
    float det = in_cov.x * in_cov.z - in_cov.y * in_cov.y;
    if (det <= 0.0) discard;
    
    float inv_det = 1.0 / det;
    // Inverse matrix: (1/det) * [ y2 -xy ]
    //                            [ -xy x2 ]
    vec3 inv_cov = vec3(in_cov.z, -in_cov.y, in_cov.x) * inv_det;

    // Gaussian power = -0.5 * (x,y) * InvCov * (x,y)^T
    float power = -0.5 * (inv_cov.x * in_uv.x * in_uv.x + 
                          2.0 * inv_cov.y * in_uv.x * in_uv.y + 
                          inv_cov.z * in_uv.y * in_uv.y);
    
    if (power > 0.0) discard;
    float alpha = in_color.a * exp(power);
    if (alpha < 0.0039) discard; // 1/255

    // Standard alpha blending: src * alpha + dst * (1-alpha)
    // Fragment shader should output non-premultiplied color for alpha_blend = true
    out_frag_color = vec4(in_color.rgb, alpha);
}
