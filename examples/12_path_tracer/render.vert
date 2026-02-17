#version 450

layout(location = 0) out vec2 vUV;

void main() {
    vUV = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    // Shrink quad size to 0.1 (10% of screen)
    float size = 0.1;
    gl_Position = vec4((vUV.x * 2.0 - 1.0) * size, ((1.0 - vUV.y) * 2.0 - 1.0) * size, 0.0, 1.0);
}
