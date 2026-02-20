#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) out vec3 vColor;

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
    uint instanceCount;
    uint instanceBuf;
    uint drawBuf;
    uint culledBuf;
} pc;

vec3 cube_vertices[8] = vec3[](
    vec3(-1,-1,-1), vec3(1,-1,-1), vec3(1,1,-1), vec3(-1,1,-1),
    vec3(-1,-1,1), vec3(1,-1,1), vec3(1,1,1), vec3(-1,1,1)
);

int cube_indices[36] = int[](
    0,1,2, 2,3,0, 4,5,6, 6,7,4, 0,4,7, 7,3,0,
    1,5,6, 6,2,1, 0,1,5, 5,4,0, 3,2,6, 6,7,3
);

void main() {
    uint instance_ptr = all_buffers[pc.culledBuf].data[gl_InstanceIndex];
    uint i_base = instance_ptr * 8;
    
    vec3 pos = vec3(
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 0]),
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 1]),
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 2])
    );
    float scale = uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 3]);
    vec3 color = vec3(
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 4]),
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 5]),
        uintBitsToFloat(all_buffers[pc.instanceBuf].data[i_base + 6])
    );

    vec3 local_pos = cube_vertices[cube_indices[gl_VertexIndex]] * scale;
    gl_Position = pc.viewProj * vec4(pos + local_pos, 1.0);
    vColor = color;
}
