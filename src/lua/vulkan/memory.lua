local ffi = require("ffi")
local bit = require("bit")

-- Local bit utility polyfills
local function clz(x)
    if x == 0 then return 32 end
    local n = 0
    if bit.band(x, 0xFFFF0000) == 0 then n = n + 16; x = bit.lshift(x, 16) end
    if bit.band(x, 0xFF000000) == 0 then n = n + 8; x = bit.lshift(x, 8) end
    if bit.band(x, 0xF0000000) == 0 then n = n + 4; x = bit.lshift(x, 4) end
    if bit.band(x, 0xC0000000) == 0 then n = n + 2; x = bit.lshift(x, 2) end
    if bit.band(x, 0x80000000) == 0 then n = n + 1 end
    return n
end

local function ctz(x)
    if x == 0 then return 32 end
    local n = 0
    if bit.band(x, 0x0000FFFF) == 0 then n = n + 16; x = bit.rshift(x, 16) end
    if bit.band(x, 0x000000FF) == 0 then n = n + 8; x = bit.rshift(x, 8) end
    if bit.band(x, 0x0000000F) == 0 then n = n + 4; x = bit.rshift(x, 4) end
    if bit.band(x, 0x00000003) == 0 then n = n + 2; x = bit.rshift(x, 2) end
    if bit.band(x, 0x00000001) == 0 then n = n + 1 end
    return n
end

-- TLSF Constants
local SL_INDEX_COUNT_LOG2 = 5
local SL_INDEX_COUNT = bit.lshift(1, SL_INDEX_COUNT_LOG2)
local FL_INDEX_MAX = 32
local FL_INDEX_SHIFT = 8 
local FL_INDEX_COUNT = FL_INDEX_MAX - FL_INDEX_SHIFT + 1

local BLOCK_FREE_BIT = 0x1
local BLOCK_PREV_FREE_BIT = 0x2
local BLOCK_SIZE_MASK = bit.bnot(bit.bor(BLOCK_FREE_BIT, BLOCK_PREV_FREE_BIT))

ffi.cdef[[
    typedef struct BlockHeader {
        uint32_t prev_phys_block; 
        uint32_t size;            
        uint32_t next_free;       
        uint32_t prev_free;       
        uint8_t _padding[240];    /* Pad header to 256 bytes for Vulkan alignment */
    } BlockHeader;
]]

local M = {}
local TLSF = {}
TLSF.__index = TLSF

function M.new(size)
    local self = setmetatable({}, TLSF)
    self.size = size
    self.fl_bitmap = 0
    self.sl_bitmaps = ffi.new("uint32_t[?]", FL_INDEX_COUNT)
    self.blocks = ffi.new("uint32_t[?]", FL_INDEX_COUNT * SL_INDEX_COUNT)
    for i = 0, FL_INDEX_COUNT * SL_INDEX_COUNT - 1 do self.blocks[i] = 0 end
    return self
end

local function mapping_insert(size)
    local fl, sl
    if size < bit.lshift(1, FL_INDEX_SHIFT) then
        fl = 0
        sl = bit.rshift(size, FL_INDEX_SHIFT - SL_INDEX_COUNT_LOG2)
    else
        fl = 31 - clz(size)
        sl = bit.band(bit.rshift(size, fl - SL_INDEX_COUNT_LOG2), SL_INDEX_COUNT - 1)
        fl = fl - FL_INDEX_SHIFT + 1
    end
    return fl, sl
end

local function mapping_search(size)
    if size < bit.lshift(1, FL_INDEX_SHIFT) then return 0, bit.rshift(size, FL_INDEX_SHIFT - SL_INDEX_COUNT_LOG2) end
    local fl = 31 - clz(size)
    local sl = bit.band(bit.rshift(size, fl - SL_INDEX_COUNT_LOG2), SL_INDEX_COUNT - 1)
    if sl < SL_INDEX_COUNT - 1 then sl = sl + 1 else sl = 0; fl = fl + 1 end
    return fl - FL_INDEX_SHIFT + 1, sl
end

function TLSF:add_pool(ptr, size)
    self.pool_ptr = ffi.cast("uint8_t*", ptr)
    local initial_block = ffi.cast("BlockHeader*", self.pool_ptr)
    initial_block.size = bit.bor(size - ffi.sizeof("BlockHeader"), BLOCK_FREE_BIT)
    initial_block.prev_phys_block = 0
    self:insert_block(0)
end

function TLSF:insert_block(offset)
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local fl, sl = mapping_insert(bit.band(block.size, BLOCK_SIZE_MASK))
    local head = self.blocks[fl * SL_INDEX_COUNT + sl]
    block.next_free = head; block.prev_free = 0
    if head ~= 0 then ffi.cast("BlockHeader*", self.pool_ptr + head).prev_free = offset end
    self.blocks[fl * SL_INDEX_COUNT + sl] = offset
    self.fl_bitmap = bit.bor(self.fl_bitmap, bit.lshift(1, fl))
    self.sl_bitmaps[fl] = bit.bor(self.sl_bitmaps[fl], bit.lshift(1, sl))
end

function TLSF:remove_block(offset)
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local fl, sl = mapping_insert(bit.band(block.size, BLOCK_SIZE_MASK))
    local prev, next = block.prev_free, block.next_free
    if next ~= 0 then ffi.cast("BlockHeader*", self.pool_ptr + next).prev_free = prev end
    if prev ~= 0 then ffi.cast("BlockHeader*", self.pool_ptr + prev).next_free = next
    else
        self.blocks[fl * SL_INDEX_COUNT + sl] = next
        if next == 0 then
            self.sl_bitmaps[fl] = bit.band(self.sl_bitmaps[fl], bit.bnot(bit.lshift(1, sl)))
            if self.sl_bitmaps[fl] == 0 then self.fl_bitmap = bit.band(self.fl_bitmap, bit.bnot(bit.lshift(1, fl))) end
        end
    end
end

function TLSF:malloc(size)
    size = bit.band(size + 255, bit.bnot(255)) -- Align to 256
    local fl, sl = mapping_search(size)
    local sl_map = bit.band(self.sl_bitmaps[fl], bit.bnot(bit.lshift(1, sl) - 1))
    if sl_map == 0 then
        local fl_map = bit.band(self.fl_bitmap, bit.bnot(bit.lshift(1, fl + 1) - 1))
        if fl_map == 0 then return nil end 
        fl = ctz(fl_map); sl_map = self.sl_bitmaps[fl]
    end
    sl = ctz(sl_map)
    local offset = self.blocks[fl * SL_INDEX_COUNT + sl]
    self:remove_block(offset)
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local bsize = bit.band(block.size, BLOCK_SIZE_MASK)
    local min_split = size + ffi.sizeof("BlockHeader") + 256
    if bsize >= min_split then
        local split_offset = offset + size + ffi.sizeof("BlockHeader")
        local split = ffi.cast("BlockHeader*", self.pool_ptr + split_offset)
        split.size = bit.bor(bsize - size - ffi.sizeof("BlockHeader"), BLOCK_FREE_BIT)
        split.prev_phys_block = offset
        block.size = size
        self:insert_block(split_offset)
    else
        block.size = bit.band(block.size, bit.bnot(BLOCK_FREE_BIT))
    end
    return offset + ffi.sizeof("BlockHeader")
end

function TLSF:free(ptr_offset)
    if not ptr_offset then return end
    local offset = ptr_offset - ffi.sizeof("BlockHeader")
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    block.size = bit.bor(block.size, BLOCK_FREE_BIT)
    self:insert_block(offset)
end

return M
