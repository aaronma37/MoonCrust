#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    float data[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    float dt;
    uint  buf_id;
    uint  attr_id;
    uint  tex_id;
} pc;

layout(location = 0) out float vSpeed;

void main() {
    uint idx = gl_VertexIndex;
    uint p_offset = idx * 8;
    
    vec3 world_pos = vec3(all_buffers[pc.buf_id].data[p_offset+0],
                          all_buffers[pc.buf_id].data[p_offset+1],
                          all_buffers[pc.buf_id].data[p_offset+2]);
    
    vec3 vel = vec3(all_buffers[pc.buf_id].data[p_offset+4],
                    all_buffers[pc.buf_id].data[p_offset+5],
                    all_buffers[pc.buf_id].data[p_offset+6]);

    vec3 view_pos = world_pos + vec3(0.0, 0.0, 2.5);
    float fov = 1.5;
    gl_Position = vec4(view_pos.xy * fov, view_pos.z * 0.1, view_pos.z);
    gl_PointSize = 4.0 / view_pos.z; 
    
    vSpeed = length(vel);
}
