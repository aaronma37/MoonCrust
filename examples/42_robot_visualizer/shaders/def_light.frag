#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PC {
    uint color_idx;
    uint normal_idx;
    uint pos_idx;
    float dummy;
    vec3 light_dir;
} pc;

void main() {
    vec4 albedo = texture(all_textures[nonuniformEXT(pc.color_idx)], vUV);
    vec4 normal = texture(all_textures[nonuniformEXT(pc.normal_idx)], vUV);
    vec4 position = texture(all_textures[nonuniformEXT(pc.pos_idx)], vUV);
    
    // Background clear condition
    if (albedo.a == 0.0) {
        outColor = vec4(0.05, 0.05, 0.07, 1.0); // Background color
        return;
    }
    
    vec3 N = normalize(normal.xyz);
    vec3 L = normalize(pc.light_dir);
    float diff = max(dot(N, L), 0.0);
    
    vec3 ambient = 0.2 * albedo.rgb;
    vec3 diffuse = diff * albedo.rgb;
    
    // Fallback: If normal is bogus (e.g., from lines), make it fully lit
    if (length(normal.xyz) < 0.1) {
        diffuse = albedo.rgb;
    }
    
    outColor = vec4(ambient + diffuse, albedo.a);
}