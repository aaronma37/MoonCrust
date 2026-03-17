#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec4 inPos;
layout(location = 1) in vec4 inNormal;
layout(location = 2) in vec4 inColor;
layout(location = 3) in uvec4 inBoneIds;
layout(location = 4) in vec4 inBoneWeights;

layout(location = 0) out vec3 outNormal;
layout(location = 1) flat out vec4 outColor;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) flat out uint outID;

layout(set = 0, binding = 0, std430) buffer AllBuffers { uint data[]; } all_bufs[];

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec3 cam_pos;
    uint bone_count;
    uint bones_idx;
} pc;

mat4 get_bone_mat(uint bone_idx, uint offset) {
    uint base = (bone_idx * 68) + offset;
    mat4 m;
    for(int i=0; i<4; i++) {
        for(int j=0; j<4; j++) {
            m[i][j] = uintBitsToFloat(all_bufs[nonuniformEXT(pc.bones_idx)].data[base + i*4 + j]);
        }
    }
    return m;
}

void main() {
    mat4 world0 = get_bone_mat(inBoneIds.x, 0);
    mat4 invB0  = get_bone_mat(inBoneIds.x, 48);
    mat4 world1 = get_bone_mat(inBoneIds.y, 0);
    mat4 invB1  = get_bone_mat(inBoneIds.y, 48);
    mat4 world2 = get_bone_mat(inBoneIds.z, 0);
    mat4 invB2  = get_bone_mat(inBoneIds.z, 48);
    mat4 world3 = get_bone_mat(inBoneIds.w, 0);
    mat4 invB3  = get_bone_mat(inBoneIds.w, 48);

    mat4 skinMat = 
        inBoneWeights.x * (world0 * invB0) +
        inBoneWeights.y * (world1 * invB1) +
        inBoneWeights.z * (world2 * invB2) +
        inBoneWeights.w * (world3 * invB3);

    outID = floatBitsToUint(inColor.a);
    outColor = vec4(inColor.rgb, 1.0);
    
    vec4 worldPos = skinMat * vec4(inPos.xyz, 1.0);
    outWorldPos = worldPos.xyz;
    outNormal = normalize(mat3(skinMat) * inNormal.xyz);
    
    gl_Position = pc.projection * pc.view * worldPos;
}
