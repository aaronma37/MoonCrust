local ffi = require("ffi")
require("examples.42_robot_visualizer.types")
local bit = require("bit")
local panels = require("examples.42_robot_visualizer.ui.panels")
local playback = require("examples.42_robot_visualizer.playback")
local robot = require("mc.robot")
local decoder = require("examples.42_robot_visualizer.decoder")
local icons = require("examples.42_robot_visualizer.ui.icons")

local v4_val = ffi.new("ImVec4_c", {0.2, 0.8, 1, 1})
local v2_zero = ffi.new("ImVec2_c", {0, 0})
local v2_table = ffi.new("ImVec2_c", {0, 250})
local v2_full = ffi.new("ImVec2_c", {-1, -1})
local plot_spec = ffi.new("ImPlotSpec_c", { Stride = 4 })
local scratch_chars = ffi.new("char[1024]")

-- Helper for selecting a stream
local function open_topic_picker(gui, on_select)
    local items = {}
    for _, ch in ipairs(playback.channels) do
        table.insert(items, { name = ch.topic, data = ch })
    end
    _G._OPEN_PICKER("Select Topic", items, on_select)
end

panels.register("pretty_viewer", "Pretty Message Viewer", function(gui, node_id, params)
    if not panels.states[node_id] then
        panels.states[node_id] = { selected_ch = nil, filter = ffi.new("char[128]"), schema_fields = nil, last_schema_id = -1, facet_synced = false }
    end
    local p_state = panels.states[node_id]
    
    local requested_topic = params and params.topic_name
    local channels = playback.channels or {}
    
    -- Initial sync with facet (only once or if facet changes)
    if requested_topic and not p_state.facet_synced then
        for _, ch in ipairs(channels) do
            if ch.topic == requested_topic then
                p_state.selected_ch = ch
                p_state.facet_synced = true
                break
            end
        end
    end
    
    -- Check if current selection still exists in the current file
    local current_exists = false
    if p_state.selected_ch then
        for _, ch in ipairs(channels) do
            if ch.id == p_state.selected_ch.id then
                current_exists = true
                break
            end
        end
    end
    
    local display_name = p_state.selected_ch and p_state.selected_ch.topic or (requested_topic and (requested_topic .. " [MISSING]") or "Select Topic...")
    
    gui.igSetNextItemWidth(-1)
    if gui.igBeginCombo("##TopicSelector", icons.SEARCH .. "  " .. display_name, 0) then
        gui.igInputText("##Search", p_state.filter, 128, 0, nil, nil)
        local q = ffi.string(p_state.filter):lower()
        
        for _, ch in ipairs(channels) do
            if q == "" or ch.topic:lower():find(q, 1, true) then
                local selected = (p_state.selected_ch ~= nil) and (ch.id == p_state.selected_ch.id)
                if gui.igSelectable_Bool(ch.topic, selected, 0, ffi.new("ImVec2_c", {0,0})) then
                    p_state.selected_ch = ch
                    p_state.schema_fields = nil -- Force re-parse
                    p_state.facet_synced = true -- Manual selection also counts as synced
                    gui.igCloseCurrentPopup()
                end
            end
        end
        gui.igEndCombo()
    end
    
    if not current_exists and requested_topic then
        gui.igTextColored(ffi.new("ImVec4_c", {1, 0.2, 0.2, 1}), icons.XMARK .. " Target topic '%s' not found.", requested_topic)
    end
    
    if current_exists and p_state.selected_ch then
        local ch = p_state.selected_ch
        local buf = playback.message_buffers[ch.id]
        
        -- Auto-parse schema once
        if not p_state.schema_fields then
            local raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id)
            if raw ~= nil then
                p_state.schema_fields = decoder.parse_schema(ffi.string(raw))
            end
        end

        if buf and buf.size > 0 then
            if gui.igTreeNode_Str(icons.LIST .. " Metadata") then 
                gui.igText("Topic: %s", ch.topic)
                gui.igText("Type: %s", ch.schema)
                gui.igText("Size: %d bytes", buf.size)
                
                local schema_raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id)
                if schema_raw ~= nil then
                    if gui.igTreeNode_Str(icons.GEAR .. " Schema Definition") then
                        gui.igTextWrapped(ffi.string(schema_raw))
                        gui.igTreePop()
                    end
                end
                
                gui.igTreePop() 
            end
            
            -- AUTO-VALUES SECTION
            if p_state.schema_fields then
                if gui.igTreeNode_Str(icons.CHART .. " Live Values") then
                    local vals = decoder.decode(buf.data, p_state.schema_fields)
                    if vals then
                        if gui.igBeginTable("ValuesTable", 2, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), v2_zero, 0) then
                            gui.igTableSetupColumn("Field", 0, 0, 0)
                            gui.igTableSetupColumn("Value", 0, 0, 0)
                            gui.igTableHeadersRow()
                            for _, v in ipairs(vals) do
                                gui.igTableNextRow(0, 0)
                                gui.igTableNextColumn(); gui.igText("%s", v.name)
                                gui.igTableNextColumn(); gui.igText(v.fmt, v.value)
                            end
                            gui.igEndTable()
                        end
                    end
                    gui.igTreePop()
                end
            end

            if ch.topic == "lidar" then
                if gui.igTreeNode_Str(icons.EYE .. " PointCloud2 Table") then
                    if gui.igBeginTable("PtsTable", 4, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), v2_table, 0) then
                        gui.igTableSetupColumn("Idx", 0, 0, 0)
                        gui.igTableSetupColumn("X", 0, 0, 0)
                        gui.igTableSetupColumn("Y", 0, 0, 0)
                        gui.igTableSetupColumn("Z", 0, 0, 0)
                        gui.igTableHeadersRow()
                        local f = ffi.cast("float*", buf.data)
                        for i=0, 49 do 
                            gui.igTableNextRow(0, 0)
                            gui.igTableNextColumn(); gui.igText(tostring(i))
                            gui.igTableNextColumn(); gui.igText(string.format("%.3f", f[i*3]))
                            gui.igTableNextColumn(); gui.igText(string.format("%.3f", f[i*3+1]))
                            gui.igTableNextColumn(); gui.igText(string.format("%.3f", f[i*3+2]))
                        end
                        gui.igEndTable()
                    end
                    gui.igTreePop()
                end
            elseif ch.topic == "pose" then
                local p = ffi.cast("Pose*", buf.data)
                gui.igTextColored(v4_val, icons.LOCATION .. string.format(" Position: (%.3f, %.3f, %.3f)", p.x, p.y, p.z))
                gui.igTextColored(v4_val, icons.LOCATION .. string.format(" Orientation (Yaw): %.3f rad", p.yaw))
            elseif buf.size >= 4 then 
                gui.igTextColored(v4_val, icons.CHART .. string.format(" Numeric Value: %.4f", ffi.cast("float*", buf.data)[0])) 
            end
        else 
            gui.igTextDisabled("(No data received yet)") 
        end
    end
end)

panels.register("plotter", "Topic Plotter", function(gui, node_id, params)
    if not panels.states[node_id] then
        panels.states[node_id] = { selected_ch = nil, filter = ffi.new("char[128]"), field_name = nil, schema_fields = nil, facet_synced = false }
    end
    local p_state = panels.states[node_id]
    
    local requested_topic = params and params.topic_name
    local requested_field = params and params.field_name
    local channels = playback.channels or {}
    
    -- 1. Sync Topic with facet
    if requested_topic and not p_state.facet_synced then
        for _, ch in ipairs(channels) do
            if ch.topic == requested_topic then
                p_state.selected_ch = ch
                p_state.schema_fields = nil -- Reset schema cache
                p_state.facet_synced = true
                break
            end
        end
    end
    
    -- 2. Sync Field with facet
    if requested_field and not p_state.field_name then
        p_state.field_name = requested_field
    end
    
    -- Topic Selector
    local current_topic = p_state.selected_ch and p_state.selected_ch.topic or "Select Topic..."
    gui.igSetNextItemWidth(gui.igGetContentRegionAvail().x * 0.5)
    if gui.igBeginCombo("##PlotTopic", icons.SEARCH .. "  " .. current_topic, 0) then
        gui.igInputText("##Search", p_state.filter, 128, 0, nil, nil)
        local q = ffi.string(p_state.filter):lower()
        for _, ch in ipairs(channels) do
            if q == "" or ch.topic:lower():find(q, 1, true) then
                if gui.igSelectable_Bool(ch.topic, p_state.selected_ch and ch.id == p_state.selected_ch.id, 0, ffi.new("ImVec2_c", {0,0})) then
                    p_state.selected_ch = ch
                    p_state.schema_fields = nil
                    p_state.facet_synced = true
                end
            end
        end
        gui.igEndCombo()
    end
    
    gui.igSameLine(0, 5)
    
    -- Field Selector
    if p_state.selected_ch then
        if not p_state.schema_fields then
            local raw = robot.lib.mcap_get_schema_content(playback.bridge, p_state.selected_ch.id)
            if raw ~= nil then p_state.schema_fields = decoder.parse_schema(ffi.string(raw)) end
        end
        
        local current_field = p_state.field_name or "Select Field..."
        gui.igSetNextItemWidth(-1)
        if gui.igBeginCombo("##PlotField", icons.LIST .. "  " .. current_field, 0) then
            if p_state.schema_fields then
                for _, f in ipairs(p_state.schema_fields) do
                    if gui.igSelectable_Bool(f.name, p_state.field_name == f.name, 0, ffi.new("ImVec2_c", {0,0})) then
                        p_state.field_name = f.name
                    end
                end
            end
            gui.igEndCombo()
        end
    end
    
    if p_state.selected_ch and p_state.field_name then
        local target_offset = -1
        local is_double = false
        if p_state.schema_fields then
            for _, f in ipairs(p_state.schema_fields) do
                if f.name == p_state.field_name then 
                    target_offset = f.offset
                    is_double = (f.type == "float64" or f.type == "double")
                    break 
                end
            end
        end
        
        if target_offset ~= -1 then
            local h = playback.request_field_history(p_state.selected_ch.id, target_offset, is_double)
            
            gui.igSameLine(0, 5)
            if gui.igButton("Fit", ffi.new("ImVec2_c", {40, 0})) then
                p_state.should_fit = true
            end

            if h and h.count > 0 then
                local label = string.format("%s: %s", p_state.selected_ch.topic, p_state.field_name)
                if gui.ImPlot_BeginPlot(label, ffi.new("ImVec2_c", {-1, -1}), 0) then
                    -- Explicitly setup each axis to ensure they are enabled
                    gui.ImPlot_SetupAxis(0, "Sample", 0) -- X Axis (ImAxis_X1)
                    gui.ImPlot_SetupAxis(1, "Value", 0)  -- Y Axis (ImAxis_Y1)
                    
                    -- Auto-fit logic: 1 = Always (Fit now), 2 = Once (Default)
                    local cond = p_state.should_fit and 1 or 2
                    gui.ImPlot_SetupAxisLimits(0, 0, 1000, cond)
                    gui.ImPlot_SetupAxisLimits(1, -1, 1, cond)
                    p_state.should_fit = false
                    
                    local spec = ffi.new("ImPlotSpec_c", {Stride=4})
                    gui.ImPlot_PlotLine_FloatPtrInt(p_state.field_name, h.data, h.count, 1.0, 0.0, spec)
                    gui.ImPlot_EndPlot()
                end
            else
                gui.igTextDisabled("(No data for this field)")
            end
        end
    end
end)

panels.register("topics", "Topic List", function(gui, node_id)
    if gui.igButton(icons.FOLDER .. " Dump All Schemas to Terminal", ffi.new("ImVec2_c", {-1, 25})) then
        print("\n" .. string.rep("=", 80))
        print("MCAP SCHEMA DUMP")
        print(string.rep("=", 80))
        if playback.channels then
            for _, ch in ipairs(playback.channels) do
                print(string.format("\n[ TOPIC: %s ]", ch.topic))
                print(string.format("  Schema Name: %s", ch.schema))
                print(string.format("  Encoding:    %s", ch.encoding))
                local raw = robot.lib.mcap_get_schema_content(playback.bridge, ch.id)
                if raw ~= nil then
                    print("  Definition:")
                    print(ffi.string(raw))
                else
                    print("  (No schema definition found for this channel)")
                end
                print(string.rep("-", 40))
            end
        else
            print("No file loaded.")
        end
        print(string.rep("=", 80) .. "\n")
    end

    gui.igText(icons.LIST .. " Discovered Topics")
    gui.igSeparator()
    if gui.igBeginTable("TopicTable", 3, bit.bor(panels.Flags.TableBorders, panels.Flags.TableResizable), v2_zero, 0) then
        gui.igTableSetupColumn("Topic", 0, 0, 0)
        gui.igTableSetupColumn("Type", 0, 0, 0)
        gui.igTableSetupColumn("ID", 0, 0, 0)
        gui.igTableHeadersRow()
        for _, ch in ipairs(playback.channels) do
            gui.igTableNextRow(0, 0)
            gui.igTableNextColumn(); gui.igText("%s", ch.topic)
            gui.igTableNextColumn(); gui.igText("%s", ch.schema)
            gui.igTableNextColumn(); gui.igText("%d", ch.id)
        end
        gui.igEndTable()
    end
end)
