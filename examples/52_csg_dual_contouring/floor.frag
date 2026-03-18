#version 450

layout(location = 0) in vec3 inWorldPos;
layout(location = 0) out vec4 outFragColor;

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec3 cam_pos;
} pc;

void main() {
    vec2 uv = inWorldPos.xz;
    vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
    float line = min(grid.x, grid.y);
    float mask = 1.0 - min(line, 1.0);
    
    vec3 color = mix(vec3(0.1, 0.1, 0.15), vec3(0.3, 0.3, 0.4), mask);
    
    // Radial fade
    float dist = length(uv);
    float alpha = exp(-dist * dist * 0.05);
    
    outFragColor = vec4(color, alpha);
}
