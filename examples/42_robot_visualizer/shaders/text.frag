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

    // 2. Sample the font atlas (Binding 1, Index 0)
    // In MoonCrust, the first uploaded font atlas usually lands at index 0 of binding 1.
    vec4 texColor = texture(all_textures[0], vUV);
    
    // ImGui standard fonts store the glyph in the alpha channel or as a white image with alpha.
    // MoonCrust uploads the font atlas as R8G8B8A8, so we use the alpha or red channel.
    float alpha = texColor.a; 
    
    // Fallback: if the texture is purely greyscale, use the red channel
    if (texColor.r > 0.0 && texColor.a == 1.0) {
        alpha = texColor.r;
    }
    
    oColor = vec4(vColor.rgb, vColor.a * alpha);
    
    if (oColor.a < 0.01) discard;
}
