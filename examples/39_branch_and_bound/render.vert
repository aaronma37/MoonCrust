#version 450
#extension GL_EXT_nonuniform_qualifier : require

struct Node {
    float val;
    float weight;
    uint  depth;
    uint  parent;
    uint  status; 
    float x_pos; 
    uint  p1, p2; 
};

layout(set = 0, binding = 0) buffer NodeBuffer { uint data[]; } all_bufs[];

layout(push_constant) uniform PushConstants {
    float dt;
    float time;
    uint  max_nodes;
    uint  num_items;
    float capacity;
    uint  start_idx;
    uint  num_to_process;
    uint  mode;
} pc;

layout(location = 0) out vec3 vColor;

vec2 get_node_pos(uint depth, float x_pos) {
    // Top-down growth
    float y = -0.9 + (float(depth) * 0.025); 
    return vec2(x_pos, y);
}

void main() {
    uint idx = gl_VertexIndex;
    uint b = idx * 8;
    uint depth = all_bufs[1].data[b+2];
    uint status = all_bufs[1].data[b+4];
    float x_pos = uintBitsToFloat(all_bufs[1].data[b+5]);

    if (pc.mode == 2) { // Nodes
        if (idx >= pc.max_nodes) { gl_Position = vec4(-2.0); return; }
        if (depth == 0 && idx > 0) { gl_Position = vec4(-2.0); return; }
        
        gl_Position = vec4(get_node_pos(depth, x_pos), 0.0, 1.0);
        
        if (status == 0) {
            gl_PointSize = 4.0 + 1.0 * sin(pc.time * 10.0);
            vColor = vec3(1.0, 0.8, 0.3); // Gold
        } else if (status == 1) {
            gl_PointSize = 1.5;
            vColor = vec3(0.8, 0.0, 0.0); // Pruned Red
        } else if (status == 2) {
            gl_PointSize = 5.0;
            vColor = vec3(0.0, 1.0, 0.5); // Green
        } else {
            gl_PointSize = 1.0;
            vColor = vec3(0.2, 0.4, 0.6); // Blue
        }
        
    } else { // Edges
        uint node_idx = idx / 2;
        uint is_parent = idx % 2;
        if (node_idx >= pc.max_nodes || node_idx == 0) { gl_Position = vec4(-2.0); return; }
        uint nb = node_idx * 8;
        if (all_bufs[1].data[nb+2] == 0) { gl_Position = vec4(-2.0); return; }

        uint target_idx = (is_parent == 1) ? all_bufs[1].data[nb+3] : node_idx;
        uint tb = target_idx * 8;
        
        float tx = uintBitsToFloat(all_bufs[1].data[tb+5]);
        uint  td = all_bufs[1].data[tb+2];
        
        gl_Position = vec4(get_node_pos(td, tx), 0.0, 1.0);
        vColor = (all_bufs[1].data[nb+4] == 1) ? vec3(0.3, 0.0, 0.0) : vec3(0.1, 0.2, 0.3);
    }
}
