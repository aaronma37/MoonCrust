local ffi = require("ffi")
local json = require("mc.json")
local socket = require("mc.socket")

-- ARG 1: TARGET DIRECTORY
local target_dir = arg[1] or "examples/44_bespoke_orchestrator"

local UDP_IP = "127.0.0.1"
local TELEMETRY_PORT = 5555
local COMMAND_PORT = 5556
local ROUTER_PORT = 5557
local BROADCAST_INTERVAL = 0.05

-- Orchestrator State
local worker_pids = {}
local graph = { nodes = {}, links = {} }
local logs = {}
local node_queues = {}
for i = 1, 200 do node_queues[i] = {} end

local in_flight_messages = 0
local global_pulse_context = {}
local next_auto_id = 500

local function log_msg(msg)
	table.insert(logs, msg)
	print(msg)
	local f = io.open("/tmp/mooncrust_backend.log", "a")
	if f then f:write(tostring(msg) .. "\n"); f:close() end
end

local command_sock, router_sock
for i = 1, 10 do
	command_sock = socket.udp_listen(UDP_IP, COMMAND_PORT)
	if command_sock then break end
	print("[SYS] Waiting for COMMAND_PORT " .. COMMAND_PORT .. " to become available...")
	os.execute("sleep 0.5")
end
for i = 1, 10 do
	router_sock = socket.udp_listen(UDP_IP, ROUTER_PORT)
	if router_sock then break end
	print("[SYS] Waiting for ROUTER_PORT " .. ROUTER_PORT .. " to become available...")
	os.execute("sleep 0.5")
end

if not command_sock or not router_sock then
	print("[FATAL] Could not bind to required ports. Exiting backend.")
	os.exit(1)
end

local function kill_workers()
	for id, pid in pairs(worker_pids) do os.execute("kill -9 " .. pid .. " 2>/dev/null") end
	worker_pids = {}
end

local function spawn_worker(node)
	local cfg_raw = json.encode(node.config or {})
	local cfg_escaped = cfg_raw:gsub("'", "'\\''")
	
	local log_path = string.format("/tmp/mc_node_%d.log", node.id)
    -- TARGET_DIR must be passed to worker so it can load the correct logic modules
	local cmd = string.format(
		[[export LUA_PATH="src/lua/?.lua;src/lua/?/init.lua;./%s/?.lua;;" && luajit %s/node_worker.lua %d %s '%s' %s > %s 2>&1 & echo $!]],
		target_dir, target_dir, node.id, node.type, cfg_escaped, target_dir, log_path
	)
	
	local f = io.popen(cmd)
	if not f then return nil end
	local pid = f:read("*a"):gsub("%s+", "")
	f:close()
	
	local pid_num = tonumber(pid)
	if pid_num then
		worker_pids[node.id] = pid_num
		log_msg(string.format("[SYS] Node %d (%s) PID %d", node.id, node.type, pid_num))
	end
	return pid_num
end

local function handle_mutation(mutation)
    if not mutation or type(mutation) ~= "table" then return end
    if mutation.op == "add_node" then
        local id = next_auto_id; next_auto_id = next_auto_id + 1
        local new_node = { id = id, type = mutation.type, name = mutation.name or "Auto", config = mutation.config or {} }
        table.insert(graph.nodes, new_node); spawn_worker(new_node)
        command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ type = "force_sync_ui", nodes = graph.nodes, links = graph.links }))
    end
end

local function handle_command(cmd_data)
	local ok, cmd = pcall(json.decode, cmd_data)
	if not ok then return end
	if cmd.type == "sync_graph" then
		kill_workers()
		graph.nodes = cmd.payload.nodes
		graph.links = cmd.payload.links
		for _, n in ipairs(graph.nodes) do spawn_worker(n) end
	elseif cmd.type == "inject_event" then
		local nid = cmd.payload.node_id
		in_flight_messages = in_flight_messages + 1
		table.insert(global_pulse_context, string.format("--- PULSE START @ NODE %d ---", nid))
		command_sock:send(UDP_IP, 6000 + nid, json.encode({ payload = cmd.payload.data }))
		if not node_queues[nid] then node_queues[nid] = {} end
		table.insert(node_queues[nid], cmd.payload.data)
	end
end

local function handle_router_message(data)
	local ok, msg = pcall(json.decode, data)
	if not ok then return end
	local src_id = msg.source_id
	if not src_id then return end
	if msg.completed_msg then in_flight_messages = math.max(0, in_flight_messages - 1) end
	if node_queues[src_id] and #node_queues[src_id] > 0 then table.remove(node_queues[src_id], 1) end
	local is_src_overseer = false
	for _, n in ipairs(graph.nodes) do if n.id == src_id and n.type == "overseer" then is_src_overseer = true; break end end
	if msg.payload then
		if is_src_overseer then
			log_msg("[OVERSEER]\n" .. tostring(msg.payload))
            -- SIGNAL COMPLETION TO UI
            command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ type = "overseer_complete" }))
            
            local dec = tostring(msg.payload):match("ARCHITECT_DECISION: (.*)")
            if dec then local ok_dec, dec_json = pcall(json.decode, dec); if ok_dec and dec_json.mutation then handle_mutation(dec_json.mutation) end end
		else
			table.insert(global_pulse_context, string.format("[NODE %d]: %s", src_id, tostring(msg.payload)))
		end
		if not is_src_overseer then
			for _, link in ipairs(graph.links) do
				if link.start == src_id then
					local dst_id = link.end_node
					local is_dst_overseer = false
					for _, n in ipairs(graph.nodes) do if n.id == dst_id and n.type == "overseer" then is_dst_overseer = true; break end end
					if not is_dst_overseer then
						in_flight_messages = in_flight_messages + 1
						router_sock:send(UDP_IP, 6000 + dst_id, json.encode({ payload = msg.payload }))
						if not node_queues[dst_id] then node_queues[dst_id] = {} end
						table.insert(node_queues[dst_id], msg.payload)
					end
				end
			end
		end
	end
	if in_flight_messages == 0 and #global_pulse_context > 0 then
		local ctx_str = table.concat(global_pulse_context, "\n")
		local triggered = false
		for _, n in ipairs(graph.nodes) do 
			if n.type == "overseer" then 
				in_flight_messages = in_flight_messages + 1; 
				router_sock:send(UDP_IP, 6000 + n.id, json.encode({ payload = ctx_str })) 
				triggered = true
			end 
		end
		
		if not triggered then
			-- If no overseer, immediately signal completion to UI
			command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ type = "overseer_complete" }))
		end
		global_pulse_context = {}
	end
end

-- Inside handle_router_message, when an overseer finishes
-- (Needs to be added inside handle_router_message where is_src_overseer is checked)


log_msg("🌙 Backend ready (Target: " .. target_dir .. ")")
local last_tick = os.clock()
local last_metrics_tick = os.clock()
while true do
	local cmd_data = command_sock:receive()
	if cmd_data then handle_command(cmd_data) end
	local route_data = router_sock:receive()
	if route_data then handle_router_message(route_data) end
	local now = os.clock()
	if now - last_tick > BROADCAST_INTERVAL then
		command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ timestamp = os.time(), concurrency = #worker_pids * 10, latency_ms = 1, logs = logs }))
		logs = {}
		for nid, q in pairs(node_queues) do if #q > 0 then command_sock:send(UDP_IP, TELEMETRY_PORT, json.encode({ type = "node_update", node_id = nid, messages = q })) end end
		last_tick = now
	end
	os.execute("sleep 0.01")
end
