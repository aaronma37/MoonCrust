#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out float vLineDist; // -1 to 1 across the line

layout(set = 0, binding = 0) buffer Data { uint u32[]; } all_buffers[];

layout(push_constant) uniform PC {
    mat4 view_proj;
    uint buf_idx;
    float point_size; // We'll reuse this for line thickness
} pc;

void main() {
    // We are drawing 6 vertices per segment (2 triangles)
    uint segment_idx = gl_VertexIndex / 6;
    uint vertex_in_segment = gl_VertexIndex % 6;
    
    // Each vertex is 7 floats (x,y,z, r,g,b,a) = 28 bytes
    // 2 vertices per segment = 56 bytes
    uint base = segment_idx * (7 * 2);
    
    vec3 p0 = vec3(
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 0]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 1]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 2])
    );
    vec3 p1 = vec3(
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 7]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 8]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 9])
    );
    
    vec4 c0 = unpackUnorm4x8(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 3]); // Note: This depends on how data is packed
    // Actually, our LineVertex struct in Lua is 7 floats. Let's read them as floats.
    vec4 color = vec4(
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 3]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 4]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 5]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 6])
    );

    vec4 clip0 = pc.view_proj * vec4(p0, 1.0);
    vec4 clip1 = pc.view_proj * vec4(p1, 1.0);
    
    vec2 screen0 = clip0.xy / clip0.w;
    vec2 screen1 = clip1.xy / clip1.w;
    
    vec2 dir = normalize(screen1 - screen0);
    vec2 normal = vec2(-dir.y, dir.x);
    
    // Line thickness in screen units (normalized -1 to 1)
    float thickness = (pc.point_size / 1000.0); 
    
    float side = 0.0;
    vec4 pos = vec4(0);
    
    if (vertex_in_segment == 0) { pos = clip0; pos.xy += normal * thickness * clip0.w; side = -1.0; }
    else if (vertex_in_segment == 1) { pos = clip0; pos.xy -= normal * thickness * clip0.w; side = 1.0; }
    else if (vertex_in_segment == 2) { pos = clip1; pos.xy += normal * thickness * clip1.w; side = -1.0; }
    else if (vertex_in_segment == 3) { pos = clip1; pos.xy += normal * thickness * clip1.w; side = -1.0; }
    else if (vertex_in_segment == 4) { pos = clip0; pos.xy -= normal * thickness * clip0.w; side = 1.0; }
    else if (vertex_in_segment == 5) { pos = clip1; pos.xy -= normal * thickness * clip1.w; side = 1.0; }

    vColor = color;
    vPos = (vertex_in_segment < 2 || vertex_in_segment == 4) ? p0 : p1;
    vLineDist = side;
    gl_Position = pos;
}
