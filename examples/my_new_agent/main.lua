local ffi = require("ffi")
local vk = require("vulkan.ffi")
local swapchain = require("vulkan.swapchain")
local sdl = require("vulkan.sdl")
local mc = require("mc")
local json = require("mc.json")

-- ARG 1: TARGET DIRECTORY
local target_dir = _G.MC_ORCHESTRATOR_DIR or arg[1] or "examples/44_bespoke_orchestrator"
_G.IMGUI_LIB_PATH = "examples/44_bespoke_orchestrator/build/mooncrust_orchestrator.so"
local imgui = require("imgui")

local M = { 
    nodes = {}, links = {}, node_map = {},
    telemetry = { concurrency = ffi.new("float[100]"), latency = ffi.new("float[100]"), ptr = 0 },
    logs = {}, next_node_id = 10, next_link_id = 10, zoom = 1.0, auto_layout = false, auto_pulse = true,
    heartbeat_interval = 5.0, heartbeat_last_time = 0
}

local function term_log(...) print("[KERN-LOG]", ...) end

function M.add_node(type, name, x, y)
    local id = M.next_node_id; M.next_node_id = M.next_node_id + 1
    local n = { id = id, type = type, name = name, color = {0.5, 0.5, 0.5, 1}, expanded = true, config = {} }
    if type == "agent" then n.config = { model = ffi.new("char[256]", "gemini"), prompt = ffi.new("char[256]", "") }
    elseif type == "transform" then n.config = { expression = ffi.new("char[2048]", "return input") }
    elseif type == "overseer" then n.config = { goal = ffi.new("char[256]", "Optimize the DAG") } end
    table.insert(M.nodes, n); M.node_map[id] = n
    if x and y then imgui.gui.imnodes_SetNodeEditorSpacePos(id, ffi.new("ImVec2_c", {x, y})) end
    return id
end

function M.send_command(cmd_type, payload)
    if udp_socket then udp_socket:send("127.0.0.1", 5556, json.encode({ type = cmd_type, payload = payload })) end
end

function M.sync_to_backend()
    local data = { nodes = {}, links = M.links }
    for _, n in ipairs(M.nodes) do
        local node_data = { id = n.id, type = n.type, name = n.name, config = {} }
        for k, v in pairs(n.config) do node_data.config[k] = (type(v) == "cdata") and ffi.string(v) or v end
        table.insert(data.nodes, node_data)
    end
    M.send_command("sync_graph", data)
end

function M.load_graph(filename)
    local f = io.open(target_dir .. "/" .. filename, "r")
    if not f then return false end
    local ok, data = pcall(json.decode, f:read("*a")); f:close()
    if not ok then return false end
    M.nodes = {}; M.node_map = {}
    for _, n in ipairs(data.nodes) do
        local new_node = { id = n.id, type = n.type, name = n.name, expanded = true, config = {} }
        for k, v in pairs(n.config or {}) do
            if k == "expression" then new_node.config[k] = ffi.new("char[2048]", tostring(v))
            else new_node.config[k] = ffi.new("char[256]", tostring(v)) end
        end
        table.insert(M.nodes, new_node); M.node_map[n.id] = new_node
        if n.x and n.y then imgui.gui.imnodes_SetNodeEditorSpacePos(n.id, ffi.new("ImVec2_c", {n.x, n.y})) end
    end
    M.links = data.links or {}; M.next_node_id = data.next_node_id or 10; M.next_link_id = data.next_link_id or 10
    return true
end

function M.save_graph(filename)
    local data = { nodes = {}, links = M.links, next_node_id = M.next_node_id, next_link_id = M.next_link_id }
    for _, n in ipairs(M.nodes) do
        local pos = imgui.gui.imnodes_GetNodeEditorSpacePos(n.id)
        local node_data = { id = n.id, type = n.type, name = n.name, x = pos.x, y = pos.y, config = {} }
        for k, v in pairs(n.config) do node_data.config[k] = (type(v) == "cdata") and ffi.string(v) or v end
        table.insert(data.nodes, node_data)
    end
    local f = io.open(target_dir .. "/" .. filename, "w")
    if f then f:write(json.encode(data)); f:close() end
end

function M.init()
    local instance, pd, device = vulkan.get_instance(), vulkan.get_physical_device(), vulkan.get_device()
    sw = swapchain.new(instance, pd, device, _G._SDL_WINDOW)
    imgui.init(); M.nodes_ctx = imgui.gui.imnodes_CreateContext(); imgui.gui.imnodes_StyleColorsDark(nil)
    if not M.load_graph("save_graph.json") then if not M.load_graph("template_graph.json") then M.add_node("trigger", "Start", 100, 300) end end
    local pool = vulkan.get_pool(); cb = vulkan.get_cb()
    pcall(function() udp_socket = require("mc.socket").udp_listen("127.0.0.1", 5555) end)
    M.sync_to_backend() -- Auto-sync on start
end
function M.draw_node(node)
    local gui = imgui.gui
    gui.igPushID_Int(node.id); gui.imnodes_BeginNode(node.id)
    gui.imnodes_BeginNodeTitleBar(); gui.igTextUnformatted(node.name, nil); gui.imnodes_EndNodeTitleBar()
    gui.imnodes_BeginInputAttribute(node.id * 100, 1); gui.igText("IN"); gui.imnodes_EndInputAttribute(); gui.igSameLine(0, 40); gui.imnodes_BeginOutputAttribute(node.id * 100 + 1, 1); gui.igText("OUT"); gui.imnodes_EndOutputAttribute()
    if node.type == "trigger" then if gui.igButton("Pulse", ffi.new("ImVec2_c", {60, 20})) then M.send_command("inject_event", {node_id = node.id, data = "trigger_" .. os.time()}) end
    elseif node.type == "agent" then gui.igInputText("Model", node.config.model, 256); gui.igInputText("Prompt", node.config.prompt, 256)
    elseif node.type == "overseer" then gui.igInputText("Goal", node.config.goal, 256) end
    gui.imnodes_EndNode(); gui.igPopID()
end

function M.update()
    local img_idx = sw:acquire_next_image()
    if not img_idx then return end

    local overseer_finished = false
    if udp_socket then while true do local data = udp_socket:receive(); if not data then break end
        local ok, msg = pcall(json.decode, data)
        if ok and msg.type == "node_update" then local n = M.node_map[msg.node_id]; if n then n.messages = msg.messages end
        elseif ok and msg.type == "overseer_complete" then overseer_finished = true
        elseif ok and msg.logs then for _, l in ipairs(msg.logs) do table.insert(M.logs, l) end end
    end end

    if M.auto_pulse then
        local now = os.clock()
        -- Wait for BOTH interval AND overseer completion signal
        if (now - M.heartbeat_last_time > M.heartbeat_interval) and (overseer_finished or M.heartbeat_last_time == 0) then
            local trigger_node = M.nodes[1] -- Assuming first node is trigger or look for type
            for _, n in ipairs(M.nodes) do if n.type == "trigger" then trigger_node = n; break end end
            if trigger_node then
                M.send_command("inject_event", {node_id = trigger_node.id, data = "heartbeat_" .. os.time()})
                M.heartbeat_last_time = now
            end
        end
    end
    gui.igSetNextWindowPos(ffi.new("ImVec2_c",{0,0})); gui.igSetNextWindowSize(gui.igGetIO_Nil().DisplaySize)
    if gui.igBegin("Orchestrator", nil, 43+1024) then
        gui.igBeginChild_Str("Graph", ffi.new("ImVec2_c", {gui.igGetContentRegionAvail().x - 300, 0}), true)
        gui.imnodes_BeginNodeEditor(); for _, n in ipairs(M.nodes) do M.draw_node(n) end
        for _, l in ipairs(M.links) do gui.imnodes_Link(l.id, l.start * 100 + 1, l.end_node * 100) end
        gui.imnodes_EndNodeEditor(); gui.igEndChild(); gui.igSameLine(); gui.igBeginGroup()
        if gui.igButton("Save", ffi.new("ImVec2_c",{100,20})) then M.save_graph("save_graph.json") end
        if gui.igButton("Sync", ffi.new("ImVec2_c",{100,20})) then M.sync_to_backend() end
        gui.igText("Logs"); gui.igBeginChild_Str("LogScroll", ffi.new("ImVec2_c",{0,0}), true)
        for _, l in ipairs(M.logs) do gui.igTextUnformatted(l) end
        gui.igEndChild(); gui.igEndGroup(); gui.igEnd()
    end
    vulkan.begin_render(cb, sw, img_idx); imgui.render(cb); vulkan.end_render(cb, sw, img_idx)
end

return M
