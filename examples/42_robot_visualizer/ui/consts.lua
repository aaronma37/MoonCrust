local ffi = require("ffi")

-- Pre-allocate every common UI primitive to ensure zero-allocation in the hot loop
local M = {
    V2_ZERO  = ffi.new("ImVec2_c", {0, 0}),
    V2_ONE   = ffi.new("ImVec2_c", {1, 1}),
    V2_FULL  = ffi.new("ImVec2_c", {-1, -1}),
    
    -- Buttons
    V2_BTN_TINY  = ffi.new("ImVec2_c", {40, 0}),
    V2_BTN_SMALL = ffi.new("ImVec2_c", {80, 0}),
    V2_BTN_MED   = ffi.new("ImVec2_c", {100, 0}),
    V2_BTN_LARGE = ffi.new("ImVec2_c", {120, 0}),
    V2_BTN_FILL  = ffi.new("ImVec2_c", {-1, 25}),
    
    -- Windows
    V2_HEADER    = ffi.new("ImVec2_c", {0, 50}),
    V2_TABLE_H   = ffi.new("ImVec2_c", {0, 250}),
    
    -- Colors
    V4_WHITE     = ffi.new("ImVec4_c", {1, 1, 1, 1}),
    V4_NOMINAL   = ffi.new("ImVec4_c", {0, 1, 0.2, 1}),
    V4_LIVE      = ffi.new("ImVec4_c", {0, 1, 0, 1}),
    V4_PAUSED    = ffi.new("ImVec4_c", {1, 0, 0, 1}),
    V4_ERROR     = ffi.new("ImVec4_c", {1, 0.2, 0.2, 1}),
    V4_VAL       = ffi.new("ImVec4_c", {0.2, 0.8, 1, 1}),
    V4_VOID      = ffi.new("ImVec4_c", {0.05, 0.05, 0.07, 0.85}),
    
    -- Pivots
    V2_PIVOT_CENTER = ffi.new("ImVec2_c", {0.5, 0.5}),
    V2_PIVOT_TOP    = ffi.new("ImVec2_c", {0.5, 0}),
}

return M
