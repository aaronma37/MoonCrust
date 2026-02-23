#version 450

layout(location = 0) out vec2 vUV;

void main() {
    // Fullscreen triangle covering -1 to 1 in clip space
    vec2 uvs[3] = vec2[](vec2(0.0, 0.0), vec2(2.0, 0.0), vec2(0.0, 2.0));
    gl_Position = vec4(uvs[gl_VertexIndex] * 2.0 - 1.0, 0.0, 1.0);
    vUV = uvs[gl_VertexIndex];
}