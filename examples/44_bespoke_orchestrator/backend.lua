local ffi = require("ffi")
local json = require("mc.json")
local socket = require("mc.socket")

local UDP_IP = "127.0.0.1"
local TELEMETRY_PORT = 5555
local COMMAND_PORT = 5556
local ROUTER_PORT = 5557
local BROADCAST_INTERVAL = 0.05

-- Orchestrator State
local worker_pids = {} -- node_id -> pid
local graph = { nodes = {}, links = {} }
local logs = {}
local node_queues = {}
for i=1, 200 do node_queues[i] = {} end

local function log_msg(msg)
    table.insert(logs, msg)
    print(msg)
end

local command_sock = socket.udp_listen(UDP_IP, COMMAND_PORT)
local router_sock = socket.udp_listen(UDP_IP, ROUTER_PORT)

local function kill_workers()
    for id, pid in pairs(worker_pids) do
        os.execute("kill " .. pid .. " 2>/dev/null")
    end
    worker_pids = {}
    log_msg("[SYS] All worker processes terminated.")
end

local function spawn_worker(node)
    local cfg = json.encode(node.config or {})
    local cmd = string.format([[export LUA_PATH="src/lua/?.lua;src/lua/?/init.lua;;" && luajit examples/44_bespoke_orchestrator/node_worker.lua %d %s '%s' & echo $!]], node.id, node.type, cfg)
    local f = io.popen(cmd)
    local pid = f:read("*a"):gsub("%s+", "")
    f:close()
    worker_pids[node.id] = tonumber(pid)
    log_msg(string.format("[SYS] Spawned Node %d (PID %s)", node.id, pid))
end

local function get_process_metrics(pid)
    if not pid then return { cpu = 0, mem = 0, alive = false } end
    local f = io.popen(string.format("ps -p %d -o %%cpu,rss,comm= 2>/dev/null", pid))
    if not f then return { cpu = 0, mem = 0, alive = false } end
    local res = f:read("*a")
    f:close()
    
    if res == "" then return { cpu = 0, mem = 0, alive = false } end
    
    -- Parse ps output (e.g. " 0.5  12340 luajit")
    local cpu, rss = res:match("%s*([%d%.]+)%s+(%d+)")
    return {
        cpu = tonumber(cpu) or 0,
        mem = (tonumber(rss) or 0) / 1024, -- KB to MB
        alive = true
    }
end

local function handle_command(cmd_data)
    local ok, cmd = pcall(json.decode, cmd_data)
    if not ok then return end
    
    if cmd.type == "sync_graph" then
        kill_workers()
        graph.nodes = cmd.payload.nodes
        graph.links = cmd.payload.links
        for _, n in ipairs(graph.nodes) do spawn_worker(n) end
        log_msg("[SYS] Graph synced. " .. #graph.nodes .. " processes active.")
    elseif cmd.type == "inject_event" then
        local nid = cmd.payload.node_id
        local port = 6000 + nid
        command_sock:send(UDP_IP, port, json.encode({ payload = cmd.payload.data }))
        if not node_queues[nid] then node_queues[nid] = {} end
        table.insert(node_queues[nid], cmd.payload.data)
        log_msg("[CMD] Injected event into Node " .. nid)
    elseif cmd.type == "run_optimizer" then
        local proposal = {
            type = "shadow_proposal",
            nodes = {
                { id = 101, type = "agent", name = "Critique Agent", color = {0.8, 0.2, 0.2, 1}, expanded = true, config = {model="gemini", prompt="Identify flaws."} }
            },
            links = {
                { id = 201, start = 3, end_node = 101 },
                { id = 202, start = 101, end_node = 5 }
            }
        }
        command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode(proposal))
    end
end

local function handle_router_message(data)
    local ok, msg = pcall(json.decode, data)
    if not ok then return end
    local src_id = msg.source_id
    if node_queues[src_id] and #node_queues[src_id] > 0 then table.remove(node_queues[src_id], 1) end
    for _, link in ipairs(graph.links) do
        if link.start == src_id then
            local dst_id = link.end_node
            router_sock:send(UDP_IP, 6000 + dst_id, json.encode({ payload = msg.payload }))
            if not node_queues[dst_id] then node_queues[dst_id] = {} end
            table.insert(node_queues[dst_id], msg.payload)
            log_msg(string.format("[FLOW] %d -> %d", src_id, dst_id))
        end
    end
end

log_msg("🌙 MoonCrust Orchestrator Dashboard Active")

local last_tick = os.clock()
local last_metrics_tick = os.clock()
local metrics = {}

while true do
    local cmd_data = command_sock:receive()
    if cmd_data then handle_command(cmd_data) end

    local route_data = router_sock:receive()
    if route_data then handle_router_message(route_data) end
    
    local now = os.clock()
    if now - last_metrics_tick > 1.0 then -- Gather metrics every 1s
        metrics = {}
        for id, pid in pairs(worker_pids) do
            metrics[tostring(id)] = get_process_metrics(pid)
        end
        last_metrics_tick = now
    end

    if now - last_tick > BROADCAST_INTERVAL then
        -- Telemetry
        local t = {
            timestamp = os.time(),
            concurrency = #worker_pids * 100 + (math.random() * 50),
            latency_ms = 10 + (math.random() * 5),
            metrics = metrics, -- Include health metrics!
            logs = logs
        }
        logs = {}
        command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode(t))
        
        for nid, q in pairs(node_queues) do
            if #q > 0 or math.random() > 0.98 then
                command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ type = "node_update", node_id = nid, messages = q }))
            end
        end
        last_tick = now
    end
    os.execute("sleep 0.01")
end
