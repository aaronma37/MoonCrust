#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 4) uniform sampler2D x_tex;
layout(set = 0, binding = 5) uniform sampler2D u_tex; 

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  width;
    uint  height;
    float lambda;
    float rho;
    uint  mode;
    uint  pad;
} pc;

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 outColor;

void main() {
    vec4 x = texture(x_tex, vTexCoord);
    vec4 u = texture(u_tex, vTexCoord);

    // If it's still white, we manually darken it
    vec3 col = clamp(x.rgb, 0.0, 1.0);
    
    // Convert pressure to a VERY sharp glowing edge
    float pressure = length(u.rgb);
    float edge = smoothstep(0.1, 0.4, pressure);
    vec3 edge_col = mix(vec3(0.0, 1.0, 0.5), vec3(1.0, 0.0, 0.5), edge);
    
    // Composite: Dark background, solid shapes, neon edges
    vec3 final_col = mix(col * 0.5, edge_col, edge * 0.8);
    
    // Add subtle grid
    float grid = (fract(vTexCoord.x * 32.0) < 0.02 || fract(vTexCoord.y * 32.0) < 0.02) ? 0.1 : 0.0;
    final_col += grid * vec3(0.0, 0.5, 1.0);

    outColor = vec4(final_col, 1.0);
}
