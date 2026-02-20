#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AudioBuffer {
    float samples[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    uint buffer_id;
    uint count;
    float time;
} pc;

layout(location = 0) out float vSample;

void main() {
    uint idx = gl_VertexIndex;
    float val = all_buffers[pc.buffer_id].samples[idx];
    
    float x = (float(idx) / float(pc.count)) * 2.0 - 1.0;
    float y = val;
    
    gl_Position = vec4(x, y, 0.0, 1.0);
    gl_PointSize = 2.0;
    vSample = val;
}
