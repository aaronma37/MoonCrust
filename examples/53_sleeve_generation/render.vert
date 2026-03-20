#version 460
layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec3 inColor;
layout(location = 3) in vec4 inWeights;
layout(location = 4) in uvec4 inBoneIds;

layout(location = 0) out vec3 outNormal;
layout(location = 1) out vec3 outColor;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out flat uint outBoneId;
layout(location = 4) out vec2 outUV; // theta, ring_idx

layout(push_constant) uniform PC {
    mat4 projection_view;
    mat4 model;
    vec2 mouse_pos;
    float outline_width;
    float wireframe_mode;
} pc;

void main() {
    vec3 pos = inPos;
    
    // Inverted Hull Inflation
    if (pc.outline_width > 0.0) {
        pos += inNormal * pc.outline_width;
    }

    vec4 world_pos = pc.model * vec4(pos, 1.0);
    gl_Position = pc.projection_view * world_pos;
    
    outNormal = normalize(mat3(pc.model) * inNormal);
    outColor = inColor;
    outWorldPos = world_pos.xyz;
    outBoneId = inBoneIds.x;
    outUV = inWeights.zw;
}
