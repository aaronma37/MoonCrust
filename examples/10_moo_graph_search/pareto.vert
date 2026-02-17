#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(set = 0, binding = 0) buffer AllBuffers {
    uint data[];
} all_buffers[];

layout(location = 0) out vec3 vColor;

void main() {
    uint idx = gl_VertexIndex;
    
    // Each solution is 2 floats (dist, cost)
    uint base = idx * 2;
    float dist = uintBitsToFloat(all_buffers[2].data[base + 0]);
    float cost = uintBitsToFloat(all_buffers[2].data[base + 1]);

    if (dist > 1e8) {
        gl_Position = vec4(2.0, 2.0, 0.0, 1.0);
        return;
    }

    // Normalizing based on expected graph scales
    float x = (dist / 40.0) - 0.9;
    float y = (cost / 40.0) - 0.9;

    gl_Position = vec4(x, -y, 0.0, 1.0);
    gl_PointSize = 8.0;
    vColor = vec3(1.0, 1.0, 1.0);
}
