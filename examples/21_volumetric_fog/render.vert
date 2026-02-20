#version 450

layout(location = 0) out vec3 vRayDir;
layout(location = 1) out vec2 vUV;

layout(push_constant) uniform PushConstants {
    mat4 invViewProj;
    vec3 camPos;
    float time;
    uint grid_id;
} pc;

void main() {
    vec2 uv = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    vUV = uv;
    gl_Position = vec4(uv * 2.0 - 1.0, 0.0, 1.0);
    
    vec4 target = pc.invViewProj * vec4(gl_Position.xy, 1.0, 1.0);
    vRayDir = target.xyz / target.w;
}
