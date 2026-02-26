local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local bit = require("bit")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")
local robot = require("mc.robot")
local decoder = require("examples.42_robot_visualizer.decoder")
local icons = require("examples.42_robot_visualizer.ui.icons")
local ui = require("examples.42_robot_visualizer.ui.consts")

panels.register("pretty_viewer", "Pretty Message Viewer", function(gui, node_id, params)
    if not panels.states[node_id] then
        panels.states[node_id] = { selected_ch = nil, filter = ffi.new("char[128]"), schema = nil, last_ts = 0ULL, cached_vals = {}, facet_synced = false }
    end
    local p_state = panels.states[node_id]
    local channels = playback.channels or {}
    
    if params and params.topic_name and not p_state.facet_synced then
        for _, ch in ipairs(channels) do if ch.topic == params.topic_name then p_state.selected_ch, p_state.facet_synced = ch, true break end end
    end
    
    local display_name = p_state.selected_ch and p_state.selected_ch.topic or "Select Topic..."
    gui.igSetNextItemWidth(-1)
    if gui.igBeginCombo("##TopicSelector", icons.SEARCH .. "  " .. display_name, 0) then
        gui.igInputText("##Search", p_state.filter, 128, 0, nil, nil)
        local q = ffi.string(p_state.filter):lower()
        for _, ch in ipairs(channels) do
            if q == "" or ch.topic:lower():find(q, 1, true) then
                if gui.igSelectable_Bool(ch.topic, p_state.selected_ch and ch.id == p_state.selected_ch.id, 0, ui.V2_ZERO) then
                    p_state.selected_ch, p_state.schema, p_state.facet_synced = ch, nil, true
                    p_state.cached_vals = {}
                    gui.igCloseCurrentPopup()
                end
            end
        end
        gui.igEndCombo()
    end
    
    if p_state.selected_ch then
        local ch = p_state.selected_ch
        if _G._GPU_INSPECTOR then _G._GPU_INSPECTOR.set_channel(ch) end
        
        local buf = playback.get_msg_buffer(ch.id)
        if buf and buf.size > 0 then
            if gui.igTreeNode_Str(icons.LIST .. " Metadata") then 
                gui.igText("Topic: %s", ch.topic); gui.igText("Type: %s", ch.schema); gui.igText("Size: %d bytes", buf.size)
                gui.igTreePop() 
            end

            if _G._GPU_INSPECTOR and _G._GPU_INSPECTOR.ch and _G._GPU_INSPECTOR.ch.id == ch.id then
                if gui.igTreeNode_Str(icons.CHART .. " Live Values (GPU Parsed)") then
                    gui.igTextColored(ui.V4_LIVE, "SILICON-DIRECT PIPELINE ACTIVE")
                    if gui.igBeginTable("ValueTable", 2, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), ui.V2_ZERO, 0) then
                        gui.igTableSetupColumn("Field", 0, 0, 0); gui.igTableSetupColumn("Value", 0, 0, 0); gui.igTableHeadersRow()
                        
                        local results = _G._GPU_INSPECTOR.results_ptr
                        for i, f in ipairs(_G._GPU_INSPECTOR.flattened) do
                            gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%s", f.name)
                            gui.igTableNextColumn()
                            
                            local base = (i-1) * 2
                            if f.type:find("64") or f.type == "double" then
                                local d_val = ffi.cast("double*", ffi.new("uint32_t[2]", {results[base], results[base+1]}))[0]
                                gui.igText("%.6f", d_val)
                            elseif f.type:find("float") then
                                local f_val = ffi.cast("float*", ffi.new("uint32_t[1]", results[base]))[0]
                                gui.igText("%.4f", f_val)
                            elseif f.type:find("uint") then
                                gui.igText("%u", results[base])
                            else
                                gui.igText("%d", ffi.cast("int32_t", results[base]))
                            end
                        end
                        gui.igEndTable()
                    end
                    gui.igTreePop()
                end
            end
        else gui.igTextDisabled("(No data received yet)") end
    end
end)

panels.register("plotter", "Topic Plotter", function(gui, node_id, params)
    if not panels.states[node_id] then
        panels.states[node_id] = { 
            selected_ch = nil, filter = ffi.new("char[128]"), field_name = nil, schema = nil, flattened = nil, 
            facet_synced = false, gpu_mode = true, range_min = -1.0, range_max = 1.0, 
            -- Pre-allocated callback data block (PERSISTENT ANCHOR)
            cb_data = ffi.new("PlotCallbackData"),
            p_gpu = ffi.new("bool[1]", true)
        }
    end
    local p_state = panels.states[node_id]
    local channels = playback.channels or {}
    
    if params and params.topic_name and not p_state.facet_synced then
        for _, ch in ipairs(channels) do if ch.topic == params.topic_name then p_state.selected_ch, p_state.schema, p_state.facet_synced = ch, nil, true break end end
    end
    if params and params.field_name and not p_state.field_name then p_state.field_name = params.field_name end
    
    local current_topic = p_state.selected_ch and p_state.selected_ch.topic or "Select Topic..."
    gui.igSetNextItemWidth(gui.igGetContentRegionAvail().x * 0.4)
    if gui.igBeginCombo("##PlotTopic", icons.SEARCH .. "  " .. current_topic, 0) then
        gui.igInputText("##Search", p_state.filter, 128, 0, nil, nil)
        local q = ffi.string(p_state.filter):lower()
        for _, ch in ipairs(channels) do
            if q == "" or ch.topic:lower():find(q, 1, true) then
                if gui.igSelectable_Bool(ch.topic, p_state.selected_ch and ch.id == p_state.selected_ch.id, 0, ui.V2_ZERO) then
                    p_state.selected_ch, p_state.schema, p_state.flattened, p_state.facet_synced = ch, nil, nil, true
                end
            end
        end
        gui.igEndCombo()
    end
    
    gui.igSameLine(0, 5)
    if p_state.selected_ch then
        if not p_state.schema then
            local raw = robot.lib.mcap_get_schema_content(playback.bridge, p_state.selected_ch.id)
            if raw ~= nil then p_state.schema = decoder.parse_schema(ffi.string(raw)); p_state.flattened = decoder.get_flattened_fields(p_state.schema) end
        end
        gui.igSetNextItemWidth(gui.igGetContentRegionAvail().x * 0.4)
        if gui.igBeginCombo("##PlotField", p_state.field_name or "Select Field...", 0) then
            if p_state.flattened then for _, f in ipairs(p_state.flattened) do if gui.igSelectable_Bool(f.name, p_state.field_name == f.name, 0, ui.V2_ZERO) then p_state.field_name = f.name end end end
            gui.igEndCombo()
        end
    end
    
    gui.igSameLine(0, 5)
    p_state.p_gpu[0] = p_state.gpu_mode
    if gui.igCheckbox("GPU", p_state.p_gpu) then p_state.gpu_mode = p_state.p_gpu[0] end

    if p_state.selected_ch and p_state.field_name and p_state.flattened then
        local target = nil
        for _, f in ipairs(p_state.flattened) do if f.name == p_state.field_name then target = f; break end end
        if target then
            if gui.ImPlot_BeginPlot(string.format("%s: %s", p_state.selected_ch.topic, p_state.field_name), ui.V2_FULL, 0) then
                gui.ImPlot_SetupAxis(0, "History (Time)", 0); gui.ImPlot_SetupAxis(1, "Value", 0)
                if p_state.gpu_mode then
                    local p_min, p_max = gui.ImPlot_GetPlotPos(), gui.ImPlot_GetPlotSize()
                    local d = p_state.cb_data
                    d.ch_id, d.field_offset, d.is_double = p_state.selected_ch.id, target.offset, target.is_double and 1 or 0
                    d.range_min, d.range_max, d.x, d.y, d.w, d.h = p_state.range_min, p_state.range_max, p_min.x, p_min.y, p_max.x, p_max.y
                    require("examples.42_robot_visualizer.view_3d").enqueue_plot(d)
                    gui.ImPlot_PlotImage("##gpu_plot", ffi.new("ImTextureRef_c", { _TexID = 105ULL }), ffi.new("ImPlotPoint_c", {x=0, y=p_state.range_min}), ffi.new("ImPlotPoint_c", {x=playback.HISTORY_MAX, y=p_state.range_max}), ffi.new("ImVec2_c", {0, 1}), ffi.new("ImVec2_c", {1, 0}), ui.V4_LIVE, ffi.new("ImPlotSpec_c"))
                else
                    local h = playback.request_field_history(p_state.selected_ch.id, target.offset, target.is_double)
                    if h and h.count > 0 then gui.ImPlot_PlotLine_FloatPtrInt(p_state.field_name, h.data, h.count, 1.0, 0.0, ffi.new("ImPlotSpec_c", {Stride=4})) end
                end
                gui.ImPlot_EndPlot()
            end
        end
    end
end)

panels.register("topics", "Topic List", function(gui, node_id)
    if gui.igButton(icons.FOLDER .. " Dump All Schemas to Terminal", ui.V2_BTN_FILL) then
        if playback.channels then for _, ch in ipairs(playback.channels) do local raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id); if raw then print("\n[ " .. ch.topic .. " ]\n" .. ffi.string(raw)) end end end
    end
    gui.igText(icons.LIST .. " Discovered Topics"); gui.igSeparator()
    if gui.igBeginTable("TopicTable", 3, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), ui.V2_ZERO, 0) then
        gui.igTableSetupColumn("Topic", 0, 0, 0); gui.igTableSetupColumn("Type", 0, 0, 0); gui.igTableSetupColumn("ID", 0, 0, 0); gui.igTableHeadersRow()
        for _, ch in ipairs(playback.channels) do gui.igTableNextRow(0, 0); gui.igTableNextColumn(); gui.igText("%s", ch.topic); gui.igTableNextColumn(); gui.igText("%s", ch.schema); gui.igTableNextColumn(); gui.igText("%d", ch.id) end
        gui.igEndTable()
    end
end)
