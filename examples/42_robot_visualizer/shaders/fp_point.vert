#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec3 vPos;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec3 vLitColor;

layout(set = 0, binding = 0) buffer Data { vec4 pos[]; } all_buffers[];

struct Light {
    vec4 pos_radius; // view space
    vec4 color;
};

struct ClusterItem {
    uint offset;
    uint count;
};

layout(std430, set = 1, binding = 0) buffer LightBuffer { Light lights[]; };
layout(std430, set = 1, binding = 1) buffer ClusterItemBuffer { ClusterItem cluster_items[]; };
layout(std430, set = 1, binding = 2) buffer LightIndexBuffer { uint light_indices[]; };

layout(push_constant) uniform PC
{
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

void main()
{
  uint pt_idx = gl_InstanceIndex;
  uint v_idx = gl_VertexIndex;

  vec4 p = all_buffers[nonuniformEXT(pc.buf_idx)].pos[pt_idx];

  // Axis Remapping
  vec3 raw;
  float vals[4] = float[](0.0, p.x, p.y, p.z);
  raw.x = (pc.axis_map[0] < 0) ? -vals[-pc.axis_map[0]] : vals[pc.axis_map[0]];
  raw.y = (pc.axis_map[1] < 0) ? -vals[-pc.axis_map[1]] : vals[pc.axis_map[1]];
  raw.z = (pc.axis_map[2] < 0) ? -vals[-pc.axis_map[2]] : vals[pc.axis_map[2]];

  // 1. World & View Transform
  mat4 model = mat4(
      pc.pose_matrix[0], pc.pose_matrix[1], pc.pose_matrix[2], pc.pose_matrix[3],
      pc.pose_matrix[4], pc.pose_matrix[5], pc.pose_matrix[6], pc.pose_matrix[7],
      pc.pose_matrix[8], pc.pose_matrix[9], pc.pose_matrix[10], pc.pose_matrix[11],
      pc.pose_matrix[12], pc.pose_matrix[13], pc.pose_matrix[14], pc.pose_matrix[15]
  );

  vec3 worldPos = (model * vec4(raw, 1.0)).xyz;
  vec4 viewPos = pc.view * vec4(worldPos, 1.0);
  vec4 clipPos = pc.view_proj * vec4(worldPos, 1.0);

  // 2. Cluster Lighting (Once per point!)
  // Convert clip space to screen-ish cluster coords
  vec3 ndc = clipPos.xyz / clipPos.w;
  uint cx = uint(clamp((ndc.x * 0.5 + 0.5) * float(pc.cluster_x), 0.0, float(pc.cluster_x - 1)));
  uint cy = uint(clamp((ndc.y * 0.5 + 0.5) * float(pc.cluster_y), 0.0, float(pc.cluster_y - 1)));
  
  float viewZ = -viewPos.z;
  uint cz = 0;
  if (viewZ > pc.z_near) {
      cz = uint(float(pc.cluster_z) * log(viewZ / pc.z_near) / log(pc.z_far / pc.z_near));
  }
  cz = min(cz, pc.cluster_z - 1);
  uint cluster_index = cx + cy * pc.cluster_x + cz * pc.cluster_x * pc.cluster_y;

  ClusterItem item = cluster_items[cluster_index];
  
  // Bright HDR Blue base
  float h = p.z * 0.2 + 0.5;
  vec3 albedo = vec3(0.0, 0.5, 1.0) * h + vec3(0.0, 0.1, 0.4);
  vec3 total_light = vec3(0.2) * albedo; // Ambient

  vec3 N = vec3(0.0, 0.0, 1.0); // Simple Billboard Normal
  
  for (uint i = 0; i < item.count; i++) {
      uint light_idx = light_indices[item.offset + i];
      Light l = lights[light_idx];
      
      vec3 L_vec = l.pos_radius.xyz - viewPos.xyz;
      float dist = length(L_vec);
      float radius = l.pos_radius.w;
      
      if (dist < radius) {
          vec3 L = normalize(L_vec);
          float nDotL = max(dot(N, L), 0.0);
          float attenuation = clamp(1.0 - (dist * dist) / (radius * radius), 0.0, 1.0);
          attenuation *= attenuation;
          total_light += albedo * l.color.rgb * l.color.w * nDotL * attenuation;
      }
  }
  vLitColor = total_light;

  // 3. Quad Output
  vec2 corners[4] = vec2[](vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(-1.0, 1.0), vec2(1.0, 1.0));
  vec2 offset = corners[v_idx];
  vUV = offset;

  float ps = pc.point_size;
  vec2 vs = (pc.vw < 1.0) ? vec2(1920.0, 1080.0) : vec2(pc.vw, pc.vh);
  vec2 size = vec2(ps) / vs;

  gl_Position = clipPos;
  gl_Position.xy += offset * size * clipPos.w;

  vColor = vec4(albedo, 1.0);
  vPos = worldPos;
}
