local ffi = require("ffi")
local M = {
    white_uv = {0, 0}
}

function M.harvest_text(draw_data, text_buffer)
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
            local cmd = cmd_buffer[i]
            local tex_id = tonumber(ffi.cast("uintptr_t", cmd.TexRef._TexID))
            
            local elem_count = cmd.ElemCount
            local idx_offset = cmd.IdxOffset
            local vtx_offset = cmd.VtxOffset
            
            -- Text uses the font atlas (TexID 0)
            if tex_id ~= 0 or cmd.UserCallback ~= nil then
                goto continue
            end

            for j = 0, elem_count - 1, 6 do
                if count >= max_instances then break end
                
                local i0 = idx_buffer[idx_offset + j] + vtx_offset
                local i2 = idx_buffer[idx_offset + j + 2] + vtx_offset
                
                local v0 = ffi.cast("float*", vtx_buffer + i0 * 20)
                local v2 = ffi.cast("float*", vtx_buffer + i2 * 20)
                local c0 = ffi.cast("uint32_t*", vtx_buffer + i0 * 20 + 16)[0]
                
                -- Heuristic: If it's the white pixel UV (solid widget), skip it.
                -- We use a slightly larger epsilon to catch common rounding errors in UVs.
                local u, v = v0[2], v0[3]
                if math.abs(u - M.white_uv[1]) < 0.001 and math.abs(v - M.white_uv[2]) < 0.001 then
                    goto skip_quad
                end
                
                -- Skip giant quads (windows/panels are usually > 100px in at least one dim)
                -- Text characters in this UI are rarely that large.
                local qw = v2[0] - v0[0]
                local qh = v2[1] - v0[1]
                                if qw > 100 or qh > 100 then
                                    goto skip_quad
                                end
                                
                                local inst = instances[count]
                                inst.x, inst.y = v0[0], v0[1]
                inst.w, inst.h = v2[0] - v0[0], v2[1] - v0[1]
                inst.u, inst.v = v0[2], v0[3]
                inst.uw, inst.vh = v2[2] - v0[2], v2[3] - v0[3]
                inst.color = c0
                
                count = count + 1
                ::skip_quad::
            end
            
            ::continue::
        end
    end
    
    return count
end

return M
