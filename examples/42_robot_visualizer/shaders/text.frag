#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(location = 0) out vec4 oColor;

void main() {
    // Sample the font atlas (Binding 1, Index 0)
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
