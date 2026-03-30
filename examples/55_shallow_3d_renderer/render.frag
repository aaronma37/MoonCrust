#version 450
layout(location = 0) in vec3 in_norm;
layout(location = 1) in vec3 in_col;
layout(location = 2) in vec3 in_world_pos;
layout(location = 3) in vec3 in_cam_pos;
layout(location = 0) out vec4 out_col;

void main() {
    vec3 L = normalize(vec3(0.5, 1.0, 0.3));
    float dif = clamp(dot(in_norm, L), 0.2, 1.0);
    
    vec3 sky_color = vec3(0.5, 0.7, 0.9);
    float dist = distance(in_world_pos, in_cam_pos);
    
    // Distance Fog: Fades from 100 to 400 units
    float fog = clamp((dist - 100.0) / 300.0, 0.0, 1.0);
    
    vec3 final_col = mix(in_col * dif, sky_color, fog);
    out_col = vec4(final_col, 1.0);
}
