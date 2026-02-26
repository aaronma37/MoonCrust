#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out float vLineDist; // -1 to 1 across the line
layout(location = 3) out float vLineWidth; // thickness in pixels

layout(set = 0, binding = 0) buffer Data { uint u32[]; } all_buffers[];

layout(push_constant) uniform PC {
    mat4 view_proj;
    uint buf_idx;
    float point_size;
    float vw, vh;
    float pose_x, pose_y, pose_z, pose_yaw;
} pc;

void main() {
    uint segment_idx = gl_VertexIndex / 6;
    uint vertex_in_segment = gl_VertexIndex % 6;
    
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

    vec4 color = vec4(
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 3]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 4]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 5]),
        uintBitsToFloat(all_buffers[nonuniformEXT(pc.buf_idx)].u32[base + 6])
    );

    vec4 clip0 = pc.view_proj * vec4(p0, 1.0);
    vec4 clip1 = pc.view_proj * vec4(p1, 1.0);
    
    vec2 viewport_size = vec2(pc.vw, pc.vh);
    
    // Project to screen space
    vec2 screen0 = (clip0.xy / clip0.w) * viewport_size * 0.5;
    vec2 screen1 = (clip1.xy / clip1.w) * viewport_size * 0.5;
    
    vec2 dir = screen1 - screen0;
    float len = length(dir);
    
    // If segment is too short or invalid, degenerate it
    if (len < 0.0001) {
        gl_Position = vec4(0, 0, 0, 0);
        return;
    }
    
    dir /= len;
    vec2 normal = vec2(-dir.y, dir.x);
    
    // Thickness in pixels (default to 2.0 if point_size is not set)
    float thickness = pc.point_size > 0.0 ? pc.point_size : 2.0;
    // Add 1 pixel for AA margin
    float expanded_thickness = thickness + 2.0;
    
    float side = 0.0;
    vec4 pos = vec4(0);
    
    // Expansion logic
    if (vertex_in_segment == 0) { pos = clip0; pos.xy += (normal * expanded_thickness * clip0.w) / viewport_size; side = -1.0; }
    else if (vertex_in_segment == 1) { pos = clip0; pos.xy -= (normal * expanded_thickness * clip0.w) / viewport_size; side = 1.0; }
    else if (vertex_in_segment == 2) { pos = clip1; pos.xy += (normal * expanded_thickness * clip1.w) / viewport_size; side = -1.0; }
    else if (vertex_in_segment == 3) { pos = clip1; pos.xy += (normal * expanded_thickness * clip1.w) / viewport_size; side = -1.0; }
    else if (vertex_in_segment == 4) { pos = clip0; pos.xy -= (normal * expanded_thickness * clip0.w) / viewport_size; side = 1.0; }
    else if (vertex_in_segment == 5) { pos = clip1; pos.xy -= (normal * expanded_thickness * clip1.w) / viewport_size; side = 1.0; }

    vColor = color;
    vPos = (vertex_in_segment < 2 || vertex_in_segment == 4) ? p0 : p1;
    vLineDist = side * (expanded_thickness / thickness); 
    vLineWidth = thickness;
    gl_Position = pos;
}
