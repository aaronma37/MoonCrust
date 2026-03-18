#version 460
layout(location = 0) in vec4 inPos;
layout(location = 1) in vec4 inNormal;
layout(location = 2) in vec4 inColor;
layout(location = 3) in vec4 inWeights;
layout(location = 4) in uvec4 inBoneIds;

layout(push_constant) uniform PC {
    mat4 mvp;
    mat4 model;
    vec2 mouse_pos;
} pc;

layout(location = 0) out vec3 outNormal;
layout(location = 1) out vec3 outColor;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out flat uint outBoneId;

void main() {
    vec4 worldPos = pc.model * vec4(inPos.xyz, 1.0);
    gl_Position = pc.mvp * vec4(inPos.xyz, 1.0);
    
    outNormal = mat3(pc.model) * inNormal.xyz;
    outColor = inColor.rgb;
    outWorldPos = worldPos.xyz;
    outBoneId = inBoneIds.x; // Pass bone ID for picking
}
