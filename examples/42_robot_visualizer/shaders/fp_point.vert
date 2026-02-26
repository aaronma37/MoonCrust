#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec3 vViewPos;

layout(set = 0, binding = 0) buffer Data
{
  vec4 pos[];
}
all_buffers[];

layout(push_constant) uniform PC
{
  mat4 view_proj;
  mat4 view;
  float vw, vh;
  float z_near, z_far;
  uint cluster_x, cluster_y, cluster_z;
  uint buf_idx;
  float point_size;
  float pose_x, pose_y, pose_z, pose_yaw;
}
pc;

void main()
{
  uint pt_idx = gl_InstanceIndex;
  uint v_idx = gl_VertexIndex;

  vec4 p = all_buffers[nonuniformEXT(pc.buf_idx)].pos[pt_idx];

  // Rotate and Translate
  float s = sin(pc.pose_yaw);
  float c = cos(pc.pose_yaw);
  vec3 worldPos;
  worldPos.x = p.x * c - p.y * s + pc.pose_x;
  worldPos.y = p.x * s + p.y * c + pc.pose_y;
  worldPos.z = p.z + pc.pose_z;

  vec4 viewPos = pc.view * vec4(worldPos, 1.0);
  vViewPos = viewPos.xyz;

  // Quad corner offsets (-1 to 1)
  vec2 corners[4] = vec2[](vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(-1.0, 1.0), vec2(1.0, 1.0));
  vec2 offset = corners[v_idx];
  vUV = offset;

  float ps = pc.point_size * 0.1; // Scale down a bit for cleaner look
  vec2 vs = (pc.vw < 1.0) ? vec2(1920.0, 1080.0) : vec2(pc.vw, pc.vh);
  vec2 size = vec2(ps) / vs;

  gl_Position = pc.view_proj * vec4(worldPos, 1.0);
  gl_Position.xy += offset * size * gl_Position.w;

  // Bright HDR Blue for maximum visibility
  float h = p.z * 0.2 + 0.5;
  vColor = vec4(vec3(0.0, 0.5, 1.0) * h + vec3(0.0, 0.1, 0.4), 1.0);
  vPos = worldPos;
}
