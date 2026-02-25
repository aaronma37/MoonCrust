local ffi = require("ffi")

-- Specialized types for the Robot Visualizer
ffi.cdef[[
    typedef struct LineVertex { float x, y, z; float r, g, b, a; } LineVertex;
    typedef struct Pose { float x, y, z, yaw; } Pose;
    typedef struct ParserPC { uint32_t in_buf_idx; uint32_t in_offset_u32; uint32_t out_buf_idx; uint32_t count; uint32_t in_stride_u32; uint32_t in_pos_offset_u32; } ParserPC;
    typedef struct RenderPC { float view_proj[16]; uint32_t buf_idx; float point_size; float viewport_size[2]; float pose_offset[4]; } RenderPC;
    typedef struct PlotPC { uint32_t gtb_idx, slot_offset, msg_size, head_idx, field_offset, history_count, is_double; float range_min, range_max; uint32_t padding; float view_min[2], view_max[2], uScale[2], uTranslate[2]; } PlotPC;
    typedef struct LidarCallbackData { float x, y, w, h; } LidarCallbackData;
    typedef struct PlotCallbackData { uint32_t ch_id, field_offset, is_double; float range_min, range_max; float x, y, w, h; } PlotCallbackData;
    
    typedef int ImGuiAxis;
    typedef struct ImDrawList ImDrawList;
    typedef void (*ImDrawCallback)(const ImDrawList* parent_list, const void* draw_cmd);

    // Functions not present in the core MoonCrust imgui/implot bindings
    void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* userdata, size_t userdata_size);
    ImDrawList* igGetWindowDrawList(void);
    
    bool igSliderFloat(const char* label, float* v, float v_min, float v_max, const char* format, int flags);
    void igSetNextWindowPos(const ImVec2_c pos, int cond, const ImVec2_c pivot);
    void igSetNextWindowSize(const ImVec2_c size, int cond);
    bool igIsWindowHovered(int flags);
    bool igIsWindowFocused(int flags);
    void igSameLine(float offset_from_start_x, float spacing);
    bool igInputText(const char* label, char* buf, size_t buf_size, int flags, void* callback, void* user_data);
    void igSetKeyboardFocusHere(int offset);
    bool igSelectable_Bool(const char* label, bool selected, int flags, const ImVec2_c size);
    void igOpenPopup_Str(const char* str_id, int popup_flags);
    bool igBeginPopupModal(const char* name, bool* p_open, int flags);
    void igEndPopup(void);
    void igCloseCurrentPopup(void);
    bool igIsItemClicked(int mouse_button);
    bool igIsKeyPressed_Bool(int key, bool repeat);
    void igSetNextWindowFocus(void);
    void igSeparatorText(const char* label);
    bool igBeginChild_Str(const char* str_id, const ImVec2_c size, bool border, ImGuiChildFlags flags);
    void igEndChild(void);
    void igTextWrapped(const char* fmt, ...);
    void igTextDisabled(const char* fmt, ...);
    bool igTreeNode_Str(const char* label);
    void igTreePop(void);
    bool igBeginTable(const char* str_id, int column, int flags, const ImVec2_c outer_size, float inner_width);
    void igEndTable(void);
    void igTableNextRow(int row_flags, float min_row_height);
    bool igTableNextColumn(void);
    void igTableSetupColumn(const char* label, int flags, float init_width_or_weight, ImGuiID user_id);
    void igTableHeadersRow(void);
    void igSetNextItemWidth(float item_width);
    ImVec2_c igGetWindowPos(void);
    ImVec2_c igGetWindowSize(void);
    ImVec2_c igGetContentRegionAvail(void);
    void igSetCursorPos(const ImVec2_c local_pos);
    float igGetCursorPosX(void);
    float igGetCursorPosY(void);
    bool igInvisibleButton(const char* str_id, const ImVec2_c size, int flags);
    void igImage(ImTextureRef_c tex_ref, const ImVec2_c image_size, const ImVec2_c uv0, const ImVec2_c uv1);
    uint64_t SDL_GetTicks(void);
    typedef struct ImPlotPoint_c { double x, y; } ImPlotPoint_c;
    void ImPlot_SetupAxis(int axis, const char* label, int flags);
    void ImPlot_SetupAxisLimits(int axis, double v_min, double v_max, int cond);
    void ImPlot_SetupAxes(const char* x_label, const char* y_label, ImPlotFlags x_flags, ImPlotFlags y_flags);
    void ImPlot_PlotImage(const char* label_id, ImTextureRef_c tex_ref, const ImPlotPoint_c bounds_min, const ImPlotPoint_c bounds_max, const ImVec2_c uv0, const ImVec2_c uv1, const ImVec4_c tint_col, const ImPlotSpec_c spec);
]]

return {}
