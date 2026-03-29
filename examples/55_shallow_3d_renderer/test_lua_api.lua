-- Unit Tests for Robot Lua API (Sandboxing & Component Discovery)

-- 1. Mock Component Registry
local COMPONENT_DRIVERS = {
    hover_chip = function(api)
        api.hover = function() return "Hovering..." end
    end,
    drill_module = function(api)
        api.drill = function() return "Drilling..." end
    end
}

-- 2. Sandbox Factory
local function create_robot_sandbox(installed_components)
    local robot_api = {
        get_status = function() return "All systems green." end
    }
    
    -- Inject methods based on hardware
    for _, comp_id in ipairs(installed_components) do
        local driver = COMPONENT_DRIVERS[comp_id]
        if driver then driver(robot_api) end
    end
    
    -- The actual sandbox environment
    -- We explicitly do NOT include _G, io, os, or package
    local env = {
        robot = robot_api,
        print = print,
        math = math,
        tostring = tostring,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        _G = nil -- Explicitly shadow _G
    }
    
    return env
end

local function run_sandboxed_code(code, env)
    local f, err = loadstring(code, "robot_script")
    if not f then return nil, err end
    setfenv(f, env) -- Bound to the sandbox
    local ok, res = pcall(f)
    if not ok then return false, res end
    return true, res
end

local function test_component_discovery()
    print("--- Running Component Discovery Tests ---")
    local env1 = create_robot_sandbox({"drill_module"})
    assert(env1.robot.drill, "Drill method missing despite module installed")
    assert(not env1.robot.hover, "Hover method present despite NO module installed")
    print("✅ Component Discovery Tests Passed!")
end

local function test_sandbox_security()
    print("--- Running Sandbox Security Tests ---")
    local env = create_robot_sandbox({})
    
    -- Test 1: Access to 'io'
    local ok1, res1 = run_sandboxed_code("return io", env)
    assert(ok1 and res1 == nil, "Sandbox allowed access to 'io' variable!")
    
    -- Test 2: Access to 'os'
    local ok2, res2 = run_sandboxed_code("return os", env)
    assert(ok2 and res2 == nil, "Sandbox allowed access to 'os' variable!")

    -- Test 3: Standard robot access
    local ok3, res3 = run_sandboxed_code("return robot.get_status()", env)
    assert(ok3 and res3 == "All systems green.", "Standard API access failed in sandbox")
    
    print("✅ Sandbox Security Tests Passed!")
end

local success, err = pcall(function()
    test_component_discovery()
    test_sandbox_security()
end)

if not success then
    print("❌ TESTS FAILED: " .. tostring(err))
    os.exit(1)
else
    print("\nALL LUA API TESTS PASSED 🚀")
end
