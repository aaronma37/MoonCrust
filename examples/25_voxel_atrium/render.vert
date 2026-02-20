#version 450
layout(location = 0) out vec2 vUV;
void main() {
    vUV = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    gl_Position = vec4(vUV.x * 2.0 - 1.0, (1.0 - vUV.y) * 2.0 - 1.0, 0.0, 1.0);
}
