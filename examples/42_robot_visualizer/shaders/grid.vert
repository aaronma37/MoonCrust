#version 450

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec3 vPos;

layout(push_constant) uniform PC {
  mat4 view_proj;
  mat4 view;
  float vw, vh;
  float z_near, z_far;
  uint cluster_x, cluster_y, cluster_z;
  uint buf_idx;
  float point_size;
  int axis_map[4];
  float pose_matrix[16];
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
    vec2 cam_xy = vec2(pc.pose_matrix[12], pc.pose_matrix[13]);
    
    vUV = p.xy + cam_xy; // Shift UVs so grid pattern stays fixed in world
    vPos = p + vec3(cam_xy, -0.05); // Shift vertices to follow camera, 5cm below 0
    gl_Position = pc.view_proj * vec4(vPos, 1.0);
}
