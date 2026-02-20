#version 450
layout(location = 0) in vec4 vColor;
layout(location = 1) in vec3 vWorld;
layout(location = 0) out vec4 outColor;

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
    float cam_x;
    float cam_y;
    float cam_z;
    float occ_pad0;
    float occ1_x;
    float occ1_y;
    float occ1_z;
    float occ1_hy;
    float occ1_hz;
    float occ1_pad0;
    float occ1_pad1;
    float occ1_pad2;
    float occ2_x;
    float occ2_y;
    float occ2_z;
    float occ2_hy;
    float occ2_hz;
    float occ2_pad0;
    float occ2_pad1;
    float occ2_pad2;
} pc;

bool occluded_by_plane(float px, float py, float pz, float hy, float hz) {
    vec3 cam = vec3(pc.cam_x, pc.cam_y, pc.cam_z);
    vec3 d = vWorld - cam;
    if (abs(d.x) < 1e-6) return false;
    float t = (px - cam.x) / d.x;
    if (t <= 0.0 || t >= 1.0) return false;
    vec3 h = cam + d * t;
    return abs(h.y - py) <= hy && abs(h.z - pz) <= hz;
}

void main() {
    vec4 c = vColor;
    bool occ = occluded_by_plane(pc.occ1_x, pc.occ1_y, pc.occ1_z, pc.occ1_hy, pc.occ1_hz) ||
               occluded_by_plane(pc.occ2_x, pc.occ2_y, pc.occ2_z, pc.occ2_hy, pc.occ2_hz);
    if (occ) c.rgb *= 0.18;
    outColor = c;
}
