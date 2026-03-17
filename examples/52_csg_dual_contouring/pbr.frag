#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 inNormal;
layout(location = 1) flat in vec4 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) flat in uint inID;

layout(location = 0) out vec4 outFragColor;

layout(push_constant) uniform PC {
    mat4 projection;
    mat4 view;
    vec3 cam_pos;
    uint bone_count;
    uint bones_idx;
} pc;

void main() {
    vec3 N = normalize(inNormal);
    vec3 L = normalize(vec3(1.0, 1.0, 1.0));
    vec3 V = normalize(pc.cam_pos - inWorldPos);
    vec3 H = normalize(L + V);

    float diff = max(dot(N, L), 0.1);
    float spec = pow(max(dot(N, H), 0.0), 32.0);
    
    float rim = 1.0 - max(dot(N, V), 0.0);
    rim = pow(rim, 4.0);

    vec3 baseColor = inColor.rgb;
    
    if (inID >= 10) {
        baseColor *= 1.2;
    }

    vec3 color = baseColor * diff + vec3(0.3) * spec + vec3(0.5) * rim * baseColor;
    color += baseColor * 0.1;

    outFragColor = vec4(pow(color, vec3(1.0/2.2)), 1.0);
}
