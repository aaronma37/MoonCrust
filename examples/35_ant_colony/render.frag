#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  ant_buf_id;
    uint  city_buf_id;
    uint  num_ants;
    uint  num_cities;
    uint  seed;
    uint  mode;
} pc;

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    if (pc.mode == 0) {
        // Sample Pheromone Map
        vec4 pheromones = texture(all_textures[0], vTexCoord);
        // Map red channel to a "Cyber Blue/Cyan" look
        vec3 col = mix(vec3(0.0, 0.0, 0.05), vec3(0.0, 0.6, 1.0), pheromones.r);
        col += mix(vec3(0.0), vec3(0.8, 0.2, 1.0), pheromones.g); // Secondary path glow
        outColor = vec4(col, 1.0);
    } else {
        // Simple circle for ants
        float dist = length(gl_PointCoord - vec2(0.5));
        if (dist > 0.5) discard;
        outColor = vec4(vColor * 2.0, 1.0); // Glowy ants
    }
}
