#version 460
layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inWorldPos;

layout(location = 0) out vec4 outColor;

void main() {
    vec3 lightDir = normalize(vec3(0.5, 1.0, 0.5));
    vec3 normal = normalize(inNormal);
    
    float diff = max(dot(normal, lightDir), 0.0);
    
    // Cel Shading (3 steps)
    if (diff > 0.8) diff = 1.0;
    else if (diff > 0.4) diff = 0.6;
    else diff = 0.3;
    
    // Rim Light
    vec3 viewDir = normalize(vec3(0, 5, 15) - inWorldPos);
    float rim = 1.0 - max(dot(viewDir, normal), 0.0);
    rim = pow(rim, 3.0) * 0.4;
    
    vec3 col = inColor * diff + vec3(rim);
    outColor = vec4(col, 1.0);
}
