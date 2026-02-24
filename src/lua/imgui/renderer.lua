local ffi = require("ffi")
local vk = require("vulkan.ffi")
local mc = require("mc")
local gpu = require("mc.gpu")
local vulkan = require("vulkan")

local M = {
    white_uv = {0, 0}
}

local vert_shader = [[
#version 450
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aUV;
layout(location = 2) in vec4 aColor;

layout(push_constant) uniform PC {
    vec2 uScale;
    vec2 uTranslate;
    uint uTextureIdx;
    uint uBlurTextureIdx;
    vec2 uScreenSize;
    vec2 uWhiteUV;
} pc;

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec4 vColor;
layout(location = 2) out vec2 vScreenUV;

void main() {
    vUV = aUV;
    vColor = aColor;
    gl_Position = vec4(aPos * pc.uScale + pc.uTranslate, 0, 1);
    vScreenUV = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
}
]]

local frag_shader = [[
#version 450
#extension GL_EXT_nonuniform_qualifier : enable
layout(location = 0) in vec2 vUV;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec2 vScreenUV;

layout(set = 0, binding = 1) uniform sampler2D all_textures[];

layout(push_constant) uniform PC {
    vec2 uScale;
    vec2 uTranslate;
    uint uTextureIdx;
    uint uBlurTextureIdx;
    vec2 uScreenSize;
    vec2 uWhiteUV;
} pc;

layout(location = 0) out vec4 oColor;

void main() {
    vec4 texColor = texture(all_textures[nonuniformEXT(pc.uTextureIdx)], vUV);
    
    // Glassmorphism Heuristic: 
    // 1. Must have a blur texture.
    // 2. Alpha must be semi-transparent (backgrounds).
    // 3. Texture must be the font atlas (idx 0).
    // 4. UV must be pointing to the "White Pixel" (used for solid backgrounds).
    bool isWhitePixel = distance(vUV, pc.uWhiteUV) < 0.0001;
    
    if (pc.uBlurTextureIdx > 0 && vColor.a < 0.99 && vColor.a > 0.01 && pc.uTextureIdx == 0 && isWhitePixel) {
        vec4 blurColor = texture(all_textures[nonuniformEXT(pc.uBlurTextureIdx)], vScreenUV);
        oColor = vec4(mix(blurColor.rgb, vColor.rgb, vColor.a), 1.0);
    } else {
        oColor = vColor * texColor;
    }
}
]]

ffi.cdef[[
    typedef struct ImGuiPC {
        float scale[2];
        float translate[2];
        uint32_t tex_idx;
        uint32_t blur_tex_idx;
        float screen_size[2];
        float white_uv[2];
    } ImGuiPC;
]]

function M.init()
    local d = vulkan.get_device()
    
    -- Compile Shaders
    local shader = require("vulkan.shader")
    local v_spirv = shader.compile_glsl(vert_shader, vk.VK_SHADER_STAGE_VERTEX_BIT)
    local f_spirv = shader.compile_glsl(frag_shader, vk.VK_SHADER_STAGE_FRAGMENT_BIT)
    local v_mod = shader.create_module(d, v_spirv)
    local f_mod = shader.create_module(d, f_spirv)
    
    -- Vertex Layout for ImDrawVert
    -- struct ImDrawVert { ImVec2 pos; ImVec2 uv; ImU32 col; }
    local binding = ffi.new("VkVertexInputBindingDescription[1]", {{
        binding = 0,
        stride = 20, -- 8 (pos) + 8 (uv) + 4 (col)
        inputRate = vk.VK_VERTEX_INPUT_RATE_VERTEX
    }})
    
    local attributes = ffi.new("VkVertexInputAttributeDescription[3]", {
        { location = 0, binding = 0, format = vk.VK_FORMAT_R32G32_SFLOAT, offset = 0 },
        { location = 1, binding = 0, format = vk.VK_FORMAT_R32G32_SFLOAT, offset = 8 },
        { location = 2, binding = 0, format = vk.VK_FORMAT_R8G8B8A8_UNORM, offset = 16 }
    })
    
    local pipeline_mod = require("vulkan.pipeline")
    local pc_range = ffi.new("VkPushConstantRange[1]", {{
        stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT),
        offset = 0,
        size = 40 -- 8 (scale) + 8 (translate) + 4 (tex_idx) + 4 (blur_tex_idx) + 8 (screen_size) + 8 (white_uv)
    }})
    
    local layout = pipeline_mod.create_layout(d, {gpu.get_bindless_layout()}, pc_range)
    
    M.pipeline = pipeline_mod.create_graphics_pipeline(d, layout, v_mod, f_mod, {
        vertex_binding = binding,
        vertex_attributes = attributes,
        vertex_attribute_count = 3,
        topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        alpha_blend = true,
        depth_test = false,
        depth_write = false,
        cull_mode = vk.VK_CULL_MODE_NONE,
        color_formats = { vk.VK_FORMAT_B8G8R8A8_UNORM } -- Match linear swapchain
    })
    M.layout = layout
    
    -- Allocate dynamic buffers
    M.v_buffer = gpu.buffer(1024 * 1024 * 4, "vertex", nil, true) -- 4MB Vertex
    M.i_buffer = gpu.buffer(1024 * 1024 * 2, "index", nil, true)  -- 2MB Index
    
    -- Map buffers for easy access
    M.v_ptr = M.v_buffer.allocation.ptr
    M.i_ptr = M.i_buffer.allocation.ptr
end

function M.render(cb, draw_data)
    if not draw_data or draw_data.CmdListsCount == 0 then return end
    
    -- 1. Update Buffers
    local v_offset = 0
    local i_offset = 0
    
    local cmd_lists = ffi.cast("ImDrawList**", draw_data.CmdLists.Data)
    for n = 0, draw_data.CmdListsCount - 1 do
        local cmd_list = cmd_lists[n]
        local v_size = cmd_list.VtxBuffer.Size * 20
        local i_size = cmd_list.IdxBuffer.Size * 2 
        
        ffi.copy(M.v_ptr + v_offset, cmd_list.VtxBuffer.Data, v_size)
        ffi.copy(M.i_ptr + i_offset, cmd_list.IdxBuffer.Data, i_size)
        
        v_offset = v_offset + v_size
        i_offset = i_offset + i_size
    end
    
    -- 2. Bind Pipeline
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.pipeline)
    
    local viewport = ffi.new("VkViewport", {
        x = 0, y = 0,
        width = draw_data.DisplaySize.x,
        height = draw_data.DisplaySize.y,
        minDepth = 0.0,
        maxDepth = 1.0
    })
    vk.vkCmdSetViewport(cb, 0, 1, viewport)
    
    local sets = ffi.new("VkDescriptorSet[1]", {gpu.get_bindless_set()})
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, M.layout, 0, 1, sets, 0, nil)
    
    local v_offsets = ffi.new("VkDeviceSize[1]", {0})
    local v_buffers = ffi.new("VkBuffer[1]", {M.v_buffer.handle})
    vk.vkCmdBindVertexBuffers(cb, 0, 1, v_buffers, v_offsets)
    vk.vkCmdBindIndexBuffer(cb, M.i_buffer.handle, 0, vk.VK_INDEX_TYPE_UINT16)
    
    -- 3. Draw
    local pc = ffi.new("ImGuiPC")
    pc.scale[0] = 2.0 / draw_data.DisplaySize.x
    pc.scale[1] = 2.0 / draw_data.DisplaySize.y
    pc.translate[0] = -1.0 - draw_data.DisplayPos.x * pc.scale[0]
    pc.translate[1] = -1.0 - draw_data.DisplayPos.y * pc.scale[1]
    pc.blur_tex_idx = M.blur_tex_idx or 0
    pc.screen_size[0] = draw_data.DisplaySize.x
    pc.screen_size[1] = draw_data.DisplaySize.y
    pc.white_uv[0] = (M.white_uv and M.white_uv[1]) or 0
    pc.white_uv[1] = (M.white_uv and M.white_uv[2]) or 0
    
    local global_v_offset = 0
    local global_i_offset = 0
    
    for n = 0, draw_data.CmdListsCount - 1 do
        local cmd_list = cmd_lists[n]
        local cmd_buffer_data = ffi.cast("ImDrawCmd*", cmd_list.CmdBuffer.Data)
        for i = 0, cmd_list.CmdBuffer.Size - 1 do
            local cmd = cmd_buffer_data[i]
            
            if cmd.UserCallback ~= nil then
                if M.on_callback then
                    M.on_callback(cb, cmd.UserCallback, cmd.UserCallbackData)
                end
            else
                pc.tex_idx = tonumber(ffi.cast("uintptr_t", cmd.TexRef._TexID))
                vk.vkCmdPushConstants(cb, M.layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, 40, pc)
                
                local scissor = ffi.new("VkRect2D", {
                    offset = {
                        x = math.max(0, tonumber(cmd.ClipRect.x - draw_data.DisplayPos.x)),
                        y = math.max(0, tonumber(cmd.ClipRect.y - draw_data.DisplayPos.y))
                    },
                    extent = {
                        width = tonumber(cmd.ClipRect.z - cmd.ClipRect.x),
                        height = tonumber(cmd.ClipRect.w - cmd.ClipRect.y)
                    }
                })
                vk.vkCmdSetScissor(cb, 0, 1, scissor)
                vk.vkCmdDrawIndexed(cb, cmd.ElemCount, 1, cmd.IdxOffset + global_i_offset, cmd.VtxOffset + global_v_offset, 0)
            end
        end
        global_v_offset = global_v_offset + cmd_list.VtxBuffer.Size
        global_i_offset = global_i_offset + cmd_list.IdxBuffer.Size
    end
end

return M
