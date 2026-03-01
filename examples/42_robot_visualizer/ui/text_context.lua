local ffi = require("ffi")
local imgui = require("imgui")

local M = {}
M.__index = M

function M.new(buffer_ptr, max_instances)
    local self = setmetatable({
        instances = ffi.cast("TextInstance*", buffer_ptr),
        count = 0,
        max_instances = max_instances or 20000,
        curr_clip = {0, 0, 10000, 10000}
    }, M)
    return self
end

function M:reset()
    self.count = 0
end

-- Manual Glyph Lookup (Bypasses missing ImFont_FindGlyph C function)
local function find_glyph(font, c)
    if not font then return nil end
    local lookup = ffi.cast("unsigned short*", font.IndexLookup.Data)
    local glyphs = ffi.cast("ImFontGlyph*", font.Glyphs.Data)
    
    if c < font.IndexLookup.Size then
        local idx = lookup[c]
        if idx ~= 65535 then
            return glyphs[idx]
        end
    end
    return font.FallbackGlyph
end

-- Bespoke Text Drawing (Bypasses ImGui Layout)
function M:draw_text(font, x, y, text, color, scale)
    if not font or not text or self.count >= self.max_instances then return end
    local font_ptr = ffi.cast("ImFont*", font)
    local s = scale or 1.0
    local color_packed = color or 0xFFFFFFFF
    
    local curr_x = x
    -- Baseline adjustment: ImGui Y is top-down, but glyphs have negative Y0 for ascending parts
    -- We add the font size to push it down into view
    local curr_y = y + (font_ptr.FontSize * s * 0.8)

    for i = 1, #text do
        if self.count >= self.max_instances then break end
        
        local char_code = text:byte(i)
        local glyph = find_glyph(font_ptr, char_code)
        
        if glyph ~= nil then
            if glyph.Visible ~= 0 then
                local inst = self.instances[self.count]
                inst.x = curr_x + glyph.X0 * s
                inst.y = curr_y + glyph.Y0 * s -- Baseline relative
                inst.w = (glyph.X1 - glyph.X0) * s
                inst.h = (glyph.Y1 - glyph.Y0) * s
                
                inst.u = glyph.U0
                inst.v = glyph.V0
                inst.uw = glyph.U1 - glyph.U0
                inst.vh = glyph.V1 - glyph.V0
                
                inst.clip_min_x, inst.clip_min_y = self.curr_clip[1], self.curr_clip[2]
                inst.clip_max_x, inst.clip_max_y = self.curr_clip[3], self.curr_clip[4]
                inst.color = color_packed
                
                self.count = self.count + 1
            end
            curr_x = curr_x + glyph.AdvanceX * s
        end
    end
end

return M
