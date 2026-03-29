-- Unit Tests for Automation Logic (60Hz Ticks & Resource Flow)
local function create_sim_clock(tick_rate)
    local clock = {
        tick_rate = tick_rate,
        tick_duration = 1.0 / tick_rate,
        accumulated_time = 0,
        total_ticks = 0
    }
    
    function clock:update(dt)
        self.accumulated_time = self.accumulated_time + dt
        local ticks_to_run = math.floor(self.accumulated_time / self.tick_duration)
        self.accumulated_time = self.accumulated_time - (ticks_to_run * self.tick_duration)
        self.total_ticks = self.total_ticks + ticks_to_run
        return ticks_to_run
    end
    
    return clock
end

local function test_sim_clock()
    print("--- Running 60Hz Tick Stability Tests ---")
    local clock = create_sim_clock(60)
    
    -- Test 1: Exactly one tick duration
    local ticks = clock:update(1/60)
    assert(ticks == 1, "Exactly 1/60s should produce 1 tick, got " .. ticks)
    
    -- Test 2: Half a tick (should accumulate)
    ticks = clock:update(1/120)
    assert(ticks == 0, "1/120s should produce 0 ticks")
    ticks = clock:update(1/120)
    assert(ticks == 1, "Cumulative 1/60s should produce 1 tick")
    
    -- Test 3: Large delta (catch up)
    ticks = clock:update(0.1) -- 6 ticks at 60Hz is 0.1s
    assert(ticks == 6, "0.1s should produce 6 ticks, got " .. ticks)
    
    print("✅ 60Hz Tick Stability Tests Passed!")
end

local function test_resource_transfer()
    print("--- Running Resource Transfer Tests ---")
    
    -- Mock Voxel Grid for Items
    -- 0: Empty, 1: Item, 2: Conveyor (East +X)
    local world = {
        {type = 2, item = 1}, -- (0,0,0) Conveyor with item
        {type = 2, item = 0}, -- (1,0,0) Empty conveyor
        {type = 2, item = 0}  -- (2,0,0) Empty conveyor
    }
    
    local function tick_conveyors(grid)
        local new_items = {}
        for i, cell in ipairs(grid) do
            if cell.type == 2 and cell.item == 1 then
                -- Try to move East
                if grid[i+1] and grid[i+1].item == 0 then
                    new_items[i+1] = 1
                    cell.item = 0
                else
                    new_items[i] = 1 -- Stuck
                end
            end
        end
        for i, val in pairs(new_items) do grid[i].item = val end
    end
    
    -- Tick 1: Item moves to (1,0,0)
    tick_conveyors(world)
    assert(world[1].item == 0 and world[2].item == 1, "Item failed to move to second cell")
    
    -- Tick 2: Item moves to (2,0,0)
    tick_conveyors(world)
    assert(world[2].item == 0 and world[3].item == 1, "Item failed to move to third cell")
    
    -- Tick 3: Item gets stuck at end
    tick_conveyors(world)
    assert(world[3].item == 1, "Item disappeared at boundary")
    
    print("✅ Resource Transfer Tests Passed!")
end

local success, err = pcall(function()
    test_sim_clock()
    test_resource_transfer()
end)

if not success then
    print("❌ TESTS FAILED: " .. tostring(err))
    os.exit(1)
else
    print("\nALL AUTOMATION TESTS PASSED 🚀")
end
