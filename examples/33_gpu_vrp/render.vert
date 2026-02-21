#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct City {
    vec2 pos;
    uint vehicle_id;
    uint next_index;
};

layout(set = 0, binding = 0) buffer CityBuffer {
    City cities[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  city_buf_id;
    uint  mode; 
    uint  vehicle_count;
    uint  padding;
} pc;

layout(location = 0) out vec3 vColor;

vec3 get_vehicle_color(uint id) {
    float phi = float(id) * 3.14159265; 
    vec3 c = 0.6 + 0.4 * cos(vec3(0, 2, 4) + phi);
    float salt = (float(id % 7) / 7.0) * 0.2;
    return clamp(c + salt, 0.0, 1.0);
}

void main() {
    uint bid = pc.city_buf_id;
    
    if (pc.mode == 1) {
        uint is_end = gl_VertexIndex % 2;
        uint base_idx = gl_VertexIndex / 2;
        
        City current = all_buffers[bid].cities[base_idx];
        uint next_idx = current.next_index;
        City next = all_buffers[bid].cities[next_idx];
        
        vec2 p = (is_end == 1) ? next.pos : current.pos;
        gl_Position = vec4(p, 0.0, 1.0);
        vColor = get_vehicle_color(current.vehicle_id);
        
        if (current.vehicle_id != next.vehicle_id) vColor *= 0.0;
        
    } else {
        uint city_idx = gl_VertexIndex;
        City city = all_buffers[bid].cities[city_idx];
        gl_Position = vec4(city.pos, 0.0, 1.0);
        gl_PointSize = 6.0;
        vColor = get_vehicle_color(city.vehicle_id);
    }
}
