#version 450
#extension GL_EXT_nonuniform_qualifier : enable

struct UIElement {
    vec2 pos;
    vec2 size;
    vec4 color;
    vec4 clip;
    uint type;
    uint flags;
    float rounding;
    uint extra;
};

layout(set = 0, binding = 0) readonly buffer UI_SSBO {
    UIElement elements[];
} ui_data[];

layout(push_constant) uniform PC {
    uint ssbo_idx;
    uint padding; // Explicit alignment padding
    vec2 screen_size;
} pc;

layout(location = 0) out flat vec2 vPos;
layout(location = 1) out flat vec2 vSize;
layout(location = 2) out flat vec4 vColor;
layout(location = 3) out flat vec4 vClip;
layout(location = 4) out flat uint vType;
layout(location = 5) out flat uint vFlags;
layout(location = 6) out flat float vRounding;
layout(location = 7) out vec2 vUV;
layout(location = 8) out flat uint vExtra;

void main() {
    UIElement e = ui_data[nonuniformEXT(pc.ssbo_idx)].elements[gl_InstanceIndex];
    
    // Unit quad vertices (Triangle Strip)
    vec2 quad[4] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );
    
    vec2 p = quad[gl_VertexIndex];
    vUV = p; // Unit space [0, 1]
    
    // Map to screen pixels then to NDC
    vec2 pixel_pos = e.pos + p * e.size;
    vec2 ndc = (pixel_pos / pc.screen_size) * 2.0 - 1.0;
    
    gl_Position = vec4(ndc, 0.0, 1.0);
    
    vPos = e.pos;
    vSize = e.size;
    vColor = e.color;
    vClip = e.clip;
    vType = e.type;
    vFlags = e.flags;
    vRounding = e.rounding;
    vExtra = e.extra;
}
