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
    metrics = {}, -- Store process health
    logs = {}, auto_scroll = true, last_packet_time = 0,
    zoom = 1.0,
    show_shadow = false,
    auto_layout = false, -- DISABLED TO DEBUG CRASH
    nodes = {
        { id = 1, type = "trigger", name = "Webhook", color = {0.2, 0.5, 0.9, 1}, expanded = true, messages = {} },
        { id = 2, type = "transform", name = "Parser", color = {0.9, 0.6, 0.1, 1}, expanded = true, messages = {}, config = { expression = ffi.new("char[256]", "return input") } },
        { id = 3, type = "agent", name = "Classifier", color = {0.6, 0.2, 0.9, 1}, expanded = true, config = { model = ffi.new("char[256]", "gemini"), prompt = ffi.new("char[256]", "Classify intent..."), use_memory = true, use_ltm = true }, messages = {} },
        { id = 4, type = "agent", name = "Summarizer", color = {0.6, 0.2, 0.9, 1}, expanded = false, config = { model = ffi.new("char[256]", "gemini"), prompt = ffi.new("char[256]", "Summarize this..."), use_memory = true, use_ltm = false }, messages = {} },
        { id = 5, type = "action", name = "Slack", color = {0.1, 0.8, 0.4, 1}, expanded = true, messages = {} },
    },
    links = {
        { id = 1, start = 1, end_node = 2 },
        { id = 2, start = 2, end_node = 3 },
        { id = 3, start = 2, end_node = 4 },
        { id = 4, start = 3, end_node = 5 },
        { id = 5, start = 4, end_node = 5 },
    },
    shadow_nodes = {},
    shadow_links = {},
    node_map = {},
    next_node_id = 10, next_link_id = 10,
}

local device, queue, graphics_family, sw
local image_available_sem, frame_fence, cb
local udp_socket

function M.init()
    print("[DEBUG] M.init start")
    local instance, pd = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sdl.SDL_SetWindowFullscreen(_G._SDL_WINDOW, true); sdl.SDL_Delay(100)
    sw = swapchain.new(instance, pd, device, _G._SDL_WINDOW)
    
    print("[DEBUG] Initializing ImGui")
    imgui.init(); M.nodes_ctx = imgui.gui.imnodes_CreateContext(); imgui.gui.imnodes_StyleColorsDark(nil)
    imgui.gui.imnodes_GetIO().AltMouseButton = 2 
    for _, n in ipairs(M.nodes) do M.node_map[n.id] = n end

    print("[DEBUG] Allocating Vulkan buffers")
    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pSem); image_available_sem = pSem[0]
    pcall(function() udp_socket = require("mc.socket").udp_listen("127.0.0.1", 5555) end)
    print("[DEBUG] M.init complete")
end

function M.send_command(cmd_type, payload)
    if udp_socket then
        local msg = json.encode({ type = cmd_type, payload = payload })
        udp_socket:send("127.0.0.1", 5556, msg)
    end
end

function M.serialize_graph()
    local nodes_data = {}
    for _, n in ipairs(M.nodes) do
        local sn = { id = n.id, type = n.type, name = n.name, color = n.color, expanded = n.expanded }
        if n.config then
            sn.config = {}
            for k, v in pairs(n.config) do
                if type(v) == "userdata" then
                    if ffi.istype("char[256]", v) then sn.config[k] = ffi.string(v)
                    elseif ffi.istype("int[1]", v) then sn.config[k] = v[0]
                    elseif ffi.istype("float[1]", v) then sn.config[k] = v[0]
                    else sn.config[k] = v end
                else sn.config[k] = v end
            end
        end
        table.insert(nodes_data, sn)
    end
    return { nodes = nodes_data, links = M.links }
end

function M.save_workflow(path)
    local data = M.serialize_graph()
    local f = io.open(path, "w")
    if f then f:write(json.encode(data)); f:close(); table.insert(M.logs, "[SYS] Saved workflow to " .. path) end
end

function M.load_workflow(path)
    local f = io.open(path, "r")
    if not f then return end
    local ok, data = pcall(json.decode, f:read("*a"))
    f:close()
    if not ok or not data then return end

    M.nodes = {}
    M.node_map = {}
    for _, n in ipairs(data.nodes) do
        if n.config then
            local c = n.config
            if c.prompt then c.prompt = ffi.new("char[256]", c.prompt) end
            if c.model then c.model = ffi.new("char[256]", c.model) end
            if c.expression then c.expression = ffi.new("char[256]", c.expression) end
            if c.condition then c.condition = ffi.new("char[256]", c.condition) end
            if c.file_path then c.file_path = ffi.new("char[256]", c.file_path) end
            if c.shell_cmd then c.shell_cmd = ffi.new("char[256]", c.shell_cmd) end
            if c.window_name then c.window_name = ffi.new("char[256]", c.window_name) end
            if c.value then c.value = ffi.new("char[256]", c.value) end
            if c.wait_count then c.wait_count = ffi.new("int[1]", c.wait_count) end
            if c.seconds then c.seconds = ffi.new("float[1]", c.seconds) end
        end
        n.messages = {}
        table.insert(M.nodes, n)
        M.node_map[n.id] = n
    end
    M.links = data.links or {}
    M.sync_active_graph()
    table.insert(M.logs, "[SYS] Loaded workflow from " .. path)
end

function M.sync_active_graph()
    local data = M.serialize_graph()
    M.send_command("sync_graph", data)
end

function M.do_auto_layout()
    if not M.auto_layout then return end
    -- Temporarily stripped to ensure no crash
end

function M.draw_node(node, is_shadow)
    local gui = imgui.gui
    if is_shadow then 
        gui.imnodes_PushColorStyle(gui.ImNodesCol_NodeBackground, M.rgba_to_u32(0.3, 0.3, 0.3, 0.5))
        gui.imnodes_PushColorStyle(gui.ImNodesCol_TitleBar, M.rgba_to_u32(0.4, 0.2, 0.2, 0.5)) 
    end
    
    gui.igPushID_Int(node.id); gui.imnodes_BeginNode(node.id); gui.imnodes_BeginNodeTitleBar(); gui.igTextUnformatted(node.name, nil); gui.imnodes_EndNodeTitleBar()
    gui.imnodes_BeginInputAttribute(node.id * 100, 1); gui.igText("MSG IN"); gui.imnodes_EndInputAttribute(); gui.igSameLine(0, 40 * M.zoom); gui.imnodes_BeginOutputAttribute(node.id * 100 + 1, 1); gui.igText("MSG OUT"); gui.imnodes_EndOutputAttribute()
    
    if node.expanded then
        gui.igSeparator(); local msg_count = node.messages and #node.messages or 0
        gui.igPushItemWidth(150 * M.zoom)
        if node.type == "trigger" then
            if gui.igButton("Inject Event", ffi.new("ImVec2_c", {120 * M.zoom, 20 * M.zoom})) then M.send_command("inject_event", { node_id = node.id, data = "manual_trigger_" .. os.time() }) end
        elseif node.type == "agent" then
            if node.config then
                gui.igInputText("Model", node.config.model, 256, 0, nil, nil)
                gui.igInputText("Prompt", node.config.prompt, 256, 0, nil, nil)
            end
        elseif node.type == "router" then if node.config then gui.igInputText("Condition", node.config.condition, 256, 0, nil, nil) end
        elseif node.type == "transform" then if node.config then gui.igInputText("Expr", node.config.expression, 256, 0, nil, nil) end
        elseif node.type == "join" or node.type == "buffer" then if node.config then gui.igInputInt("Count/Cap", node.config.wait_count, 1, 50, 0) end
        elseif node.type == "delay" then if node.config then gui.igInputFloat("Seconds", node.config.seconds, 0.1, 1.0, "%.1f", 0) end
        elseif node.type == "constant" then if node.config then gui.igInputText("Value", node.config.value, 256, 0, nil, nil) end
        elseif node.type == "actuator" then if node.config then gui.igInputText("File Path", node.config.file_path, 256, 0, nil, nil) end
        elseif node.type == "terminal" then if node.config then gui.igInputText("Command", node.config.shell_cmd, 256, 0, nil, nil) end
        elseif node.type == "capture" then
            if node.config then gui.igInputText("Window Name", node.config.window_name, 256, 0, nil, nil) end
            if gui.igButton("Grab Now", ffi.new("ImVec2_c", {120 * M.zoom, 20 * M.zoom})) then M.send_command("inject_event", { node_id = node.id, data = "capture_request" }) end
        end
        gui.igPopItemWidth()
        local pulse = 0.5 + math.sin(os.clock() * 10) * 0.5
        if msg_count > 0 then gui.igSameLine(0, 10); gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, pulse}), "●") end
    end
    gui.imnodes_EndNode(); gui.igPopID()
    if is_shadow then gui.imnodes_PopColorStyle(); gui.imnodes_PopColorStyle() end
end

function M.rgba_to_u32(r, g, b, a)
    local ur, ug, ub, ua = math.floor(math.min(1,math.max(0,r))*255), math.floor(math.min(1,math.max(0,g))*255), math.floor(math.min(1,math.max(0,b))*255), math.floor(math.min(1,math.max(0,a))*255)
    return bit.bor(bit.lshift(ua, 24), bit.lshift(ub, 16), bit.lshift(ug, 8), ur)
end

function M.update()
    print("[DEBUG] M.update tick start")
    vk.vkWaitForFences(device, 1, ffi.new("VkFence[1]", {frame_fence}), vk.VK_TRUE, 0xFFFFFFFFFFFFFFFFULL)
    local w, h = ffi.new("int[1]"), ffi.new("int[1]"); sdl.SDL_GetWindowSizeInPixels(_G._SDL_WINDOW, w, h)
    if w[0] ~= sw.extent.width or h[0] ~= sw.extent.height then sw:cleanup(); sw = swapchain.new(vulkan.get_instance(), vulkan.get_physical_device(), device, _G._SDL_WINDOW) return end
    vk.vkResetFences(device, 1, ffi.new("VkFence[1]", {frame_fence}))
    local img_idx = sw:acquire_next_image(image_available_sem)
    if img_idx == nil then return end

    if udp_socket then
        while true do
            local data = udp_socket:receive()
            if not data then break end
            local ok, telemetry = pcall(json.decode, data)
            if ok then
                if telemetry.type == "shadow_proposal" then
                    for _, sn in ipairs(telemetry.nodes) do
                        sn.config = sn.config or {}
                        if sn.type == "agent" then sn.config.model = ffi.new("char[256]", sn.config.model or "gemini"); sn.config.prompt = ffi.new("char[256]", sn.config.prompt or ""); sn.config.use_memory = sn.config.use_memory or false; sn.config.use_ltm = sn.config.use_ltm or false end
                        if sn.type == "router" then sn.config.condition = ffi.new("char[256]", sn.config.condition or "") end
                        if sn.type == "transform" then sn.config.expression = ffi.new("char[256]", sn.config.expression or "") end
                        if sn.type == "constant" then sn.config.value = ffi.new("char[256]", sn.config.value or "") end
                        if sn.type == "actuator" then sn.config.file_path = ffi.new("char[256]", sn.config.file_path or "") end
                        if sn.type == "terminal" then sn.config.shell_cmd = ffi.new("char[256]", sn.config.shell_cmd or "") end
                        if sn.type == "capture" then sn.config.window_name = ffi.new("char[256]", sn.config.window_name or "MoonCrust") end
                        if sn.type == "join" or sn.type == "buffer" then sn.config.wait_count = ffi.new("int[1]", sn.config.wait_count or 2) end
                        if sn.type == "delay" then sn.config.seconds = ffi.new("float[1]", sn.config.seconds or 1.0) end
                    end
                    M.shadow_nodes = telemetry.nodes; M.shadow_links = telemetry.links; M.show_shadow = true; table.insert(M.logs, "[AI] Received evolution proposal.")
                elseif telemetry.type == "node_update" then
                    local node = M.node_map[telemetry.node_id]
                    if node then node.messages = telemetry.messages end
                else
                    M.last_packet_time = os.clock(); M.telemetry.ptr = (M.telemetry.ptr + 1) % 100
                    M.telemetry.concurrency[M.telemetry.ptr] = telemetry.concurrency; M.telemetry.latency[M.telemetry.ptr] = telemetry.latency_ms
                    M.agents = telemetry.agents
                    for _, log in ipairs(telemetry.logs) do table.insert(M.logs, log); if #M.logs > 100 then table.remove(M.logs, 1) end end
                end
            end
        end
    end

    print("[DEBUG] ImGui new_frame start")
    imgui.new_frame(); local gui = imgui.gui
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {0, 0}), 0, ffi.new("ImVec2_c", {0, 0})); gui.igSetNextWindowSize(gui.igGetIO_Nil().DisplaySize, 0)
    
    if gui.igBegin("🌙 MoonCrust Bespoke Orchestrator", nil, 43 + 1024 + 128) then
        gui.igBeginChild_Str("GraphSpace", ffi.new("ImVec2_c", {gui.igGetContentRegionAvail().x - 400, 0}), true, 0)
            gui.imnodes_BeginNodeEditor()
            for _, node in ipairs(M.nodes) do M.draw_node(node, false) end
            for _, link in ipairs(M.links) do gui.imnodes_Link(link.id, link.start * 100 + 1, link.end_node * 100) end
            gui.imnodes_EndNodeEditor()
        gui.igEndChild(); gui.igSameLine(0, -1); gui.igBeginGroup()
            gui.igText("Event Stream"); gui.igBeginChild_Str("Logs", ffi.new("ImVec2_c", {-1, 0}), true, 0)
            for _, log in ipairs(M.logs) do gui.igTextUnformatted(log, nil) end
            gui.igEndChild()
        gui.igEndGroup(); gui.igEnd()
    end
    print("[DEBUG] ImGui render start")
    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]"); color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO; color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE; color_attach[0].clearValue.color.float32 = {0.02, 0.02, 0.03, 1.0}
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    imgui.render(cb); vk.vkCmdEndRendering(cb)
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence); sw:present(queue, img_idx, sw.semaphores[img_idx])
    print("[DEBUG] M.update tick end")
end

return M
