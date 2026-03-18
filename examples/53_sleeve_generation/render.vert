#version 460
layout(location = 0) in vec4 inPos;
layout(location = 1) in vec4 inNormal;
layout(location = 2) in vec4 inColor;
layout(location = 3) in vec4 inWeights;
layout(location = 4) in uvec4 inBoneIds;

layout(push_constant) uniform PC {
    mat4 mvp;
    mat4 model;
} pc;

layout(std430, set = 0, binding = 3) readonly buffer BoneMatrices {
    mat4 bones[];
};

layout(location = 0) out vec3 outNormal;
layout(location = 1) out vec3 outColor;
layout(location = 2) out vec3 outWorldPos;

void main() {
    mat4 skinMat = 
        inWeights.x * bones[inBoneIds.x] +
        inWeights.y * bones[inBoneIds.y] +
        inWeights.z * bones[inBoneIds.z] +
        inWeights.w * bones[inBoneIds.w];

    vec4 worldPos = pc.model * skinMat * vec4(inPos.xyz, 1.0);
    gl_Position = pc.mvp * skinMat * vec4(inPos.xyz, 1.0);
    
    outNormal = mat3(pc.model * skinMat) * inNormal.xyz;
    outColor = inColor.rgb;
    outWorldPos = worldPos.xyz;
}
