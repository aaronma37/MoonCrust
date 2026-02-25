#version 450
layout(location = 0) in flat vec2 vPos;
layout(location = 1) in flat vec2 vSize;
layout(location = 2) in flat vec4 vColor;
layout(location = 3) in flat vec4 vClip;
layout(location = 4) in flat uint vType;
layout(location = 5) in flat uint vFlags;
layout(location = 6) in flat float vRounding;
layout(location = 7) in vec2 vUV;
layout(location = 8) in flat uint vExtra;

layout(location = 0) out vec4 oColor;

float sdRoundedRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    // 1. ClipRect Discard (Vulkan gl_FragCoord is top-left origin by default)
    vec2 fragCoord = gl_FragCoord.xy;
    
    if (fragCoord.x < vClip.x || fragCoord.y < vClip.y || fragCoord.x > vClip.z || fragCoord.y > vClip.w) {
        discard;
    }

    // 2. SDF Rendering
    vec2 center = vPos + vSize * 0.5;
    vec2 p = fragCoord - center;
    float d = sdRoundedRect(p, vSize * 0.5, vRounding);
    
    // Antialiasing
    float alpha = 1.0 - smoothstep(-0.5, 0.5, d);
    
    if (vType == 0) { // Frame / Window
        oColor = vColor;
        oColor.a *= alpha;
    } else if (vType == 1) { // Button
        oColor = vColor;
        // Simple hover effect if flags bit 0 is set
        if ((vFlags & 1) != 0) oColor.rgb += 0.1;
        // Simple active effect if flags bit 1 is set
        if ((vFlags & 2) != 0) oColor.rgb -= 0.1;
        oColor.a *= alpha;
    } else if (vType == 2) { // Plot Area (Aperture)
        oColor = vec4(vColor.rgb, vColor.a * alpha);
    } else if (vType == 3) { // Slider
        float progress = float(vExtra) / 1000.0;
        if (vUV.x < progress) {
            oColor = vec4(vColor.rgb * 1.5, vColor.a * alpha); // Filled part
        } else {
            oColor = vec4(vColor.rgb * 0.5, vColor.a * alpha); // Background part
        }
    } else if (vType == 4) { // Separator
        oColor = vColor;
        oColor.a *= alpha;
    } else {
        oColor = vColor;
        oColor.a *= alpha;
    }

    if (oColor.a < 0.001) discard;
}
