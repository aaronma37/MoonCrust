#version 450

layout(location = 0) out vec2 vUV;

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint mode; // Matches tx in main.lua offset-wise
    float tx, ty, tz;
} pc;

void main() {
    vUV = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    
    // Scale quad to 0.8 units in world space
    float size = 0.8;
    vec3 pos = vec3(pc.tx, pc.ty + 1.2, pc.tz); 
    
    vec4 clip_pos = pc.mvp * vec4(pos, 1.0);
    // Perspective-correct billboarding
    vec2 offset = (vUV * 2.0 - 1.0) * size;
    clip_pos.xy += vec2(offset.x, -offset.y); // FLIP Y HERE
    
    gl_Position = clip_pos;
}
