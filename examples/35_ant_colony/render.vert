#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Ant {
    vec2 pos;
    float angle;
    uint  phase;
    uint  home_city;
    uint  target_city;
    uint  padding1;
    uint  padding2;
};

layout(set = 0, binding = 0) buffer AntBuffer { Ant ants[]; } all_ants[];
layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  ant_buf_id;
    uint  city_buf_id;
    uint  num_ants;
    uint  num_cities;
    uint  seed;
    uint  mode; // 0 = background (pheromones), 1 = ants
} pc;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec3 vColor;

void main() {
    if (pc.mode == 0) {
        // Fullscreen Quad for Pheromone Map
        vTexCoord = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
        gl_Position = vec4(vTexCoord * 2.0 - 1.0, 0.0, 1.0);
        vTexCoord.y = 1.0 - vTexCoord.y; // Flip Y for Vulkan
    } else {
        // Ant Particles
        Ant ant = all_ants[pc.ant_buf_id].ants[gl_VertexIndex];
        gl_Position = vec4(ant.pos, 0.0, 1.0);
        gl_PointSize = 2.0;
        vColor = (ant.phase == 0) ? vec3(0.2, 0.8, 1.0) : vec3(1.0, 0.5, 0.2);
    }
}
