local ffi = require("ffi")
local bit = require("bit")
local M = {
    elements = nil,
    count = 0,
    max_elements = 10000,
    curr_clip = {0, 0, 10000, 10000}
}

function M.init(buffer_ptr, max_elements)
    M.elements = ffi.cast("UIElement*", buffer_ptr)
    M.max_elements = max_elements or 10000
    M.reset()
end

function M.reset()
    M.count = 0
end

function M.push(e)
    if M.count >= M.max_elements then return end
    local dest = M.elements[M.count]
    dest.x, dest.y = e.x, e.y
    dest.w, dest.h = e.w, e.h
    dest.r, dest.g, dest.b, dest.a = e.r or 1, e.g or 1, e.b or 1, e.a or 1
    dest.clip_min_x, dest.clip_min_y = e.clip_min_x or M.curr_clip[1], e.clip_min_y or M.curr_clip[2]
    dest.clip_max_x, dest.clip_max_y = e.clip_max_x or M.curr_clip[3], e.clip_max_y or M.curr_clip[4]
    dest.type = e.type or 0
    dest.flags = e.flags or 0
    dest.rounding = e.rounding or 0
    dest.extra = e.extra or 0
    M.count = M.count + 1
end

-- Wrapper for common ImGui widgets to capture metadata
function M.wrap(gui)
    local old_igButton = gui.igButton
    gui.igButton = function(label, size)
        local pos = gui.igGetCursorScreenPos()
        local avail = gui.igGetContentRegionAvail()
        local w, h = size.x, size.y
        if w <= 0 then w = avail.x end
        if h <= 0 then h = 24 end 
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        local res = old_igButton(label, size)
        
        M.push({
            x = pos.x, y = pos.y, w = w, h = h,
            r = 0.2, g = 0.25, b = 0.35, a = 1.0, 
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 1, -- Button
            rounding = 4.0,
            flags = (gui.igIsItemHovered(0) and 1 or 0) + (gui.igIsItemActive() and 2 or 0)
        })
        return res
    end

    local old_igBegin = gui.igBegin
    gui.igBegin = function(name, p_open, flags)
        local res = old_igBegin(name, p_open, flags)
        local pos = gui.igGetWindowPos()
        local size = gui.igGetWindowSize()
        M.push({
            x = pos.x, y = pos.y, w = size.x, h = size.y,
            r = 0.05, g = 0.05, b = 0.07, a = 0.95,
            type = 0, -- Window Frame
            rounding = 10.0
        })
        return res
    end

    gui.igSelectable_Bool = function(label, selected, flags, size)
        local pos = gui.igGetCursorScreenPos()
        local avail = gui.igGetContentRegionAvail()
        local w, h = size.x, size.y
        if w <= 0 then w = avail.x end
        if h <= 0 then h = 20 end
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        local res = gui._S.ffi_lib.igSelectable_Bool(label, selected, flags, size)
        
        local r, g, b = 0.1, 0.1, 0.1
        if selected then r, g, b = 0.2, 0.3, 0.5 end

        M.push({
            x = pos.x, y = pos.y, w = w, h = h,
            r = r, g = g, b = b, a = 1.0,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 6, -- Selectable
            rounding = 2.0,
            flags = (gui.igIsItemHovered(0) and 1 or 0)
        })
        return res
    end

    local old_igSliderFloat = gui.igSliderFloat
    gui.igSliderFloat = function(label, v, v_min, v_max, format, flags)
        local pos = gui.igGetCursorScreenPos()
        local avail = gui.igGetContentRegionAvail()
        local w = (avail.x > 0) and avail.x or 100
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        local res = old_igSliderFloat(label, v, v_min, v_max, format, flags)
        
        M.push({
            x = pos.x, y = pos.y, w = w, h = 20,
            r = 0.15, g = 0.15, b = 0.2, a = 1.0,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 3, -- Slider
            rounding = 2.0,
            extra = ffi.cast("uint32_t", (v[0] - v_min) / (v_max - v_min) * 1000.0) -- Packed progress
        })
        return res
    end

    local old_igInputText = gui.igInputText
    gui.igInputText = function(label, buf, buf_size, flags, callback, user_data)
        local pos = gui.igGetCursorScreenPos()
        local avail = gui.igGetContentRegionAvail()
        local w = (avail.x > 0) and avail.x or 100
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        local res = old_igInputText(label, buf, buf_size, flags, callback, user_data)
        
        M.push({
            x = pos.x, y = pos.y, w = w, h = 24,
            r = 0.1, g = 0.12, b = 0.15, a = 1.0,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 5, -- InputText
            rounding = 4.0,
            flags = (gui.igIsItemActive() and 2 or 0)
        })
        return res
    end

    local old_igSeparator = gui.igSeparator
    gui.igSeparator = function()
        local pos = gui.igGetCursorScreenPos()
        local avail = gui.igGetContentRegionAvail()
        local w = (avail.x > 0) and avail.x or 100
        
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        old_igSeparator()
        M.push({
            x = pos.x, y = pos.y, w = w, h = 1,
            r = 0.3, g = 0.3, b = 0.4, a = 0.5,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 4 -- Separator
        })
    end

    local old_ImPlot_PlotImage = gui.ImPlot_PlotImage
    gui.ImPlot_PlotImage = function(label_id, tex_ref, bounds_min, bounds_max, uv0, uv1, tint_col, spec)
        local pos = gui.ImPlot_GetPlotPos()
        local size = gui.ImPlot_GetPlotSize()
        local w_pos = gui.igGetWindowPos()
        local w_size = gui.igGetWindowSize()
        
        local tex_id = tonumber(ffi.cast("uintptr_t", tex_ref._TexID))
        
        M.push({
            x = pos.x, y = pos.y, w = size.x, h = size.y,
            r = 1, g = 1, b = 1, a = 1,
            clip_min_x = w_pos.x, clip_min_y = w_pos.y,
            clip_max_x = w_pos.x + w_size.x, clip_max_y = w_pos.y + w_size.y,
            type = 2, -- Aperture
            extra = tex_id
        })
        -- We don't need to call old_ImPlot_PlotImage because we are headless!
    end
end

return M
