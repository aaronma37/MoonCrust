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
local FL_INDEX_SHIFT = 8 -- Minimum block size 256 bytes
local FL_INDEX_COUNT = FL_INDEX_MAX - FL_INDEX_SHIFT + 1

local BLOCK_FREE_BIT = 0x1
local BLOCK_PREV_FREE_BIT = 0x2
local BLOCK_SIZE_MASK = bit.bnot(bit.bor(BLOCK_FREE_BIT, BLOCK_PREV_FREE_BIT))

ffi.cdef[[
    typedef struct BlockHeader {
        uint32_t prev_phys_block; // offset of previous physical block
        uint32_t size;            // size and status bits
        uint32_t next_free;       // offset of next free block in list
        uint32_t prev_free;       // offset of prev free block in list
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
    -- Matrix of free list heads (offsets)
    self.blocks = ffi.new("uint32_t[?]", FL_INDEX_COUNT * SL_INDEX_COUNT)
    
    -- Initialize free lists to 0 (null)
    for i = 0, FL_INDEX_COUNT * SL_INDEX_COUNT - 1 do
        self.blocks[i] = 0
    end
    
    return self
end

local function mapping_insert(size)
    local fl = 0
    local sl = 0
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
    if size < bit.lshift(1, FL_INDEX_SHIFT) then
        return 0, bit.rshift(size, FL_INDEX_SHIFT - SL_INDEX_COUNT_LOG2)
    end
    
    local fl = 31 - clz(size)
    local sl = bit.band(bit.rshift(size, fl - SL_INDEX_COUNT_LOG2), SL_INDEX_COUNT - 1)
    
    -- Round up to next bucket to guarantee fit
    if sl < SL_INDEX_COUNT - 1 then
        sl = sl + 1
    else
        sl = 0
        fl = fl + 1
    end
    
    return fl - FL_INDEX_SHIFT + 1, sl
end

function TLSF:add_pool(ptr, size)
    -- In a real implementation, we'd initialize the first block here
    -- and link it into the free lists. For MoonCrust, we'll assume the 
    -- user provides a large pre-allocated FFI buffer or VRAM offset.
    self.pool_ptr = ptr
    
    -- Initial big block at offset 0
    local initial_block = ffi.cast("BlockHeader*", self.pool_ptr)
    initial_block.size = bit.bor(size, BLOCK_FREE_BIT)
    initial_block.prev_phys_block = 0
    
    self:insert_block(0)
end

function TLSF:insert_block(offset)
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local fl, sl = mapping_insert(bit.band(block.size, BLOCK_SIZE_MASK))
    
    local head = self.blocks[fl * SL_INDEX_COUNT + sl]
    block.next_free = head
    block.prev_free = 0
    
    if head ~= 0 then
        local next_block = ffi.cast("BlockHeader*", self.pool_ptr + head)
        next_block.prev_free = offset
    end
    
    self.blocks[fl * SL_INDEX_COUNT + sl] = offset
    self.fl_bitmap = bit.bor(self.fl_bitmap, bit.lshift(1, fl))
    self.sl_bitmaps[fl] = bit.bor(self.sl_bitmaps[fl], bit.lshift(1, sl))
end

function TLSF:remove_block(offset)
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local fl, sl = mapping_insert(bit.band(block.size, BLOCK_SIZE_MASK))
    
    local prev = block.prev_free
    local next = block.next_free
    
    if next ~= 0 then
        local next_block = ffi.cast("BlockHeader*", self.pool_ptr + next)
        next_block.prev_free = prev
    end
    if prev ~= 0 then
        local prev_block = ffi.cast("BlockHeader*", self.pool_ptr + prev)
        prev_block.next_free = next
    else
        self.blocks[fl * SL_INDEX_COUNT + sl] = next
        if next == 0 then
            self.sl_bitmaps[fl] = bit.band(self.sl_bitmaps[fl], bit.bnot(bit.lshift(1, sl)))
            if self.sl_bitmaps[fl] == 0 then
                self.fl_bitmap = bit.band(self.fl_bitmap, bit.bnot(bit.lshift(1, fl)))
            end
        end
    end
end

function TLSF:malloc(size)
    -- Align size to 8 bytes minimum
    size = bit.band(size + 7, bit.bnot(7))
    
    local fl, sl = mapping_search(size)
    
    -- Search bitmaps for a suitable bucket
    local sl_map = bit.band(self.sl_bitmaps[fl], bit.bnot(bit.lshift(1, sl) - 1))
    if sl_map == 0 then
        local fl_map = bit.band(self.fl_bitmap, bit.bnot(bit.lshift(1, fl + 1) - 1))
        if fl_map == 0 then return nil end -- Out of memory
        
        fl = ctz(fl_map)
        sl_map = self.sl_bitmaps[fl]
    end
    sl = ctz(sl_map)
    
    local offset = self.blocks[fl * SL_INDEX_COUNT + sl]
    self:remove_block(offset)
    
    -- Split block if too large
    local block = ffi.cast("BlockHeader*", self.pool_ptr + offset)
    local bsize = bit.band(block.size, BLOCK_SIZE_MASK)
    if bsize >= size + ffi.sizeof("BlockHeader") + 8 then
        local remaining = bsize - size - ffi.sizeof("BlockHeader")
        local split_offset = offset + size + ffi.sizeof("BlockHeader")
        local split = ffi.cast("BlockHeader*", self.pool_ptr + split_offset)
        
        split.size = bit.bor(remaining, BLOCK_FREE_BIT)
        split.prev_phys_block = offset
        block.size = size -- no longer free
        
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
    
    -- Merge with next physical block
    local next_offset = offset + bit.band(block.size, BLOCK_SIZE_MASK) + ffi.sizeof("BlockHeader")
    if next_offset < self.size then
        local next_block = ffi.cast("BlockHeader*", self.pool_ptr + next_offset)
        if bit.band(next_block.size, BLOCK_FREE_BIT) ~= 0 then
            self:remove_block(next_offset)
            block.size = block.size + bit.band(next_block.size, BLOCK_SIZE_MASK) + ffi.sizeof("BlockHeader")
        end
    end
    
    -- Merge with prev physical block
    if bit.band(block.size, BLOCK_PREV_FREE_BIT) ~= 0 or block.prev_phys_block ~= offset then
        local prev_offset = block.prev_phys_block
        local prev_block = ffi.cast("BlockHeader*", self.pool_ptr + prev_offset)
        if bit.band(prev_block.size, BLOCK_FREE_BIT) ~= 0 then
            self:remove_block(prev_offset)
            prev_block.size = prev_block.size + bit.band(block.size, BLOCK_SIZE_MASK) + ffi.sizeof("BlockHeader")
            offset = prev_offset
            block = prev_block
        end
    end
    
    self:insert_block(offset)
end

return M
