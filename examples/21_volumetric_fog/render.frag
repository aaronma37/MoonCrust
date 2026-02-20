#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 vRayDir;
layout(location = 1) in vec2 vUV;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler3D fog_tex[];

layout(push_constant) uniform PushConstants {
    mat4 invViewProj;
    vec4 camPos;   // w is pad0
    vec4 l1pos_i;  // xyz is pos, w is intensity
    vec4 l2pos_i;  // xyz is pos, w is intensity
    float time;
    uint grid_id;
} pc;

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float phase(float g, float cos_theta) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * 3.14159 * pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5));
}

void main() {
    vec3 ray_origin = pc.camPos.xyz;
    vec3 ray_dir = normalize(vRayDir - ray_origin);
    
    vec3 sun_dir = normalize(vec3(1.0, 0.6, -0.5));
    vec3 ambient = vec3(0.01, 0.02, 0.04);
    vec3 sun_col = vec3(1.0, 0.8, 0.5) * 3.0;
    
    float cos_theta = dot(ray_dir, sun_dir);
    float p_func = phase(0.7, cos_theta);
    
    vec3 accum = vec3(0.0);
    float transmittance = 1.0;
    float jitter = hash12(gl_FragCoord.xy + pc.time);
    float step_size = 0.3;
    
    for(int i = 0; i < 80; i++) {
        float d_dist = (float(i) + jitter) * step_size;
        vec3 p = ray_origin + ray_dir * d_dist;
        
        vec3 uv = (p + vec3(10, 0, 10)) / vec3(20, 10, 20);
        if (any(lessThan(uv, vec3(0))) || any(greaterThan(uv, vec3(1)))) {
            if (dot(p, p) > 600.0 && i > 50) break;
            continue;
        }
        
        float density = texture(fog_tex[pc.grid_id], uv).a;
        
        if (density > 0.005) {
            // 1. Sun Shadow
            float sun_shadow = 0.0;
            for(int j = 1; j <= 2; j++) {
                vec3 sp = p + sun_dir * float(j) * 0.8;
                vec3 suv = (sp + vec3(10, 0, 10)) / vec3(20, 10, 20);
                sun_shadow += texture(fog_tex[pc.grid_id], suv).a;
            }
            float sun_atten = exp(-sun_shadow * 2.0);
            
            // 2. Point Light 1 (Cyan Flicker)
            vec3 l1_dir = pc.l1pos_i.xyz - p;
            float l1_dist = length(l1_dir);
            float l1_atten = pc.l1pos_i.w / (1.0 + l1_dist * l1_dist);
            vec3 l1_col = vec3(0.2, 0.8, 1.0) * l1_atten;
            
            // 3. Point Light 2 (Orange Flicker)
            vec3 l2_dir = pc.l2pos_i.xyz - p;
            float l2_dist = length(l2_dir);
            float l2_atten = pc.l2pos_i.w / (1.0 + l2_dist * l2_dist);
            vec3 l2_col = vec3(1.0, 0.5, 0.1) * l2_atten;

            vec3 col = ambient + (sun_col * sun_atten * p_func) + l1_col + l2_col;
            
            float detail = fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
            float d_mod = density * (0.8 + 0.4 * detail);

            float weight = d_mod * step_size;
            accum += col * weight * transmittance;
            transmittance *= clamp(1.0 - weight, 0.0, 1.0);
        }
        
        if (transmittance < 0.01) break;
    }
    
    accum = 1.0 - exp(-accum * 1.0);
    outColor = vec4(accum, 1.0 - transmittance);
}
