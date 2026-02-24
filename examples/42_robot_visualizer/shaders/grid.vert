#version 450

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec3 vPos;

layout(push_constant) uniform PC {
    mat4 view_proj;
} pc;

void main() {
    // Large ground quad
    vec3 pos[4] = vec3[](
        vec3(-100, -100, 0),
        vec3( 100, -100, 0),
        vec3(-100,  100, 0),
        vec3( 100,  100, 0)
    );
    vec3 p = pos[gl_VertexIndex];
    vUV = p.xy;
    vPos = p;
    gl_Position = pc.view_proj * vec4(p, 1.0);
}
