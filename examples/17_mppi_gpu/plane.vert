#version 450

layout(push_constant) uniform PushConstants {
    mat4 mvp;
    uint mode;
    uint count;
    uint pad0;
    uint pad1;
    float plane_x;
    float plane_y;
    float plane_z;
    float plane_hy;
    float plane_hz;
    float plane_pad0;
    float plane_pad1;
    float plane_pad2;
} pc;

layout(location = 0) out vec4 vColor;

void main() {
    vec2 q[6] = vec2[](
        vec2(-1.0, -1.0), vec2(-1.0,  1.0), vec2( 1.0,  1.0),
        vec2(-1.0, -1.0), vec2( 1.0,  1.0), vec2( 1.0, -1.0)
    );
    vec2 uv = q[gl_VertexIndex];

    vec3 p = vec3(
        pc.plane_x,
        pc.plane_y + uv.x * pc.plane_hy,
        pc.plane_z + uv.y * pc.plane_hz
    );

    gl_Position = pc.mvp * vec4(p, 1.0);
    vColor = vec4(0.88, 0.10, 0.10, 1.0);
}
