local ffi = require("ffi")

-- FontAwesome 6 Solid Icons
-- Mapping common icons to their UTF-8/UTF-16 codes
local M = {
    -- Navigation / Robot
    ROBOT     = "\xef\x95\x89", -- f549
    LOCATION  = "\xef\x8b\x85", -- f2c5
    CHART     = "\xef\x88\x81", -- f201
    LIST      = "\xef\x80\xbb", -- f03b
    EYE       = "\xef\x81\xae", -- f06e
    EYE_SLASH = "\xef\x81\xb0", -- f070
    
    -- Status
    HEARTBEAT = "\xef\x88\x9e", -- f21e
    SIGNAL    = "\xef\x80\x92", -- f012
    BATTERY   = "\xef\x89\x80", -- f240
    CHECK     = "\xef\x80\x8c", -- f00c
    XMARK     = "\xef\x95\xb3", -- f573
    
    -- Playback
    PLAY      = "\xef\x80\x8b", -- f04b
    PAUSE     = "\xef\x80\x8c", -- f04c
    STOP      = "\xef\x80\x8d", -- f04d
    FORWARD   = "\xef\x80\x8e", -- f04e
    BACKWARD  = "\xef\x80\x8a", -- f04a
    
    -- Generic
    GEAR      = "\xef\x80\x93", -- f013
    FOLDER    = "\xef\x81\xbb", -- f07b
    SEARCH    = "\xef\x80\x82", -- f002
    TRASH     = "\xef\x86\xb8", -- f1b8
    
    -- Ranges
    GLYPH_MIN = 0xE000,
    GLYPH_MAX = 0xF8FF
}

return M
