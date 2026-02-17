#version 450

layout(location = 0) out vec2 vUV;

void main() {
    vUV = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    // Flip Y: vUV.y goes from 0 at top to 1 at bottom, but we want 1 at top
    gl_Position = vec4(vUV.x * 2.0 - 1.0, (1.0 - vUV.y) * 2.0 - 1.0, 0.0, 1.0);
}
