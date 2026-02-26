#version 450
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_gpu_shader_fp64 : enable

layout(set = 0, binding = 0) buffer Data { uint u32[]; } all_buffers[];

layout(push_constant) uniform PC {
    uint gtb_idx;
    uint slot_offset;
    uint msg_size;
    uint head_idx;
    uint field_offset;
    uint history_count;
    uint is_double;
    float range_min;
    float range_max;
} pc;

layout(location = 0) out vec4 vColor;

void main() {
    uint i = gl_VertexIndex;
    if (i >= pc.history_count) return;

    // Unwrap circular buffer
    uint data_idx = (pc.head_idx + i) % pc.history_count;
    uint base_u32 = (pc.slot_offset / 4) + (data_idx * (pc.msg_size / 4));
    uint field_u32 = base_u32 + (pc.field_offset / 4);
    
    float val = 0.0;
    if (pc.is_double != 0) {
        uint low = all_buffers[nonuniformEXT(pc.gtb_idx)].u32[field_u32];
        uint high = all_buffers[nonuniformEXT(pc.gtb_idx)].u32[field_u32 + 1];
        val = float(packDouble2x32(uvec2(low, high)));
    } else {
        val = uintBitsToFloat(all_buffers[nonuniformEXT(pc.gtb_idx)].u32[field_u32]);
    }

    // Normalize value based on provided range
    float range = pc.range_max - pc.range_min;
    if (abs(range) < 0.0001) range = 1.0;
    float norm_y = (val - pc.range_min) / range;
    
    // Map to NDC (-1 to 1)
    float x_ndc = (float(i) / float(pc.history_count - 1)) * 2.0 - 1.0;
    float y_ndc = norm_y * 2.0 - 1.0;

    gl_Position = vec4(x_ndc, y_ndc, 0.0, 1.0);
    gl_PointSize = 8.0;
    vColor = vec4(0.0, 0.9, 1.0, 1.0); // Cyan
}
