#version 460
layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) in flat uint inBoneId;

layout(push_constant) uniform PC {
    mat4 mvp;
    mat4 model;
    vec2 mouse_pos;
} pc;

layout(std430, set = 0, binding = 4) buffer PickBuffer {
    uint pick_id;
};

layout(location = 0) out vec4 outColor;

void main() {
    // 1. GPU PICKING
    if (abs(gl_FragCoord.x - pc.mouse_pos.x) < 1.0 && abs(gl_FragCoord.y - pc.mouse_pos.y) < 1.0) {
        pick_id = inBoneId;
    }

    // 2. CEL SHADING
    vec3 lightDir = normalize(vec3(0.5, 1.0, 0.5));
    vec3 normal = normalize(inNormal);
    float diff = max(dot(normal, lightDir), 0.0);
    
    if (diff > 0.8) diff = 1.0;
    else if (diff > 0.4) diff = 0.6;
    else diff = 0.3;
    
    vec3 viewDir = normalize(vec3(0, 5, 15) - inWorldPos);
    float rim = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0) * 0.4;
    
    outColor = vec4(inColor * diff + vec3(rim), 1.0);
}
