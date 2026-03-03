local ffi = require("ffi")
local vk = require("vulkan.ffi")
local descriptors = require("vulkan.descriptors")
local command = require("vulkan.command")
local shader = require("vulkan.shader")
local pipeline = require("vulkan.pipeline")
local swapchain = require("vulkan.swapchain")
local render_graph = require("vulkan.graph")
local input = require("mc.input")
local mc = require("mc")
local json = require("mc.json")
local sdl = require("vulkan.sdl")

-- SET LIB PATH BEFORE REQUIRING IMGUI
_G.IMGUI_LIB_PATH = "examples/44_bespoke_orchestrator/build/mooncrust_orchestrator.so"
local imgui = require("imgui")
local nodes_ffi = require("imgui.nodes_ffi")

-- Load bespoke library for callback symbols
ffi.cdef[[
    void orchestrator_dummy_callback(const void* parent_list, const void* cmd);
]]
local bespoke_lib = ffi.load(_G.IMGUI_LIB_PATH)

-- Custom orchestrator state
local M = { 
    agents = {},
    telemetry = { concurrency = ffi.new("float[100]"), latency = ffi.new("float[100]"), ptr = 0 },
    metrics = {}, 
    logs = {}, auto_scroll = true, last_packet_time = 0,
    zoom = 1.0,
    show_shadow = false,
    auto_layout = false, 
    nodes = {
        { id = 0, type = "objective", name = "Kernel Mission", color = {1.0, 0.8, 0.2, 1}, expanded = true, memory = {}, config = { goal = ffi.new("char[256]", "Synthesize a universal GPU orchestrator.") } },
        { id = 1, type = "trigger", name = "System Pulse", color = {0.2, 0.5, 0.9, 1}, expanded = true, memory = {}, messages = {} },
        { id = 2, type = "transform", name = "Telemetry Aggregator", color = {0.3, 0.7, 0.9, 1}, expanded = true, memory = {}, messages = {}, config = { expression = ffi.new("char[2048]", "return {\n  latency = telemetry.latency[telemetry.ptr],\n  concurrency = telemetry.concurrency[telemetry.ptr]\n}") } },
        { id = 3, type = "transform", name = "Evolutionary Engine", color = {0.9, 0.3, 0.3, 1}, expanded = true, memory = {}, messages = {}, config = { expression = ffi.new("char[2048]", "-- Growth Logic\nmemory.tick = (memory.tick or 0) + 1\nprint('Pulse ' .. memory.tick)\n\nif memory.tick == 2 and not memory.spawned then\n  print('ACTION: Spawning Gemini...')\n  local aid = mutate.add_node('agent', 'Gemini Strategist', 600, 150)\n  mutate.set_config(aid, 'model', 'gemini-2.0-flash')\n  mutate.add_link(aid, 4)\n  mutate.swap_link(node.id, 4, aid)\n  memory.spawned = true\nend\nreturn input") } },
        { id = 4, type = "action", name = "Kernel Actuator", color = {0.1, 0.8, 0.4, 1}, expanded = true, memory = {}, messages = {} },
    },
    links = {
        { id = 1, start = 1, end_node = 2 },
        { id = 2, start = 2, end_node = 3 },
        { id = 3, start = 3, end_node = 4 }, 
    },
    shadow_nodes = {},
    shadow_links = {},
    node_map = {},
    next_node_id = 10, next_link_id = 10,
    heartbeat_interval = 1.0,
    heartbeat_last_time = 0,
    auto_pulse = false,
    total_executions = 0,
}

-- REDIRECT STDOUT TO UI
local old_print = print
_G.print = function(...)
    old_print(...) 
    local str = ""
    local args = {...}
    for i, v in ipairs(args) do
        str = str .. tostring(v) .. (i < #args and "\t" or "")
    end
    table.insert(M.logs, "[STDOUT] " .. str)
    if #M.logs > 200 then table.remove(M.logs, 1) end
end

local function term_log(...)
    old_print("[KERN-LOG]", ...)
end

-- UTILITY TO ENSURE FFI BUFFER
local function ensure_buffer(node, key, default_val, size)
    if not node.config[key] or type(node.config[key]) ~= "cdata" then
        node.config[key] = ffi.new("char["..size.."]", tostring(node.config[key] or default_val))
    end
    return node.config[key]
end

-- MUTATION API
function M.add_node(type, name, x, y)
    local id = M.next_node_id; M.next_node_id = M.next_node_id + 1
    local n = { id = id, type = type, name = name, color = {0.5, 0.5, 0.5, 1}, expanded = true, messages = {}, memory = {} }
    if type == "agent" then n.config = { model = ffi.new("char[256]", "gemini"), prompt = ffi.new("char[256]", "") }
    elseif type == "transform" then n.config = { expression = ffi.new("char[2048]", "return input") }
    elseif type == "router" then n.config = { condition = ffi.new("char[256]", "") }
    elseif type == "objective" then n.config = { goal = ffi.new("char[256]", "") }
    else n.config = {} end
    table.insert(M.nodes, n)
    M.node_map[id] = n
    if x and y then imgui.gui.imnodes_SetNodeEditorSpacePos(id, ffi.new("ImVec2_c", {x, y})) end
    term_log("[MUTATE] Added node: " .. name .. " ID: " .. id)
    return id
end

function M.delete_node(id)
    if id == 0 then return end
    for i, n in ipairs(M.nodes) do
        if n.id == id then table.remove(M.nodes, i); M.node_map[id] = nil; break end
    end
    for i = #M.links, 1, -1 do
        if M.links[i].start == id or M.links[i].end_node == id then table.remove(M.links, i) end
    end
    term_log("[MUTATE] Deleted node: " .. id)
end

function M.add_link(start_id, end_id)
    local id = M.next_link_id; M.next_link_id = M.next_link_id + 1
    table.insert(M.links, { id = id, start = start_id, end_node = end_id })
    term_log("[MUTATE] Added link: " .. start_id .. " -> " .. end_id)
    return id
end

function M.swap_link(from_id, old_to_id, new_to_id)
    for _, l in ipairs(M.links) do
        if l.start == from_id and l.end_node == old_to_id then
            l.end_node = new_to_id
            term_log(string.format("[MUTATE] Swapped Bridge: %d -> (%d to %d)", from_id, old_to_id, new_to_id))
            return true
        end
    end
    return false
end

function M.set_node_config(id, key, value)
    local n = M.node_map[id]
    if not n or not n.config then return end
    if type(n.config[key]) == "cdata" then 
        ffi.copy(n.config[key], tostring(value)) 
    else 
        n.config[key] = value 
    end
end

function M.send_command(cmd_type, payload)
    if udp_socket then
        local msg = json.encode({ type = cmd_type, payload = payload })
        udp_socket:send("127.0.0.1", 5556, msg)
    end
end

-- LUA EVALUATOR
function M.execute_node(node, input_data, ttl)
    ttl = ttl or 10
    if ttl <= 0 then return end

    node.last_active = os.clock()
    node.is_processing = true
    node.pulse_count = (node.pulse_count or 0) + 1
    M.total_executions = M.total_executions + 1

    local function propagate(res)
        for _, link in ipairs(M.links) do
            if link.start == node.id then
                local next_node = M.node_map[link.end_node]
                if next_node then M.execute_node(next_node, res, ttl - 1) end
            end
        end
    end

    local status, result = pcall(function()
        if node.type == "transform" and node.config and node.config.expression then
            local env = {
                input = input_data, nodes = M.nodes, links = M.links, node = node, memory = node.memory, telemetry = M.telemetry,
                print = print, mutate = { add_node = M.add_node, delete_node = M.delete_node, add_link = M.add_link, swap_link = M.swap_link, set_config = M.set_node_config },
                send = function(id, data) if M.node_map[id] then M.execute_node(M.node_map[id], data, ttl - 1) end end,
                math = math, table = table, string = string, os = os
            }
            local expr_str = type(node.config.expression) == "cdata" and ffi.string(node.config.expression) or tostring(node.config.expression)
            local fn, err = load(expr_str, "node_" .. node.id, "t", env)
            if not fn then error(err) end
            local ok, res = pcall(fn)
            if not ok then error(res) end
            node.messages = node.messages or {}; table.insert(node.messages, { time = os.time(), data = tostring(res) })
            if #node.messages > 5 then table.remove(node.messages, 1) end
            propagate(res)
            return res
        elseif node.type == "agent" then
            local model = (type(node.config.model) == "cdata") and ffi.string(node.config.model) or tostring(node.config.model or "gemini")
            local prompt = (type(node.config.prompt) == "cdata") and ffi.string(node.config.prompt) or tostring(node.config.prompt or "")
            
            term_log("AGENT " .. node.id .. " REQUESTING REASONING...")
            
            -- 1. SEND REAL REQUEST OVER NETWORK
            M.send_command("agent_query", {
                node_id = node.id,
                model = model,
                prompt = prompt,
                input = input_data
            })

            -- 2. ENHANCED SIMULATION (While waiting for real server)
            print("--- AGENT START [" .. model .. "] ---")
            print("PROMPT: " .. prompt)
            
            -- Act like a real optimizer using the input telemetry
            local lat = type(input_data) == "table" and (input_data.latency or 0) or 0
            local res = string.format("Reasoned: [Decision %d] Kernel Latency is %.2fms. Status: %s", 
                node.pulse_count, lat, lat > 50 and "OPTIMIZE" or "STABLE")
            
            print("RESULT: " .. res)
            print("--- AGENT END ---")
            
            node.messages = node.messages or {}; table.insert(node.messages, { time = os.time(), data = res })
            propagate(res)
            return res
        elseif node.type == "action" then
            table.insert(M.logs, "[ACTUATOR] Final Output: " .. tostring(input_data))
            propagate(input_data)
            return input_data
        else
            propagate(input_data)
            return input_data
        end
    end)

    node.is_processing = false
    if not status then 
        node.error_state = tostring(result)
        term_log("NODE " .. node.id .. " ERR: " .. node.error_state) 
    else
        node.error_state = nil
    end
end

-- AUTO-LAYOUT
function M.do_auto_layout()
    if not M.auto_layout then return end
    local k = 250.0; local pos = {}
    for _, n in ipairs(M.nodes) do
        local p = imgui.gui.imnodes_GetNodeEditorSpacePos(n.id)
        pos[n.id] = { x = p.x, y = p.y, dx = 0, dy = 0 }
    end
    for i = 1, 2 do
        for _, n1 in ipairs(M.nodes) do
            for _, n2 in ipairs(M.nodes) do
                if n1.id ~= n2.id then
                    local dx, dy = pos[n1.id].x - pos[n2.id].x, pos[n1.id].y - pos[n2.id].y
                    local dist = math.sqrt(dx*dx + dy*dy) + 1.0
                    pos[n1.id].dx = pos[n1.id].dx + (dx/dist) * (k*k/dist)
                    pos[n1.id].dy = pos[n1.id].dy + (dy/dist) * (k*k/dist)
                end
            end
        end
        for _, l in ipairs(M.links) do
            if pos[l.start] and pos[l.end_node] then
                local dx, dy = pos[l.start].x - pos[l.end_node].x, pos[l.start].y - pos[l.end_node].y
                local dist = math.sqrt(dx*dx + dy*dy) + 0.1
                pos[l.start].dx, pos[l.start].dy = pos[l.start].dx - (dx/dist)*(dist*dist/k), pos[l.start].dy - (dy/dist)*(dist*dist/k)
                pos[l.end_node].dx, pos[l.end_node].dy = pos[l.end_node].dx + (dx/dist)*(dist*dist/k), pos[l.end_node].dy + (dy/dist)*(dist*dist/k)
            end
        end
        local cx, cy = 500, 300
        for _, n in ipairs(M.nodes) do
            local p = pos[n.id]
            p.x = p.x + math.max(-50, math.min(50, (p.dx + (cx - p.x)*0.5) * 0.05))
            p.y = p.y + math.max(-50, math.min(50, (p.dy + (cy - p.y)*0.5) * 0.05))
            p.dx, p.dy = 0, 0
        end
    end
    for _, n in ipairs(M.nodes) do imgui.gui.imnodes_SetNodeEditorSpacePos(n.id, ffi.new("ImVec2_c", {pos[n.id].x, pos[n.id].y})) end
end

function M.init()
    local instance, pd = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sdl.SDL_SetWindowFullscreen(_G._SDL_WINDOW, true); sdl.SDL_Delay(100)
    sw = swapchain.new(instance, pd, device, _G._SDL_WINDOW)
    imgui.init(); M.nodes_ctx = imgui.gui.imnodes_CreateContext(); imgui.gui.imnodes_StyleColorsDark(nil)
    imgui.gui.imnodes_GetIO().AltMouseButton = 2 
    for _, n in ipairs(M.nodes) do M.node_map[n.id] = n end
    imgui.gui.imnodes_SetNodeEditorSpacePos(0, ffi.new("ImVec2_c", {100, 100}))
    imgui.gui.imnodes_SetNodeEditorSpacePos(1, ffi.new("ImVec2_c", {100, 300}))
    imgui.gui.imnodes_SetNodeEditorSpacePos(2, ffi.new("ImVec2_c", {350, 300}))
    imgui.gui.imnodes_SetNodeEditorSpacePos(3, ffi.new("ImVec2_c", {600, 300}))
    imgui.gui.imnodes_SetNodeEditorSpacePos(4, ffi.new("ImVec2_c", {850, 300}))
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pSem); image_available_sem = pSem[0]
    pcall(function() udp_socket = require("mc.socket").udp_listen("127.0.0.1", 5555) end)
end

function M.draw_node(node, is_shadow)
    local gui = imgui.gui
    local active_age = os.clock() - (node.last_active or 0)
    if active_age < 1.0 then gui.imnodes_PushColorStyle(gui.ImNodesCol_NodeOutline, M.rgba_to_u32(1, 1, 1, 1.0 - active_age)) end
    if node.is_processing then gui.imnodes_PushColorStyle(gui.ImNodesCol_TitleBar, M.rgba_to_u32(1, 1, 0, 1)) end

    gui.igPushID_Int(node.id); gui.imnodes_BeginNode(node.id)
    gui.imnodes_BeginNodeTitleBar(); gui.igTextUnformatted(node.name, nil); gui.igSameLine(0, 20); gui.igTextColored(ffi.new("ImVec4_c", {0.4, 0.4, 0.4, 1.0}), "⚡ " .. (node.pulse_count or 0)); gui.imnodes_EndNodeTitleBar()
    gui.imnodes_BeginInputAttribute(node.id * 100, 1); gui.igText("MSG IN"); gui.imnodes_EndInputAttribute(); gui.igSameLine(0, 40 * M.zoom); gui.imnodes_BeginOutputAttribute(node.id * 100 + 1, 1); gui.igText("MSG OUT"); gui.imnodes_EndOutputAttribute()
    
    local status_text = node.is_processing and "PROCESSING" or (node.error_state and "ERROR" or "IDLE")
    local status_col = node.is_processing and {1, 1, 0, 1} or (node.error_state and {1, 0, 0, 1} or {0, 1, 0, 0.5})
    gui.igTextColored(ffi.new("ImVec4_c", status_col), "STATUS: " .. status_text)
    if node.messages and #node.messages > 0 then
        local latest = node.messages[#node.messages].data
        gui.igTextColored(ffi.new("ImVec4_c", {0.7, 0.7, 1.0, 1.0}), "OUT: " .. ( #latest > 30 and latest:sub(1, 27) .. "..." or latest))
    end
    if node.expanded then
        gui.igSeparator(); gui.igPushItemWidth(150 * M.zoom)
        if node.type == "objective" then ensure_buffer(node, "goal", "", 256); gui.igInputText("Goal", node.config.goal, 256, 0, nil, nil)
        elseif node.type == "trigger" then if gui.igButton("Inject Pulse", ffi.new("ImVec2_c", {120 * M.zoom, 20 * M.zoom})) then M.execute_node(node, "pulse_" .. os.time()) end
        elseif node.type == "agent" then 
            ensure_buffer(node, "model", "gemini", 256); ensure_buffer(node, "prompt", "", 256)
            gui.igInputText("Model", node.config.model, 256, 0, nil, nil); gui.igInputText("Prompt", node.config.prompt, 256, 0, nil, nil)
        elseif node.type == "transform" then 
            ensure_buffer(node, "expression", "return input", 2048)
            gui.igInputText("Expr", node.config.expression, 2048, 0, nil, nil)
        end
        gui.igPopItemWidth()
    end
    gui.imnodes_EndNode(); gui.igPopID()
    if node.is_processing then gui.imnodes_PopColorStyle() end
    if active_age < 1.0 then gui.imnodes_PopColorStyle() end
end

function M.rgba_to_u32(r, g, b, a)
    local ur, ug, ub, ua = math.floor(math.min(1,math.max(0,r))*255), math.floor(math.min(1,math.max(0,g))*255), math.floor(math.min(1,math.max(0,b))*255), math.floor(math.min(1,math.max(0,a))*255)
    return bit.bor(bit.lshift(ua, 24), bit.lshift(ub, 16), bit.lshift(ug, 8), ur)
end

function M.update()
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local w, h = ffi.new("int[1]"), ffi.new("int[1]"); sdl.SDL_GetWindowSizeInPixels(_G._SDL_WINDOW, w, h)
    if w[0] ~= sw.extent.width or h[0] ~= sw.extent.height then sw:cleanup(); sw = swapchain.new(vulkan.get_instance(), vulkan.get_physical_device(), device, _G._SDL_WINDOW) return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end
    if M.auto_pulse then
        local now = os.clock()
        if now - M.heartbeat_last_time > M.heartbeat_interval then
            if M.node_map[1] then M.execute_node(M.node_map[1], "heartbeat_" .. os.time()) end
            M.heartbeat_last_time = now
        end
    end
    M.do_auto_layout()
    imgui.new_frame(); local gui = imgui.gui
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {0, 0}), 0, ffi.new("ImVec2_c", {0, 0})); gui.igSetNextWindowSize(gui.igGetIO_Nil().DisplaySize, 0)
    if gui.igBegin("🌙 MoonCrust Kernel Graph", nil, 43 + 1024 + 128) then
        gui.igBeginChild_Str("GraphSpace", ffi.new("ImVec2_c", {gui.igGetContentRegionAvail().x - 400, 0}), true, 0)
            gui.imnodes_BeginNodeEditor(); for _, node in ipairs(M.nodes) do M.draw_node(node, false) end
            for _, link in ipairs(M.links) do gui.imnodes_Link(link.id, link.start * 100 + 1, link.end_node * 100) end
            gui.imnodes_EndNodeEditor()
        gui.igEndChild(); gui.igSameLine(0, -1); gui.igBeginGroup()
            gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 1, 1}), "--- GRAPH HEALTH ---")
            gui.igText("Nodes: " .. #M.nodes); gui.igText("Links: " .. #M.links); gui.igText("Steps: " .. M.total_executions)
            local pAuto = ffi.new("bool[1]", {M.auto_layout}); if gui.igCheckbox("Auto Layout", pAuto) then M.auto_layout = pAuto[0] end
            local pPulse = ffi.new("bool[1]", {M.auto_pulse}); if gui.igCheckbox("Auto Pulse", pPulse) then M.auto_pulse = pPulse[0] end
            if M.auto_pulse then
                local progress = (os.clock() - M.heartbeat_last_time) / M.heartbeat_interval
                gui.igProgressBar(math.min(1.0, progress), ffi.new("ImVec2_c", {-1, 15}), "Charge")
            end
            gui.igText("Event Stream"); gui.igBeginChild_Str("Logs", ffi.new("ImVec2_c", {-1, 0}), true, 0)
            for _, log in ipairs(M.logs) do gui.igTextUnformatted(log, nil) end
            gui.igEndChild(); gui.igEndGroup(); gui.igEnd()
    end
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO; color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE; color_attach[0].clearValue.color.float32 = {0.02, 0.02, 0.03, 1.0}
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    imgui.render(cb); vk.vkCmdEndRendering(cb)
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
