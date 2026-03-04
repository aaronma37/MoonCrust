local ffi = require("ffi")
local json = require("mc.json")

local M = {}

local function call_gemini(prompt)
    local safe_prompt = prompt:gsub("'", "'''")
    local cmd = string.format("gemini -p '%s' 2>/dev/null", safe_prompt)
    local f = io.popen(cmd)
    if not f then return nil end
    local res = f:read("*a")
    f:close()
    return res
end

function M.process(input_msg, config, context)
    local goal = config.goal or "Optimize the current DAG."
    local target_dir = context.target_dir or "examples/44_bespoke_orchestrator"
    local gen_dir = target_dir .. "/nodes/generated/"
    
    local system_prompt = string.format([[
You are the ARCHITECT of a MoonCrust DAG.
GOAL: %s

CURRENT CONTEXT (Execution Log):
%s

INSTRUCTIONS:
1. Analyze the logic. If you identify a needed optimization, write a NEW Lua node.
2. The Lua node must have a 'process(input, config, context)' function.
3. Output a JSON block with "thought", "lua_code", and "mutation".

FORMAT:
{
  "thought": "Ex: Merging nodes to reduce latency.",
  "lua_code": "local M = {}; function M.process(i, c, ctx) ... end; return M",
  "mutation": {
    "op": "add_node",
    "type": "generated.node_gen_AUTOID",
    "name": "Evolved Node"
  }
}
]], goal, input_msg)

    print("[ARCHITECT] Reasoning...")
    local response = call_gemini(system_prompt)
    if not response then return "ERR: Gemini Offline" end
    
    local json_str = response:match("({.+})")
    if not json_str then return "ERR: No JSON in Architect response" end
    
    local ok, dec = pcall(json.decode, json_str)
    if ok and dec.lua_code and dec.mutation then
        -- GENERATE A SEMI-RANDOM ID FOR THE FILENAME
        local gen_id = math.random(1000, 9999)
        local filename = string.format("node_gen_%d.lua", gen_id)
        local full_path = gen_dir .. filename
        
        -- WRITE THE LUA FILE TO DISK
        local f = io.open(full_path, "w")
        if f then
            f:write(dec.lua_code)
            f:close()
            print("[ARCHITECT] Created new logic at: " .. full_path)
            
            -- Update mutation type to match the filename
            dec.mutation.type = "generated.node_gen_" .. gen_id
            return "ARCHITECT_DECISION: " .. json.encode(dec)
        end
    end
    
    return "ARCHITECT: No mutation required."
end

return M
