#version 450

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inColor;

layout(location = 0) out vec3 fragGouraudColor;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    mat4 model;
} pc;

void main() {
    gl_Position = pc.mvp * vec4(inPosition, 1.0);
    
    // Gouraud Shading: Calculate lighting per vertex
    vec3 worldNormal = normalize(mat3(pc.model) * inNormal);
    
    // Use a top-down angled light simulating the sun
    vec3 lightDir = normalize(vec3(0.5, -1.0, 0.5));
    
    // Calculate diffuse
    float diff = max(dot(worldNormal, -lightDir), 0.0);
    
    // Base ambient light so it's not super dark in the shadows
    float ambient = 0.5;
    
    // Light intensity multiplier
    float intensity = ambient + (diff * 0.8);
    
    fragGouraudColor = inColor * intensity;
}
