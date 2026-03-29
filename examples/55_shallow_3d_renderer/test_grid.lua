-- Unit Tests for 16x16x16 Voxel Chunk Indexing
local grid_w, grid_h, grid_d = 512, 128, 512
local chunk_size = 16

local function get_chunk_coords(wx, wy, wz)
    return math.floor(wx / chunk_size), math.floor(wy / chunk_size), math.floor(wz / chunk_size)
end

local function get_chunk_index(cx, cy, cz)
    local chunks_per_row = grid_w / chunk_size
    local chunks_per_slice = (grid_w / chunk_size) * (grid_h / chunk_size)
    return cx + cy * chunks_per_row + cz * chunks_per_slice
end

local function get_local_index(lx, ly, lz)
    -- Standard X + Y*W + Z*W*H for consistency with the shaders
    return lx + ly * chunk_size + lz * chunk_size * chunk_size
end

local function test_indexing()
    print("--- Running Voxel Grid Indexing Tests ---")
    
    -- Test 1: Origin
    local cx, cy, cz = get_chunk_coords(0, 0, 0)
    assert(cx == 0 and cy == 0 and cz == 0, "Origin chunk coords failed")
    assert(get_chunk_index(cx, cy, cz) == 0, "Origin chunk index failed")
    
    -- Test 2: Boundary (15, 15, 15) -> still chunk 0
    local cx2, cy2, cz2 = get_chunk_coords(15, 15, 15)
    assert(cx2 == 0 and cy2 == 0 and cz2 == 0, "Max local boundary chunk coords failed")
    
    -- Test 3: Next Chunk (16, 0, 0) -> chunk 1
    local cx3, cy3, cz3 = get_chunk_coords(16, 0, 0)
    assert(cx3 == 1 and cy3 == 0 and cz3 == 0, "Next X chunk coords failed")
    assert(get_chunk_index(cx3, cy3, cz3) == 1, "Next X chunk index failed")
    
    -- Test 4: Vertical Chunk (0, 16, 0)
    local chunks_per_row = grid_w / chunk_size -- 32
    local cx4, cy4, cz4 = get_chunk_coords(0, 16, 0)
    assert(cx4 == 0 and cy4 == 1 and cz4 == 0, "Vertical chunk coords failed")
    assert(get_chunk_index(cx4, cy4, cz4) == chunks_per_row, "Vertical chunk index failed")

    -- Test 5: Deep Chunk (0, 0, 16)
    local chunks_per_slice = (grid_w / chunk_size) * (grid_h / chunk_size) -- 32 * 8 = 256
    local cx5, cy5, cz5 = get_chunk_coords(0, 0, 16)
    assert(cx5 == 0 and cy5 == 0 and cz5 == 1, "Deep chunk coords failed")
    assert(get_chunk_index(cx5, cy5, cz5) == chunks_per_slice, "Deep chunk index failed")

    -- Test 6: Local indexing within a 16^3 chunk
    assert(get_local_index(0, 0, 0) == 0, "Local origin failed")
    assert(get_local_index(1, 0, 0) == 1, "Local X+1 failed")
    assert(get_local_index(0, 1, 0) == 16, "Local Y+1 failed")
    assert(get_local_index(0, 0, 1) == 256, "Local Z+1 failed")
    assert(get_local_index(15, 15, 15) == 4095, "Local max (16^3 - 1) failed")

    print("✅ Indexing Tests Passed!")
end

local function test_neighbor_logic()
    print("--- Running Neighbor Logic Tests ---")
    
    -- Test: Neighbors within the same chunk
    local wx, wy, wz = 5, 5, 5
    local cx, cy, cz = get_chunk_coords(wx, wy, wz)
    
    local neighbors = {
        {wx+1, wy, wz}, {wx-1, wy, wz},
        {wx, wy+1, wz}, {wx, wy-1, wz},
        {wx, wy, wz+1}, {wx, wy, wz-1}
    }
    
    for _, n in ipairs(neighbors) do
        local ncx, ncy, ncz = get_chunk_coords(n[1], n[2], n[3])
        assert(ncx == cx and ncy == cy and ncz == cz, "Internal neighbor crossed chunk boundary")
    end
    
    -- Test: Neighbors crossing boundaries
    local wx2, wy2, wz2 = 15, 5, 5
    local ncx, ncy, ncz = get_chunk_coords(wx2 + 1, wy2, wz2)
    assert(ncx == 1, "X+1 neighbor failed to cross boundary")
    
    local wx3, wy3, wz3 = 0, 5, 5
    local ncx2, ncy2, ncz2 = get_chunk_coords(wx3 - 1, wy3, wz3)
    assert(ncx2 == -1, "X-1 neighbor failed to detect negative boundary")
    
    print("✅ Neighbor Logic Tests Passed!")
end

local success, err = pcall(function()
    test_indexing()
    test_neighbor_logic()
end)

if not success then
    print("❌ TESTS FAILED: " .. tostring(err))
    os.exit(1)
else
    print("\nALL GRID TESTS PASSED 🚀")
end
