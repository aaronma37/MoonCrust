local ffi = require("ffi")
local sdl = require("vulkan.sdl")
local bit = require("bit")

local M = {}

-- Cached pointers for optimization
local mx_ptr = ffi.new("float[1]")
local my_ptr = ffi.new("float[1]")
local rmx_ptr = ffi.new("float[1]")
local rmy_ptr = ffi.new("float[1]")
local num_keys_ptr = ffi.new("int[1]")

-- Internal state for "pressed" (one-frame) checks
local prev_keyboard = nil
local curr_keyboard = nil
local num_keys = 0

local prev_mouse = 0
local curr_mouse = 0
local curr_window = 0

local prev_mx, prev_my = 0, 0

function M.tick()
    -- Update Mouse Position
    prev_mx, prev_my = mx_ptr[0], my_ptr[0]
    
    -- Hallmark #6: Use logical window size to normalize mouse if needed, 
    -- but here we just align with what C++ gives us.
    mx_ptr[0] = _G._MOUSE_X or 0
    my_ptr[0] = _G._MOUSE_Y or 0
    
    -- Manual delta calculation
    rmx_ptr[0] = mx_ptr[0] - prev_mx
    rmy_ptr[0] = my_ptr[0] - prev_my
    
    -- Update Mouse Buttons from Globals (Event-driven)
    prev_mouse = curr_mouse
    local buttons = 0
    if _G._MOUSE_L == true then buttons = bit.bor(buttons, 1) end
    if _G._MOUSE_M == true then buttons = bit.bor(buttons, 2) end
    if _G._MOUSE_R == true then buttons = bit.bor(buttons, 4) end
    curr_mouse = buttons
    
    -- Update Keyboard
    local keys_ptr = sdl.SDL_GetKeyboardState(num_keys_ptr)
    num_keys = num_keys_ptr[0]
    
    if not curr_keyboard then
        curr_keyboard = ffi.new("uint8_t[?]", num_keys)
        prev_keyboard = ffi.new("uint8_t[?]", num_keys)
    end
    
    ffi.copy(prev_keyboard, curr_keyboard, num_keys)
    ffi.copy(curr_keyboard, keys_ptr, num_keys)
end

-- Mouse API
function M.mouse_pos() return mx_ptr[0], my_ptr[0] end
function M.mouse_delta() return rmx_ptr[0], rmy_ptr[0] end
function M.mouse_window() return curr_window end

function M.mouse_down(button)
    -- button: 1=Left, 2=Middle, 3=Right (Standard Lua 1-based)
    -- But ImGui uses 0-based.
    local mask = bit.lshift(1, button - 1)
    return bit.band(curr_mouse, mask) ~= 0
end

function M.mouse_down_raw(mask)
    return bit.band(curr_mouse, mask) ~= 0
end

function M.mouse_pressed(button)
    local mask = bit.lshift(1, button - 1)
    return bit.band(curr_mouse, mask) ~= 0 and bit.band(prev_mouse, mask) == 0
end

function M.mouse_released(button)
    local mask = bit.lshift(1, button - 1)
    return bit.band(curr_mouse, mask) == 0 and bit.band(prev_mouse, mask) ~= 0
end

-- Keyboard API
function M.key_down(scancode)
    if not curr_keyboard or scancode < 0 or scancode >= num_keys then return false end
    return curr_keyboard[scancode] ~= 0
end

function M.key_pressed(scancode)
    if not curr_keyboard or scancode < 0 or scancode >= num_keys then return false end
    return curr_keyboard[scancode] ~= 0 and prev_keyboard[scancode] == 0
end

function M.key_released(scancode)
    if not curr_keyboard or scancode < 0 or scancode >= num_keys then return false end
    return curr_keyboard[scancode] == 0 and prev_keyboard[scancode] ~= 0
end

-- Common Scancodes (MoonCrust Subset)
M.SCANCODE_W = 26
M.SCANCODE_A = 4
M.SCANCODE_S = 22
M.SCANCODE_D = 7
M.SCANCODE_SPACE = 44
M.SCANCODE_LSHIFT = 225
M.SCANCODE_LCTRL = 224
M.SCANCODE_ESCAPE = 41

M.sdl = sdl

-- Number Keys
M.SCANCODE_1 = 30
M.SCANCODE_2 = 31
M.SCANCODE_3 = 32
M.SCANCODE_4 = 33
M.SCANCODE_5 = 34
M.SCANCODE_6 = 35
M.SCANCODE_7 = 36
M.SCANCODE_8 = 37
M.SCANCODE_9 = 38
M.SCANCODE_0 = 39
M.SCANCODE_Z = 29

return M
