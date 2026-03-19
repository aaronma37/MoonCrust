#version 460
layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) in flat uint inBoneId;
layout(location = 4) in vec2 inUV; // x=theta_norm (0-1), y=t_norm (0-1)

layout(push_constant) uniform PC {
    mat4 mvp;
    mat4 model;
    vec2 mouse_pos;
    float outline_width;
    float wireframe_mode;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    if (pc.outline_width > 0.0) {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 normal = normalize(inNormal);
    vec3 lightDir = normalize(vec3(10, 10, 10));
    float diff = max(dot(normal, lightDir), 0.0);
    
    if (diff > 0.4) diff = 0.7;
    else diff = 0.45;
    
    vec3 viewDir = normalize(vec3(0, 5, 15) - inWorldPos);
    float rim = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0) * 0.4;
    
    vec3 finalCol = inColor * diff + vec3(rim);

    if (pc.wireframe_mode > 0.5) {
        // Draw 8 "Sticks" (vertical)
        float sticks = abs(sin(inUV.x * 8.0 * 3.14159265));
        float stick_edge = smoothstep(0.1, 0.0, sticks);
        
        // Draw 16 "Rings" (horizontal)
        float rings = abs(sin(inUV.y * 16.0 * 3.14159265));
        float ring_edge = smoothstep(0.1, 0.0, rings);
        
        float grid = max(stick_edge, ring_edge);
        finalCol = mix(finalCol * 0.2, vec3(0.0, 1.0, 1.0), grid);
    }

    outColor = vec4(finalCol, 1.0);
}
