#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 3) uniform sampler2D density_tex;
layout(set = 0, binding = 4) uniform sampler2D potential_tex;

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  width;
    uint  height;
    uint  mode;
    uint  p1, p2, p3;
} pc;

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 outColor;

void main() {
    float rho = texture(density_tex, vTexCoord).r;
    float phi = texture(potential_tex, vTexCoord).r;

    // Safety: Catch NaNs immediately
    if (isnan(rho)) rho = 0.0;
    if (isnan(phi)) phi = 0.0;

    vec3 col = vec3(0.005, 0.005, 0.015);
    float vis_rho = smoothstep(0.3, 0.6, rho);
    vec3 mat_color = mix(vec3(0.05, 0.15, 0.3), vec3(0.6, 0.8, 1.0), vis_rho);
    col = mix(col, mat_color, vis_rho);
    
    float phi_r = textureOffset(potential_tex, vTexCoord, ivec2(1,0)).r;
    float phi_u = textureOffset(potential_tex, vTexCoord, ivec2(0,1)).r;
    float grad = length(vec2(phi_r - phi, phi_u - phi)) * 15.0;
    
    // Safety: Clamp gradient to prevent visual blowout
    grad = clamp(grad, 0.0, 5.0);
    
    vec3 stress_col = mix(vec3(0.0, 0.4, 1.0), vec3(1.0, 0.3, 0.0), clamp(grad, 0.0, 1.0));
    col += stress_col * grad * (0.1 + 0.9 * vis_rho) * 1.5;
    
    if (vTexCoord.x < 0.005) col += vec3(0.0, 1.0, 0.5) * 0.8;
    if (distance(vTexCoord, vec2(1.0, 0.5)) < 0.015) col += vec3(1.0, 0.1, 0.1) * (0.8 + 0.2 * sin(pc.time * 8.0));

    outColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
