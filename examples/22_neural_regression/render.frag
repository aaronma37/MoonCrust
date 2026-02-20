#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) buffer AllBuffers {
    float data[];
} all_buffers[];

layout(push_constant) uniform PushConstants {
    uint weightBuf;
    uint targetImg;
    float lr;
    float time;
    vec2 resolution;
} pc;

void main() {
    vec2 x = gl_FragCoord.xy / pc.resolution;
    
    // LOAD WEIGHTS (Hidden=32)
    float local_W1[64];
    float local_B1[32];
    float local_W2[96];
    float local_B2[3];

    for(int i=0; i<64; i++) local_W1[i] = all_buffers[pc.weightBuf].data[i];
    for(int i=0; i<32; i++) local_B1[i] = all_buffers[pc.weightBuf].data[64 + i];
    for(int i=0; i<96; i++) local_W2[i] = all_buffers[pc.weightBuf].data[64 + 32 + i];
    for(int i=0; i<3; i++)  local_B2[i] = all_buffers[pc.weightBuf].data[64 + 32 + 96 + i];

    // FORWARD PASS
    float h1[32];
    for(int i=0; i<32; i++) {
        float sum = local_B1[i];
        sum += x.x * local_W1[i*2 + 0];
        sum += x.y * local_W1[i*2 + 1];
        h1[i] = tanh(sum);
    }
    
    vec3 out_y = vec3(0.0);
    for(int i=0; i<3; i++) {
        out_y[i] = local_B2[i];
        for(int j=0; j<32; j++) {
            out_y[i] += h1[j] * local_W2[i*32 + j];
        }
    }
    out_y = 1.0 / (1.0 + exp(-out_y));

    outColor = vec4(out_y, 1.0);
}
