#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec2 inUV;
layout(location = 0) out vec4 outCol;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PC {
    uint scene_tex_idx;
    float screen_w;
    float screen_h;
} pc;

float rgb_to_luma(vec3 rgb) {
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 texel_size = vec2(1.0 / pc.screen_w, 1.0 / pc.screen_h);
    vec3 rgbM = texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV).rgb;
    
    // FXAA Implementation (Fast Approximate Anti-Aliasing)
    float lumaM  = rgb_to_luma(rgbM);
    float lumaNW = rgb_to_luma(texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + vec2(-1.0, -1.0) * texel_size).rgb);
    float lumaNE = rgb_to_luma(texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + vec2(1.0, -1.0) * texel_size).rgb);
    float lumaSW = rgb_to_luma(texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + vec2(-1.0, 1.0) * texel_size).rgb);
    float lumaSE = rgb_to_luma(texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + vec2(1.0, 1.0) * texel_size).rgb);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * 0.125), 0.0078125);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(vec2(8.0, 8.0), max(vec2(-8.0, -8.0), dir * rcpDirMin)) * texel_size;

    vec3 rgbA = 0.5 * (
        texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + dir * (1.0 / 3.0 - 0.5)).rgb +
        texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + dir * (2.0 / 3.0 - 0.5)).rgb);
    
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + dir * (0.0 / 3.0 - 0.5)).rgb +
        texture(all_textures[nonuniformEXT(pc.scene_tex_idx)], inUV + dir * (3.0 / 3.0 - 0.5)).rgb);

    float lumaB = rgb_to_luma(rgbB);
    if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
        outCol = vec4(rgbA, 1.0);
    } else {
        outCol = vec4(rgbB, 1.0);
    }
}
