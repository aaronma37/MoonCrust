#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in flat vec2 vPos;
layout(location = 1) in flat vec2 vSize;
layout(location = 2) in flat vec4 vColor;
layout(location = 3) in flat vec4 vClip;
layout(location = 4) in flat uint vType;
layout(location = 5) in flat uint vFlags;
layout(location = 6) in flat float vRounding;
layout(location = 7) in vec2 vUV;
layout(location = 8) in flat uint vExtra;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(location = 0) out vec4 oColor;

float sdRoundedRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 center = vPos + vSize * 0.5;
    vec2 p = gl_FragCoord.xy - center;
    float d = sdRoundedRect(p, vSize * 0.5, vRounding);
    float alpha = 1.0 - smoothstep(-0.5, 0.5, d);
    
    if (vType == 2) { 
        if (vExtra == 0) {
            oColor = vec4(1.0, 0.0, 1.0, 1.0); 
        } else {
            uint texIdx = nonuniformEXT(vExtra);
            vec4 texColor = texture(all_textures[texIdx], vUV);
            
            // THICKENING KERNEL for Plots
            if (vExtra == 105) {
                float off = 0.0015; // Sample offset
                texColor += texture(all_textures[texIdx], vUV + vec2(off, 0));
                texColor += texture(all_textures[texIdx], vUV + vec2(-off, 0));
                texColor += texture(all_textures[texIdx], vUV + vec2(0, off));
                texColor += texture(all_textures[texIdx], vUV + vec2(0, -off));
                texColor *= 0.5; // Merge and boost
                texColor.rgb *= 2.0; 
            }
            
            oColor = vec4(texColor.rgb, texColor.a * alpha);
        }
    } else {
        oColor = vColor;
        oColor.a *= alpha;
    }

    if (oColor.a < 0.001) discard;
}
