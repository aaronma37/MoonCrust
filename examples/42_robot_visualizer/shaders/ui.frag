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
    // 1. ClipRect Discard
    vec2 fragCoord = gl_FragCoord.xy;
    if (fragCoord.x < vClip.x || fragCoord.y < vClip.y || fragCoord.x > vClip.z || fragCoord.y > vClip.w) {
        discard;
    }

    // 2. SDF Rendering
    vec2 center = vPos + vSize * 0.5;
    vec2 p = fragCoord - center;
    float d = sdRoundedRect(p, vSize * 0.5, vRounding);
    float alpha = 1.0 - smoothstep(-0.5, 0.5, d);
    
    if (vType == 2) { 
        if (vExtra == 0) {
            oColor = vec4(1.0, 0.0, 1.0, 1.0); 
        } else {
            uint texIdx = nonuniformEXT(vExtra);
            vec4 texColor = texture(all_textures[texIdx], vUV);
            
            // 25-TAP 5x5 BOX KERNEL for Plots (Extreme Thickness)
            if (vExtra == 105) {
                float off = 0.0012; 
                texColor = vec4(0.0);
                for(int y = -2; y <= 2; y++) {
                    for(int x = -2; x <= 2; x++) {
                        texColor += texture(all_textures[texIdx], vUV + vec2(x * off, y * off));
                    }
                }
                texColor /= 9.0; // Boosted normalization
                texColor.rgb *= 1.8;
            }
            
            oColor = vec4(texColor.rgb, texColor.a * alpha);
        }
    } else if (vType == 3) { // Slider
        float progress = float(vExtra) / 1000.0;
        if (vUV.x < progress) {
            oColor = vec4(vColor.rgb * 1.5, vColor.a * alpha);
        } else {
            oColor = vec4(vColor.rgb * 0.5, vColor.a * alpha);
        }
    } else if (vType == 5) { // InputText
        bool is_active = (vFlags & 2) != 0;
        if (is_active) {
            oColor = vec4(vColor.rgb * 1.5 + vec3(0.0, 0.4, 0.8), vColor.a * alpha);
        } else {
            oColor = vec4(vColor.rgb * 0.8, vColor.a * alpha);
        }
    } else {
        oColor = vColor;
        // Apply Hover Highlight (Flag 1)
        if ((vFlags & 1) != 0) {
            oColor.rgb += vec3(0.1, 0.12, 0.15);
        }
        oColor.a *= alpha;
    }

    if (oColor.a < 0.001) discard;
}
