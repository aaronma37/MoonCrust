#version 460
layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) in flat uint inBoneId;

layout(push_constant) uniform PC {
    mat4 mvp;
    mat4 model;
    vec2 mouse_pos;
    float outline_width;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    // INVERTED HULL: Render solid black for the outline pass
    if (pc.outline_width > 0.0) {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 normal = normalize(inNormal);
    vec3 lightDir = normalize(vec3(10, 10, 10));
    float diff = max(dot(normal, lightDir), 0.0);
    
    // ANIME CEL SHADING
    if (diff > 0.4) diff = 0.7;
    else diff = 0.45;
    
    vec3 viewDir = normalize(vec3(0, 5, 15) - inWorldPos);
    float rim = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0) * 0.4;
    
    outColor = vec4(inColor * diff + vec3(rim), 1.0);
}
