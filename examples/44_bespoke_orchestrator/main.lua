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
    void orchestrator_dummy_callback(const ImDrawList* parent_list, const ImDrawCmd* cmd);
]]
local bespoke_lib = ffi.load(_G.IMGUI_LIB_PATH)

-- Custom orchestrator state
local M = { 
    agents = {},
    telemetry = { concurrency = ffi.new("float[100]"), latency = ffi.new("float[100]"), ptr = 0 },
    logs = {}, auto_scroll = true, last_packet_time = 0,
    zoom = 1.0,
    nodes = {
        { id = 1, name = "Trigger: Webhook", color = {0.2, 0.5, 0.9, 1}, expanded = true, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} },
        { id = 2, name = "Transform: JSON", color = {0.9, 0.6, 0.1, 1}, expanded = true, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} },
        { id = 3, name = "LLM: Classify", color = {0.6, 0.2, 0.9, 1}, expanded = true, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} },
        { id = 4, name = "LLM: Summarize", color = {0.6, 0.2, 0.9, 1}, expanded = false, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} },
        { id = 5, name = "Action: Slack", color = {0.1, 0.8, 0.4, 1}, expanded = true, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} },
    },
    links = {
        { id = 1, start = 1, end_node = 2, type = "data" },
        { id = 2, start = 2, end_node = 3, type = "logic" },
        { id = 3, start = 2, end_node = 4, type = "logic" },
        { id = 4, start = 3, end_node = 5, type = "action" },
        { id = 5, start = 4, end_node = 5, type = "action" },
    },
    node_map = {},
    next_node_id = 10, next_link_id = 10,
}

local device, queue, graphics_family, sw
local image_available_sem, frame_fence, cb
local udp_socket
local bg_pipe_layout, bg_pipe

ffi.cdef[[ typedef struct BgPC { float time; float width; float height; } BgPC; ]]

function M.init()
    print("Example 44: Bespoke Orchestrator Dashboard (Vulkan + ImNodes)")
    local instance, pd = vulkan.get_instance(), vulkan.get_physical_device()
    device = vulkan.get_device(); queue, graphics_family = vulkan.get_queue()
    sdl.SDL_SetWindowFullscreen(_G._SDL_WINDOW, true); sdl.SDL_Delay(100)
    sw = swapchain.new(instance, pd, device, _G._SDL_WINDOW)
    
    local pc_range = ffi.new("VkPushConstantRange[1]", {{ stageFlags = bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), offset = 0, size = ffi.sizeof("BgPC") }})
    bg_pipe_layout = pipeline.create_layout(device, {}, pc_range)
    local f_vert = io.open("examples/44_bespoke_orchestrator/shaders/bg.vert.spv", "rb")
    local f_frag = io.open("examples/44_bespoke_orchestrator/shaders/bg.frag.spv", "rb")
    bg_pipe = pipeline.create_graphics_pipeline(device, bg_pipe_layout, shader.create_module(device, f_vert:read("*all")), shader.create_module(device, f_frag:read("*all")), { topology = vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, blend_enable = false })
    f_vert:close(); f_frag:close()
    
    imgui.init(); M.nodes_ctx = imgui.gui.imnodes_CreateContext(); imgui.gui.imnodes_StyleColorsDark(nil)
    imgui.gui.imnodes_GetIO().AltMouseButton = 2 
    for _, n in ipairs(M.nodes) do M.node_map[n.id] = n end

    local pool = command.create_pool(device, graphics_family); cb = command.allocate_buffers(device, pool, 1)[1]
    local pF = ffi.new("VkFence[1]"); vk.vkCreateFence(device, ffi.new("VkFenceCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO, flags=vk.VK_FENCE_CREATE_SIGNALED_BIT }), nil, pF); frame_fence = pF[0]
    local pSem = ffi.new("VkSemaphore[1]"); vk.vkCreateSemaphore(device, ffi.new("VkSemaphoreCreateInfo", { sType=vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO }), nil, pSem); image_available_sem = pSem[0]
    pcall(function() udp_socket = require("mc.socket").udp_listen("127.0.0.1", 5555) end)
end

function M.rgba_to_u32(r, g, b, a)
    local ur, ug, ub, ua = math.floor(math.min(1,math.max(0,r))*255), math.floor(math.min(1,math.max(0,g))*255), math.floor(math.min(1,math.max(0,b))*255), math.floor(math.min(1,math.max(0,a))*255)
    return bit.bor(bit.lshift(ua, 24), bit.lshift(ub, 16), bit.lshift(ug, 8), ur)
end

function M.on_imgui_callback(cb, func_ptr, data_ptr)
    local renderer = require("imgui.renderer")
    if tonumber(ffi.cast("uintptr_t", data_ptr)) == 1 then
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, renderer.additive_pipeline)
    else
        vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, renderer.pipeline)
    end
end

function M.draw_glow_wire(draw_list, p1, p2, r, g, b, zoom)
    local gui = imgui.gui
    local dx = math.abs(p2.x - p1.x)
    local offset = math.min(150 * zoom, math.max(50 * zoom, dx * 0.5))
    local cp1 = ffi.new("ImVec2_c", { p1.x + offset, p1.y })
    local cp2 = ffi.new("ImVec2_c", { p2.x - offset, p2.y })
    local pulse = 0.8 + math.sin(os.clock() * 4) * 0.2

    local steps = 12
    for i = 1, steps do
        local t = i / steps
        local thickness = (2.0 + (1.0 - t)^2 * 23.0) * zoom
        local alpha = 0.01 + (t * t) * 0.12
        gui.ImDrawList_PathClear(draw_list)
        gui.ImDrawList_PathLineTo(draw_list, p1)
        gui.ImDrawList_PathBezierCubicCurveTo(draw_list, cp1, cp2, p2, 48)
        gui.ImDrawList_PathStroke(draw_list, M.rgba_to_u32(r, g, b, alpha * pulse), 0, thickness)
    end
    
    gui.ImDrawList_PathClear(draw_list)
    gui.ImDrawList_PathLineTo(draw_list, p1)
    gui.ImDrawList_PathBezierCubicCurveTo(draw_list, cp1, cp2, p2, 48)
    gui.ImDrawList_PathStroke(draw_list, M.rgba_to_u32(r + 0.3, g + 0.3, b + 0.3, 0.8), 0, 2.5 * zoom)

    gui.ImDrawList_PathClear(draw_list)
    gui.ImDrawList_PathLineTo(draw_list, p1)
    gui.ImDrawList_PathBezierCubicCurveTo(draw_list, cp1, cp2, p2, 48)
    gui.ImDrawList_PathStroke(draw_list, M.rgba_to_u32(1, 1, 1, 1.0), 0, 1.0 * zoom)
end

function M.handle_node_collisions()
    local gui = imgui.gui
    local min_dist = 250 * M.zoom
    for i=1, #M.nodes do
        for j=i+1, #M.nodes do
            local n1, n2 = M.nodes[i], M.nodes[j]
            local p1, p2 = gui.imnodes_GetNodeGridSpacePos(n1.id), gui.imnodes_GetNodeGridSpacePos(n2.id)
            local dx, dy = p2.x - p1.x, p2.y - p1.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < min_dist then
                if dist < 1 then dist = 1; dx = 1 end
                local force = (min_dist - dist) * 0.05
                local ox, oy = (dx / dist) * force, (dy / dist) * force
                gui.imnodes_SetNodeGridSpacePos(n1.id, ffi.new("ImVec2_c", { p1.x - ox, p1.y - oy }))
                gui.imnodes_SetNodeGridSpacePos(n2.id, ffi.new("ImVec2_c", { p2.x + ox, p2.y + oy }))
            end
        end
    end
end

function M.update()
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
                M.last_packet_time = os.clock(); M.telemetry.ptr = (M.telemetry.ptr + 1) % 100
                M.telemetry.concurrency[M.telemetry.ptr] = telemetry.concurrency; M.telemetry.latency[M.telemetry.ptr] = telemetry.latency_ms
                M.agents = telemetry.agents
                for _, log in ipairs(telemetry.logs) do table.insert(M.logs, log); if #M.logs > 100 then table.remove(M.logs, 1) end end
            end
        end
    end

    imgui.new_frame(); local gui = imgui.gui
    gui.igSetNextWindowPos(ffi.new("ImVec2_c", {0, 0}), 0, ffi.new("ImVec2_c", {0, 0})); gui.igSetNextWindowSize(gui.igGetIO_Nil().DisplaySize, 0)
    
    if gui.igBegin("🌙 MoonCrust Bespoke Orchestrator", nil, 43 + 1024 + 128) then
        if gui.igBeginMenuBar() then
            if gui.igBeginMenu("File", true) then 
                if gui.igMenuItem_Bool("Exit Fullscreen", "ESC", false, true) then sdl.SDL_SetWindowFullscreen(_G._SDL_WINDOW, false) end
                if gui.igMenuItem_Bool("Quit", "Alt+F4", false, true) then os.exit() end
                gui.igEndMenu() 
            end
            gui.igEndMenuBar()
        end

        gui.igColumns(4, "stats", false); gui.igText("CONCURRENCY"); gui.igTextColored(ffi.new("ImVec4_c", {0, 1, 0, 1}), "%.0f agents", M.telemetry.concurrency[M.telemetry.ptr]); gui.igNextColumn()
        gui.igText("LATENCY (P99)"); gui.igTextColored(ffi.new("ImVec4_c", {1, 0.8, 0, 1}), "%.1f ms", M.telemetry.latency[M.telemetry.ptr]); gui.igNextColumn()
        gui.igText("BACKEND"); gui.igTextColored(ffi.new("ImVec4_c", {0, 0.8, 1, 1}), "127.0.0.1:5555"); gui.igNextColumn()
        local is_live = (os.clock() - M.last_packet_time) < 1.0
        gui.igText("STATUS"); if is_live then gui.igTextColored(ffi.new("ImVec4_c", {0.2, 1, 0.2, 1}), "LIVE") else gui.igTextColored(ffi.new("ImVec4_c", {1, 0.8, 0, 1}), "MOCK") end
        gui.igNextColumn(); gui.igColumns(1, nil, false); gui.igSeparator()

        gui.igBeginChild_Str("GraphSpace", ffi.new("ImVec2_c", {gui.igGetContentRegionAvail().x - 400, 0}), true, 0)
            if gui.igIsWindowHovered(0) then
                local io = gui.igGetIO_Nil()
                M.zoom = math.max(0.3, math.min(2.0, M.zoom + io.MouseWheel * 0.05))
                if gui.igIsMouseClicked_Bool(1, false) then gui.igOpenPopup_Str("GraphContextMenu", 0) end
            end
            if gui.igBeginPopup("GraphContextMenu", 0) then
                if gui.igMenuItem_Bool("Add Agent Node", nil, false, true) then
                    local nid = M.next_node_id; M.next_node_id = nid + 1
                    local n = { id = nid, name = "Agent: " .. nid, color = {math.random(), math.random(), math.random(), 1}, expanded = true, pin_in = {x=0,y=0}, pin_out = {x=0,y=0} }
                    table.insert(M.nodes, n); M.node_map[nid] = n
                end
                gui.igEndPopup()
            end

            gui.imnodes_PushStyleVar_Float(gui.ImNodesStyleVar_GridSpacing, 24.0 * M.zoom)
            gui.imnodes_PushStyleVar_Float(gui.ImNodesStyleVar_PinCircleRadius, 5.0 * M.zoom)
            gui.imnodes_PushStyleVar_Float(gui.ImNodesStyleVar_NodeCornerRounding, 12.0 * M.zoom)

            gui.imnodes_BeginNodeEditor()
            for _, node in ipairs(M.nodes) do
                gui.igPushID_Int(node.id); gui.imnodes_BeginNode(node.id); gui.imnodes_BeginNodeTitleBar()
                if gui.igArrowButton("##collapse", node.expanded and gui.ImGuiDir_Down or gui.ImGuiDir_Right) then node.expanded = not node.expanded end
                gui.igSameLine(0, 5); gui.igTextUnformatted(node.name, nil); gui.imnodes_EndNodeTitleBar()
                
                -- FORCE ABSOLUTE PIN LAYOUT
                local start_cursor = gui.igGetCursorPos()
                
                -- IN PORT (Far Left)
                gui.imnodes_BeginInputAttribute(node.id * 100, 1)
                gui.igDummy(ffi.new("ImVec2_c", {16 * M.zoom, 16 * M.zoom}))
                local minI, maxI = gui.igGetItemRectMin(), gui.igGetItemRectMax()
                node.pin_in = { x = minI.x - 2, y = (minI.y + maxI.y) * 0.5 }
                gui.imnodes_EndInputAttribute()
                
                -- OUT PORT (Far Right)
                gui.igSetCursorPos(ffi.new("ImVec2_c", { start_cursor.x + 150 * M.zoom, start_cursor.y }))
                gui.imnodes_BeginOutputAttribute(node.id * 100 + 1, 1)
                gui.igDummy(ffi.new("ImVec2_c", {16 * M.zoom, 16 * M.zoom}))
                local minO, maxO = gui.igGetItemRectMin(), gui.igGetItemRectMax()
                node.pin_out = { x = maxO.x + 2, y = (minO.y + maxO.y) * 0.5 }
                gui.imnodes_EndOutputAttribute()
                
                if node.expanded then
                    gui.igSetCursorPos(ffi.new("ImVec2_c", { start_cursor.x, start_cursor.y + 25 * M.zoom }))
                    gui.igSeparator()
                    gui.igProgressBar(math.random(), ffi.new("ImVec2_c", {160 * M.zoom, 15 * M.zoom}), "")
                end
                gui.imnodes_EndNode(); gui.igPopID()
            end
            
            local dl = gui.igGetWindowDrawList()
            gui.ImDrawList_AddCallback(dl, bespoke_lib.orchestrator_dummy_callback, ffi.cast("void*", 1))
            for _, link in ipairs(M.links) do
                local n1 = M.node_map[link.start]; local n2 = M.node_map[link.end_node]
                if n1 and n2 and n1.pin_out.x ~= 0 then
                    local r, g, b = 0.2, 0.7, 1.0
                    if link.type == "logic" then r, g, b = 0.8, 0.4, 1.0 elseif link.type == "action" then r, g, b = 0.4, 1.0, 0.6 end
                    M.draw_glow_wire(dl, ffi.new("ImVec2_c", n1.pin_out), ffi.new("ImVec2_c", n2.pin_in), r, g, b, M.zoom)
                end
            end
            gui.ImDrawList_AddCallback(dl, bespoke_lib.orchestrator_dummy_callback, ffi.cast("void*", 0))

            gui.imnodes_EndNodeEditor()
            gui.imnodes_PopStyleVar(3)

            local pan = gui.imnodes_EditorContextGetPanning(); local limit = 5000
            if pan.x < -limit or pan.x > limit or pan.y < -limit or pan.y > limit then
                pan.x = math.max(-limit, math.min(limit, pan.x)); pan.y = math.max(-limit, math.min(limit, pan.y))
                gui.imnodes_EditorContextResetPanning(pan)
            end
            M.handle_node_collisions()
        gui.igEndChild(); gui.igSameLine(0, -1); gui.igBeginGroup()
            if gui.ImPlot_BeginPlot("Real-time Concurrency", ffi.new("ImVec2_c", {-1, 200}), 0) then
                gui.ImPlot_SetupAxis(0, "", 8); gui.ImPlot_SetupAxis(1, "", 0); gui.ImPlot_SetupAxisLimits(1, 0, 1200, 2)
                gui.ImPlot_PlotLine_FloatPtrInt("Agents", M.telemetry.concurrency, 100, 1.0, 0, ffi.new("ImPlotSpec_c")); gui.ImPlot_EndPlot()
            end
            if gui.ImPlot_BeginPlot("System Latency", ffi.new("ImVec2_c", {-1, 200}), 0) then
                gui.ImPlot_SetupAxis(0, "", 8); gui.ImPlot_SetupAxis(1, "", 0); gui.ImPlot_SetupAxisLimits(1, 0, 100, 2)
                gui.ImPlot_PlotLine_FloatPtrInt("ms", M.telemetry.latency, 100, 1.0, 0, ffi.new("ImPlotSpec_c")); gui.ImPlot_EndPlot()
            end
            gui.igText("Event Stream"); gui.igBeginChild_Str("Logs", ffi.new("ImVec2_c", {-1, 0}), true, 0)
            for _, log in ipairs(M.logs) do gui.igTextUnformatted(log, nil) end
            if M.auto_scroll then gui.igSetScrollHereY(1.0) end
            gui.igEndChild()
        gui.igEndGroup(); gui.igEnd()
    end

    vk.vkResetCommandBuffer(cb, 0); vk.vkBeginCommandBuffer(cb, ffi.new("VkCommandBufferBeginInfo", { sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO }))
    local color_attach = ffi.new("VkRenderingAttachmentInfo[1]")
    color_attach[0].sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO; color_attach[0].imageView = ffi.cast("VkImageView", sw.views[img_idx]); color_attach[0].imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL; color_attach[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR; color_attach[0].storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE; color_attach[0].clearValue.color.float32 = {0.02, 0.02, 0.03, 1.0}
    vk.vkCmdBeginRendering(cb, ffi.new("VkRenderingInfo", { sType=vk.VK_STRUCTURE_TYPE_RENDERING_INFO, renderArea={extent=sw.extent}, layerCount=1, colorAttachmentCount=1, pColorAttachments=color_attach }))
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, bg_pipe)
    vk.vkCmdPushConstants(cb, bg_pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 0, ffi.sizeof("BgPC"), ffi.new("BgPC", { time = os.clock(), width = sw.extent.width, height = sw.extent.height }))
    vk.vkCmdDraw(cb, 3, 1, 0, 0)
    imgui.on_callback = M.on_imgui_callback; imgui.render(cb)
    vk.vkCmdEndRendering(cb)
    local bar = ffi.new("VkImageMemoryBarrier[1]", {{ sType=vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER, oldLayout=vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, newLayout=vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, image=ffi.cast("VkImage", sw.images[img_idx]), subresourceRange={ aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT, levelCount = 1, layerCount = 1 }, dstAccessMask=0 }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nil, 0, nil, 1, bar); vk.vkEndCommandBuffer(cb)
    vk.vkQueueSubmit(queue, 1, ffi.new("VkSubmitInfo", { sType=vk.VK_STRUCTURE_TYPE_SUBMIT_INFO, waitSemaphoreCount=1, pWaitSemaphores=ffi.new("VkSemaphore[1]", {image_available_sem}), pWaitDstStageMask=ffi.new("VkPipelineStageFlags[1]", {vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT}), commandBufferCount=1, pCommandBuffers=ffi.new("VkCommandBuffer[1]", {cb}), signalSemaphoreCount=1, pSignalSemaphores=ffi.new("VkSemaphore[1]", {sw.semaphores[img_idx]}) }), frame_fence)
    sw:present(queue, img_idx, sw.semaphores[img_idx])
end

return M
