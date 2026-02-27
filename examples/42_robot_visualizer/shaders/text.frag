#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec4 vClip;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(location = 0) out vec4 oColor;

void main() {
    // 1. ClipRect Discard
    vec2 fragCoord = gl_FragCoord.xy;
    if (fragCoord.x < vClip.x || fragCoord.y < vClip.y || fragCoord.x > vClip.z || fragCoord.y > vClip.w) {
        discard;
    }

    // 2. Sample the font atlas (Standard Linear)
    vec4 texColor = texture(all_textures[0], vUV);
    float alpha = texColor.a;
    if (texColor.r > 0.0 && texColor.a == 1.0) alpha = texColor.r;
    
        // 3. Hard Pixel Threshold (Wonderful Terminal Look)
        // Forcing alpha to binary (on/off) makes pixel fonts look perfect
        alpha = (alpha > 0.5) ? 1.0 : 0.0;
        
        oColor = vec4(vColor.rgb, vColor.a * alpha);
        if (oColor.a < 0.01) discard;
    }
