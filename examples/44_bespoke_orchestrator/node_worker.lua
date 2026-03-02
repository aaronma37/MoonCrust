local ffi = require("ffi")
local json = require("mc.json")
local socket = require("mc.socket")

local node_id = tonumber(arg[1])
local node_type = arg[2]
local config_raw = arg[3]
local config = json.decode(config_raw)

local UDP_IP = "127.0.0.1"
local ROUTER_PORT = 5557
local MY_PORT = 6000 + node_id

local my_sock = socket.udp_listen(UDP_IP, MY_PORT)
print(string.format("[Node %d] Started (%s)", node_id, node_type))

-- 1. Load the specific logic for this node type
local node_logic_path = "examples.44_bespoke_orchestrator.nodes." .. node_type
local ok, node_module = pcall(require, node_logic_path)
if not ok then
    print(string.format("[Node %d] FATAL: Could not load logic for type '%s': %s", node_id, node_type, node_module))
    os.exit(1)
end

-- 2. State Management (Shared by all nodes via context)
local history = {}
local MAX_HISTORY = 10
local ltm_path = string.format("examples/44_bespoke_orchestrator/memory_node_%d.json", node_id)
local knowledge_base = {}

-- Load LTM if enabled
if config.use_ltm then
    local f = io.open(ltm_path, "r")
    if f then
        local data = f:read("*a")
        if data ~= "" then knowledge_base = json.decode(data) or {} end
        f:close()
    end
end

local function save_ltm()
    local f = io.open(ltm_path, "w")
    if f then f:write(json.encode(knowledge_base)); f:close() end
end

-- Vector Math (for LTM nodes)
local function get_embedding(text)
    local safe_text = text:gsub('"', '\\"'):gsub("'", "\\'"):gsub("\n", " ")
    local cmd = string.format([[curl -s -X POST http://localhost:11434/api/embeddings -d '{"model": "all-minilm", "prompt": "%s"}' 2>/dev/null]], safe_text)
    local f = io.popen(cmd)
    if not f then return nil end
    local res = f:read("*a")
    f:close()
    local ok, data = pcall(json.decode, res)
    return ok and data and data.embedding or nil
end

local function cosine_similarity(v1, v2)
    if not v1 or not v2 or #v1 ~= #v2 then return 0 end
    local dot, mag1, mag2 = 0, 0, 0
    for i=1, #v1 do dot = dot + v1[i] * v2[i]; mag1 = mag1 + v1[i] * v1[i]; mag2 = mag2 + v2[i] * v2[i] end
    local mag = math.sqrt(mag1) * math.sqrt(mag2)
    return mag == 0 and 0 or dot / mag
end

-- Core Execution Bridge
local function execute_process(input_msg)
    local context = { node_id = node_id }
    
    -- Handle LTM Retrieval
    if config.use_ltm then
        local query_vec = get_embedding(input_msg)
        if query_vec then
            local best_mem, best_sim = nil, -1
            for _, mem in ipairs(knowledge_base) do
                local sim = cosine_similarity(query_vec, mem.vector)
                if sim > best_sim then best_sim = sim; best_mem = mem end
            end
            if best_mem and best_sim > 0.7 then 
                context.recalled_context = "\n[RECALLED MEMORY]: " .. best_mem.text .. "\n" 
            end
        end
    end

    -- Handle Short Term Context
    if config.use_memory and #history > 0 then
        context.history_context = "\nRecent History:\n" .. table.concat(history, "\n") .. "\n"
    end

    -- Call the modular logic!
    local output = node_module.process(input_msg, config, context)
    
    if output then
        -- Update Short Term History (if LLM/Vision response)
        if (node_type == "llm" or node_type == "vision") and config.use_memory then
            table.insert(history, "User: " .. input_msg)
            table.insert(history, "Assistant: " .. output)
            
            -- Sleep Cycle (Consolidation)
            if #history > MAX_HISTORY * 2 then
                -- (Implementation of summarization could be moved to nodes/llm.lua or kept here)
                for i=1, 4 do table.remove(history, 1) end
            end
        end
    end

    return output
end

-- Main Loop
local last_const_time = os.clock()
while true do
    local data = my_sock:receive()
    if data then
        local ok, msg = pcall(json.decode, data)
        if ok and msg.payload then
            local output = execute_process(msg.payload)
            if output then 
                my_sock:send(UDP_IP, ROUTER_PORT, json.encode({ source_id = node_id, payload = output })) 
            end
        end
    end
    
    -- Heartbeat for Constant nodes
    if node_type == "constant" and os.clock() - last_const_time > 5.0 then
        local output = execute_process("")
        if output then
            my_sock:send(UDP_IP, ROUTER_PORT, json.encode({ source_id = node_id, payload = output }))
        end
        last_const_time = os.clock()
    end
    
    os.execute("sleep 0.05")
end
