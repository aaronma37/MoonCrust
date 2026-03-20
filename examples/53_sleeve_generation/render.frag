#version 460
layout(location = 0) in vec3 inNormal;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) in flat uint inBoneId;
layout(location = 4) in vec2 inUV; // x=theta_norm (0-1), y=t_norm (0-1)

layout(push_constant) uniform PC {
    mat4 projection_view;
    mat4 model;
    vec2 mouse_pos;
    float outline_width;
    float wireframe_mode;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    if (pc.outline_width > 0.0) {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // DEBUG: Make the head bright magenta
    // We set inBoneIds.x to head_bone_id in vertex shader
    // The character body uses segments, so its bone IDs will vary.
    // If the color is magenta, it's the SDF head.
    vec3 color = inColor;
    
    // For now, let's just make ALL non-body meshes magenta to see them
    // Body meshes have UVs (sticks/rings), SDF head doesn't really (it's 0).
    if (inUV.x == 0.0 && inUV.y == 0.0) {
        color = vec3(1.0, 0.0, 1.0); 
    }

    vec3 normal = normalize(inNormal);
    vec3 lightDir = normalize(vec3(10, 10, 10));
    float diff = max(dot(normal, lightDir), 0.0);
    
    if (diff > 0.4) diff = 0.7;
    else diff = 0.45;
    
    vec3 finalCol = color * diff;

    if (pc.wireframe_mode > 0.5) {
        float sticks = abs(sin(inUV.x * 8.0 * 3.14159265));
        float stick_edge = smoothstep(0.1, 0.0, sticks);
        float rings = abs(sin(inUV.y * 16.0 * 3.14159265));
        float ring_edge = smoothstep(0.1, 0.0, rings);
        float grid = max(stick_edge, ring_edge);
        finalCol = mix(finalCol * 0.2, vec3(0.0, 1.0, 1.0), grid);
    }

    outColor = vec4(finalCol, 1.0);
}
