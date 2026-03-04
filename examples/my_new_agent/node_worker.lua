local ffi = require("ffi")
local json = require("mc.json")
local socket = require("mc.socket")

local node_id = tonumber(arg[1])
local node_type = arg[2]
local config_raw = arg[3]
local target_dir = arg[4] or "examples/44_bespoke_orchestrator"
local config = json.decode(config_raw)

local UDP_IP = "127.0.0.1"
local ROUTER_PORT = 5557
local MY_PORT = 6000 + node_id

local my_sock = socket.udp_listen(UDP_IP, MY_PORT)
-- print(string.format("[Node %d] Started (%s) in %s", node_id, node_type, target_dir))

-- 1. Load the specific logic for this node type
local node_logic_path = target_dir:gsub("/", ".") .. ".nodes." .. node_type
local ok, node_module = pcall(require, node_logic_path)
if not ok then
    -- Fallback to relative path if absolute module fails
    node_logic_path = "nodes." .. node_type
    ok, node_module = pcall(require, node_logic_path)
end

if not ok then
    print(string.format("[Node %d] FATAL: Could not load logic for type '%s': %s", node_id, node_type, node_module))
    os.exit(1)
end

local history = {}
local ltm_path = string.format("%s/memory_node_%d.json", target_dir, node_id)
local knowledge_base = {}

-- Core Execution Bridge
local function execute_process(input_msg)
    local context = { node_id = node_id, target_dir = target_dir }
    
    if config.use_memory and #history > 0 then
        context.history_context = "\nRecent History:\n" .. table.concat(history, "\n") .. "\n"
    end

    local output = node_module.process(input_msg, config, context)
    
    if output and config.use_memory then
        table.insert(history, "User: " .. input_msg)
        table.insert(history, "Assistant: " .. output)
        if #history > 20 then for i=1, 4 do table.remove(history, 1) end end
    end

    return output
end

while true do
    local data = my_sock:receive()
    if data then
        local ok, msg = pcall(json.decode, data)
        if ok and msg.payload ~= nil then
            local output = execute_process(msg.payload)
            my_sock:send(UDP_IP, ROUTER_PORT, json.encode({ source_id = node_id, payload = output, completed_msg = true }))
        end
    end
    os.execute("sleep 0.05")
end
