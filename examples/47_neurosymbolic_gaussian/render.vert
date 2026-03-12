#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Projected {
    vec2 pos;
    vec3 cov; // x2, xy, y2
    vec4 color;
    float depth;
};

struct SortEntry {
    uint key;
    uint value;
};

layout(set = 0, binding = 0) buffer ProjectedBuffer { Projected projected[]; } all_projected[];
layout(set = 0, binding = 0) buffer SortBuffer { SortEntry entries[]; } all_sort_buffers[];

layout(push_constant) uniform PushConstants {
    uint p_id;
    uint s_id;
    vec2 screen_size;
} pc;

layout(location = 0) out vec2 out_uv;
layout(location = 1) out vec4 out_color;
layout(location = 2) out vec3 out_cov;

void main() {
    uint splat_idx = all_sort_buffers[pc.s_id].entries[gl_VertexIndex / 6].value;
    Projected p = all_projected[pc.p_id].projected[splat_idx];

    if (p.depth <= 0.0) {
        gl_Position = vec4(0,0,0,0);
        return;
    }

    vec2 corners[6] = vec2[](
        vec2(-1.0, -1.0),
        vec2( 1.0, -1.0),
        vec2( 1.0,  1.0),
        vec2(-1.0, -1.0),
        vec2( 1.0,  1.0),
        vec2(-1.0,  1.0)
    );
    vec2 corner = corners[gl_VertexIndex % 6];

    float det = p.cov.x * p.cov.z - p.cov.y * p.cov.y;
    float mid = 0.5 * (p.cov.x + p.cov.z);
    float lambda1 = mid + sqrt(max(0.1, mid * mid - det));
    float radius = ceil(3.0 * sqrt(max(0.1, lambda1)));

    // Expand in pixel space, then back to NDC
    vec2 pos_pixels = (p.pos * 0.5 + 0.5) * pc.screen_size;
    vec2 out_pos_pixels = pos_pixels + corner * radius;
    vec2 out_pos_ndc = (out_pos_pixels / pc.screen_size) * 2.0 - 1.0;

    gl_Position = vec4(out_pos_ndc, 0.0, 1.0);
    
    out_uv = corner * radius;
    out_color = p.color;
    out_cov = p.cov;
}
