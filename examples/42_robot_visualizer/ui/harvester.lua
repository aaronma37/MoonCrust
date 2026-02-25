local ffi = require("ffi")

pcall(ffi.cdef, [[
    typedef struct TextInstance {
        float x, y, w, h;
        float u, v, uw, vh;
        float clip_min_x, clip_min_y, clip_max_x, clip_max_y;
        uint32_t color;
        uint32_t padding[3];
    } TextInstance;
]])

local M = {
    white_uv = {0, 0}
}

function M.harvest_text(draw_data, text_buffer)
    if not draw_data then return 0 end
    local instances = ffi.cast("TextInstance*", text_buffer.allocation.ptr)
    local count = 0
    local max_instances = 20000 -- Matches MAX_TEXT_INSTANCES
    
    local cmd_lists = ffi.cast("ImDrawList**", draw_data.CmdLists.Data)
    for n = 0, draw_data.CmdListsCount - 1 do
        local cmd_list = cmd_lists[n]
        local vtx_buffer = ffi.cast("unsigned char*", cmd_list.VtxBuffer.Data)
        local idx_buffer = ffi.cast("unsigned short*", cmd_list.IdxBuffer.Data)
        
        local cmd_buffer = ffi.cast("ImDrawCmd*", cmd_list.CmdBuffer.Data)
        for i = 0, cmd_list.CmdBuffer.Size - 1 do
            if count >= max_instances then goto done end
            local cmd = cmd_buffer[i]
            local tex_id = tonumber(ffi.cast("uintptr_t", cmd.TexRef._TexID))
            
            local elem_count = cmd.ElemCount
            local idx_offset = cmd.IdxOffset
            local vtx_offset = cmd.VtxOffset
            local clip = cmd.ClipRect
            
            -- Text uses the font atlas (TexID 0)
            if tex_id ~= 0 or cmd.UserCallback ~= nil then
                goto continue
            end

            for j = 0, elem_count - 1, 6 do
                if count >= max_instances then goto done end
                
                local i0 = idx_buffer[idx_offset + j] + vtx_offset
                local i2 = idx_buffer[idx_offset + j + 2] + vtx_offset
                
                local v0 = ffi.cast("float*", vtx_buffer + i0 * 20)
                local v2 = ffi.cast("float*", vtx_buffer + i2 * 20)
                local c0 = ffi.cast("uint32_t*", vtx_buffer + i0 * 20 + 16)[0]
                
                -- Heuristic: If it's the white pixel UV (solid widget), skip it.
                local u, v = v0[2], v0[3]
                if math.abs(u - M.white_uv[1]) < 0.001 and math.abs(v - M.white_uv[2]) < 0.001 then
                    goto skip_quad
                end
                
                local qw = v2[0] - v0[0]
                local qh = v2[1] - v0[1]
                if qw > 100 or qh > 100 then
                    goto skip_quad
                end
                
                local inst = instances[count]
                inst.x, inst.y = v0[0], v0[1]
                inst.w, inst.h = qw, qh
                inst.u, inst.v = v0[2], v0[3]
                inst.uw, inst.vh = v2[2] - v0[2], v2[3] - v0[3]
                inst.clip_min_x, inst.clip_min_y = clip.x, clip.y
                inst.clip_max_x, inst.clip_max_y = clip.z, clip.w
                inst.color = c0
                
                count = count + 1
                ::skip_quad::
            end
            
            ::continue::
        end
    end
    
    ::done::
    return count
end

return M
