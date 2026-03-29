-- Unit Tests for Voxel Physics (AABB vs Voxel Grid)
local function check_aabb_voxel_collision(aabb, vx, vy, vz)
    -- Voxel at (vx, vy, vz) occupies [vx, vx+1], [vy, vy+1], [vz, vz+1]
    return aabb.min.x < vx + 1 and aabb.max.x > vx and
           aabb.min.y < vy + 1 and aabb.max.y > vy and
           aabb.min.z < vz + 1 and aabb.max.z > vz
end

local function is_grounded(aabb, get_voxel_func)
    -- Check voxels immediately below the AABB
    local margin = 0.05
    local check_y = math.floor(aabb.min.y - margin)
    
    -- Iterate over the horizontal footprint of the AABB
    local x_start, x_end = math.floor(aabb.min.x), math.floor(aabb.max.x)
    local z_start, z_end = math.floor(aabb.min.z), math.floor(aabb.max.z)
    
    for x = x_start, x_end do
        for z = z_start, z_end do
            if get_voxel_func(x, check_y, z) > 0 then
                return true
            end
        end
    end
    return false
end

local function test_aabb_collision()
    print("--- Running AABB Voxel Collision Tests ---")
    
    local robot_aabb = {
        min = {x = 10.2, y = 5.0, z = 10.2},
        max = {x = 10.8, y = 7.0, z = 10.8} -- 0.6 wide, 2.0 tall
    }
    
    -- Test 1: No collision
    assert(not check_aabb_voxel_collision(robot_aabb, 12, 5, 12), "False positive collision failed")
    
    -- Test 2: Direct collision
    assert(check_aabb_voxel_collision(robot_aabb, 10, 5, 10), "Direct collision failed")
    
    -- Test 3: Partial overlap (X boundary)
    local robot_edge = {
        min = {x = 10.9, y = 5.0, z = 10.2},
        max = {x = 11.1, y = 7.0, z = 10.8}
    }
    assert(check_aabb_voxel_collision(robot_edge, 10, 5, 10), "Edge overlap (min) failed")
    assert(check_aabb_voxel_collision(robot_edge, 11, 5, 10), "Edge overlap (max) failed")
    
    print("✅ AABB Collision Tests Passed!")
end

local function test_grounded_detection()
    print("--- Running Grounded Detection Tests ---")
    
    -- Mock world: floor at y=4
    local function mock_world(x, y, z)
        if y == 4 then return 1 end -- Solid floor
        return 0
    end
    
    -- Test 1: Robot in air
    local air_robot = {
        min = {x = 10, y = 5.1, z = 10},
        max = {x = 11, y = 7.1, z = 11}
    }
    assert(not is_grounded(air_robot, mock_world), "Airborne robot detected as grounded")
    
    -- Test 2: Robot on ground
    local grounded_robot = {
        min = {x = 10, y = 5.0, z = 10},
        max = {x = 11, y = 7.0, z = 11}
    }
    assert(is_grounded(grounded_robot, mock_world), "Grounded robot detected as airborne")
    
    -- Test 3: Robot partially off edge
    local edge_robot = {
        min = {x = 10.9, y = 5.0, z = 10.9},
        max = {x = 11.9, y = 7.0, z = 11.9}
    }
    -- footprint covers x=[10, 11], z=[10, 11] partially. 
    -- floor is everywhere at y=4, so it should be grounded.
    assert(is_grounded(edge_robot, mock_world), "Edge robot grounded detection failed")

    print("✅ Grounded Detection Tests Passed!")
end

local success, err = pcall(function()
    test_aabb_collision()
    test_grounded_detection()
end)

if not success then
    print("❌ TESTS FAILED: " .. tostring(err))
    os.exit(1)
else
    print("\nALL PHYSICS TESTS PASSED 🚀")
end
