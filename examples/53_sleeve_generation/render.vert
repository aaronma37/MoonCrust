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
    float outline_width; // 0.0 = body, >0.0 = outline
} pc;

layout(location = 0) out vec3 outNormal;
layout(location = 1) out vec3 outColor;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out flat uint outBoneId;

void main() {
    vec3 pos = inPos.xyz;
    float side = inNormal.w;
    
    // INVERTED HULL: Push vertices out along normal for outline pass
    if (pc.outline_width > 0.0) {
        // Ensure we always inflate 'outward' relative to the surface
        pos += normalize(inNormal.xyz) * pc.outline_width;
    }

    vec4 worldPos = pc.model * vec4(pos, 1.0);
    gl_Position = pc.mvp * vec4(pos, 1.0);
    
    // DEPTH BIAS: Push outline slightly further away to prevent z-fighting
    if (pc.outline_width > 0.0) {
        gl_Position.z += 0.0001;
    }
    
    outNormal = mat3(pc.model) * inNormal.xyz;
    outColor = inColor.rgb;
    outWorldPos = worldPos.xyz;
    outBoneId = inBoneIds.x;
}
