local ffi = require("ffi")

-- Minimal ImGui FFI for MoonCrust
ffi.cdef[[
    typedef struct ImVec2_c { float x, y; } ImVec2_c;
    typedef struct ImVec4_c { float x, y, z, w; } ImVec4_c;
    typedef struct ImRect_c { ImVec2_c Min, Max; } ImRect_c;
    typedef unsigned short ImDrawIdx;
    typedef unsigned int ImGuiID;
    typedef unsigned long long ImTextureID;
    typedef unsigned char ImU8;
    typedef unsigned short ImU16;
    typedef unsigned int ImU32;
    typedef unsigned long long ImU64;
    typedef signed char ImS8;
    typedef signed int ImS32;
    typedef signed long long ImS64;
    typedef unsigned short ImWchar16;
    typedef unsigned int ImWchar32;
    typedef ImWchar16 ImWchar;
    
    typedef enum {
        ImGuiWindowFlags_None = 0,
        ImGuiWindowFlags_NoTitleBar = 1,
        ImGuiWindowFlags_NoResize = 2,
        ImGuiWindowFlags_NoMove = 4,
        ImGuiWindowFlags_NoScrollbar = 8,
        ImGuiWindowFlags_NoScrollWithMouse = 16,
        ImGuiWindowFlags_NoCollapse = 32,
        ImGuiWindowFlags_AlwaysAutoResize = 64,
        ImGuiWindowFlags_NoBackground = 128,
        ImGuiWindowFlags_NoSavedSettings = 256,
        ImGuiWindowFlags_NoMouseInputs = 512,
        ImGuiWindowFlags_MenuBar = 1024,
        ImGuiWindowFlags_HorizontalScrollbar = 2048,
        ImGuiWindowFlags_NoFocusOnAppearing = 4096,
        ImGuiWindowFlags_NoBringToFrontOnFocus = 8192,
        ImGuiWindowFlags_AlwaysVerticalScrollbar = 16384,
        ImGuiWindowFlags_AlwaysHorizontalScrollbar = 32768,
        ImGuiWindowFlags_NoNavInputs = 65536,
        ImGuiWindowFlags_NoNavFocus = 131072,
        ImGuiWindowFlags_UnsavedDocument = 262144,
        ImGuiWindowFlags_NoDocking = 524288,
        ImGuiWindowFlags_NoNav = 196608,
        ImGuiWindowFlags_NoDecoration = 43,
        ImGuiWindowFlags_NoInputs = 197120,
        ImGuiWindowFlags_DockNodeHost = 8388608,
        ImGuiWindowFlags_ChildWindow = 16777216,
        ImGuiWindowFlags_Tooltip = 33554432,
        ImGuiWindowFlags_Popup = 67108864,
        ImGuiWindowFlags_Modal = 134217728,
        ImGuiWindowFlags_ChildMenu = 268435456,
    } ImGuiWindowFlags_;

    typedef enum {
        ImGuiChildFlags_None = 0,
        ImGuiChildFlags_Borders = 1,
        ImGuiChildFlags_AlwaysUseWindowPadding = 2,
        ImGuiChildFlags_ResizeX = 4,
        ImGuiChildFlags_ResizeY = 8,
        ImGuiChildFlags_AutoResizeX = 16,
        ImGuiChildFlags_AutoResizeY = 32,
        ImGuiChildFlags_AlwaysAutoResize = 64,
        ImGuiChildFlags_FrameStyle = 128,
        ImGuiChildFlags_NavFlattened = 256,
    } ImGuiChildFlags_;

    typedef enum {
        ImGuiCond_None = 0,
        ImGuiCond_Always = 1,
        ImGuiCond_Once = 2,
        ImGuiCond_FirstUseEver = 4,
        ImGuiCond_Appearing = 8,
    } ImGuiCond_;

    typedef enum {
        ImGuiStyleVar_Alpha = 0,
        ImGuiStyleVar_DisabledAlpha = 1,
        ImGuiStyleVar_WindowPadding = 2,
        ImGuiStyleVar_WindowRounding = 3,
        ImGuiStyleVar_WindowBorderSize = 4,
        ImGuiStyleVar_WindowMinSize = 5,
        ImGuiStyleVar_WindowTitleAlign = 6,
        ImGuiStyleVar_ChildRounding = 7,
        ImGuiStyleVar_ChildBorderSize = 8,
        ImGuiStyleVar_PopupRounding = 9,
        ImGuiStyleVar_PopupBorderSize = 10,
        ImGuiStyleVar_FramePadding = 11,
        ImGuiStyleVar_FrameRounding = 12,
        ImGuiStyleVar_FrameBorderSize = 13,
        ImGuiStyleVar_ItemSpacing = 14,
        ImGuiStyleVar_ItemInnerSpacing = 15,
        ImGuiStyleVar_IndentSpacing = 16,
        ImGuiStyleVar_CellPadding = 17,
        ImGuiStyleVar_ScrollbarSize = 18,
        ImGuiStyleVar_ScrollbarRounding = 19,
        ImGuiStyleVar_GrabMinSize = 20,
        ImGuiStyleVar_GrabRounding = 21,
        ImGuiStyleVar_TabRounding = 22,
        ImGuiStyleVar_ButtonTextAlign = 23,
        ImGuiStyleVar_SelectableTextAlign = 24,
    } ImGuiStyleVar_;

    typedef enum {
        ImGuiCol_Text = 0,
        ImGuiCol_TextDisabled,
        ImGuiCol_WindowBg,
        ImGuiCol_ChildBg,
        ImGuiCol_PopupBg,
        ImGuiCol_Border,
        ImGuiCol_BorderShadow,
        ImGuiCol_FrameBg,
        ImGuiCol_FrameBgHovered,
        ImGuiCol_FrameBgActive,
        ImGuiCol_TitleBg,
        ImGuiCol_TitleBgActive,
        ImGuiCol_TitleBgCollapsed,
        ImGuiCol_MenuBarBg,
        ImGuiCol_ScrollbarBg,
        ImGuiCol_ScrollbarGrab,
        ImGuiCol_ScrollbarGrabHovered,
        ImGuiCol_ScrollbarGrabActive,
        ImGuiCol_CheckMark,
        ImGuiCol_SliderGrab,
        ImGuiCol_SliderGrabActive,
        ImGuiCol_Button,
        ImGuiCol_ButtonHovered,
        ImGuiCol_ButtonActive,
        ImGuiCol_Header,
        ImGuiCol_HeaderHovered,
        ImGuiCol_HeaderActive,
        ImGuiCol_Separator,
        ImGuiCol_SeparatorHovered,
        ImGuiCol_SeparatorActive,
        ImGuiCol_ResizeGrip,
        ImGuiCol_ResizeGripHovered,
        ImGuiCol_ResizeGripActive,
        ImGuiCol_Tab,
        ImGuiCol_TabHovered,
        ImGuiCol_TabActive,
        ImGuiCol_TabUnfocused,
        ImGuiCol_TabUnfocusedActive,
        ImGuiCol_PlotLines,
        ImGuiCol_PlotLinesHovered,
        ImGuiCol_PlotHistogram,
        ImGuiCol_PlotHistogramHovered,
        ImGuiCol_TableHeaderBg,
        ImGuiCol_TableBorderStrong,
        ImGuiCol_TableBorderLight,
        ImGuiCol_TableRowBg,
        ImGuiCol_TableRowBgAlt,
        ImGuiCol_TextSelectedBg,
        ImGuiCol_DragDropTarget,
        ImGuiCol_NavHighlight,
        ImGuiCol_NavWindowingHighlight,
        ImGuiCol_NavWindowingDimBg,
        ImGuiCol_ModalWindowDimBg,
        ImGuiCol_COUNT
    } ImGuiCol_;

    typedef enum {
        ImPlotAxisFlags_None = 0,
        ImPlotAxisFlags_NoLabel = 1 << 0,
        ImPlotAxisFlags_NoGridLines = 1 << 1,
        ImPlotAxisFlags_NoTickMarks = 1 << 2,
        ImPlotAxisFlags_NoTickLabels = 1 << 3,
        ImPlotAxisFlags_LogScale = 1 << 4,
        ImPlotAxisFlags_Time = 1 << 5,
        ImPlotAxisFlags_Invert = 1 << 6,
        ImPlotAxisFlags_AutoFit = 1 << 7,
        ImPlotAxisFlags_RangeFit = 1 << 8,
        ImPlotAxisFlags_Opposite = 1 << 9,
        ImPlotAxisFlags_Foreground = 1 << 10,
    } ImPlotAxisFlags_;

    typedef enum {
        ImPlotCond_None = 0,
        ImPlotCond_Always = 1,
        ImPlotCond_Once = 2,
    } ImPlotCond_;

    typedef enum {
        ImGuiDir_None = -1,
        ImGuiDir_Left = 0,
        ImGuiDir_Right = 1,
        ImGuiDir_Up = 2,
        ImGuiDir_Down = 3,
        ImGuiDir_COUNT
    } ImGuiDir;

    typedef enum {
        ImGuiPopupFlags_None = 0,
        ImGuiPopupFlags_MouseButtonLeft = 0,
        ImGuiPopupFlags_MouseButtonRight = 1,
        ImGuiPopupFlags_MouseButtonMiddle = 2,
        ImGuiPopupFlags_MouseButtonMask_ = 0x1F,
        ImGuiPopupFlags_MouseButtonDefault_ = 1,
        ImGuiPopupFlags_NoOpenOverExistingPopup = 1 << 5,
        ImGuiPopupFlags_NoOpenOverItems = 1 << 6,
        ImGuiPopupFlags_AnyPopupId = 1 << 7,
        ImGuiPopupFlags_AnyPopupLevel = 1 << 8,
        ImGuiPopupFlags_AnyPopup = 384,
    } ImGuiPopupFlags_;

    typedef int ImGuiPopupFlags;
    typedef int ImGuiCol;
    typedef int ImGuiWindowFlags;
    typedef int ImGuiChildFlags;
    typedef int ImGuiCond;
    typedef int ImPlotFlags;
    typedef int ImPlot3DFlags;
    typedef int ImFontAtlasFlags;
    typedef int ImTextureFormat;
    typedef int ImTextureStatus;
    typedef int ImGuiConfigFlags;
    typedef int ImGuiBackendFlags;
    typedef int ImGuiKeyChord;
    typedef int ImGuiMouseSource;
    typedef int ImPlotMarker;
    typedef int ImPlot3DMarker;
    typedef int ImGuiKey;

    typedef struct ImDrawVert {
        ImVec2_c pos;
        ImVec2_c uv;
        ImU32 col;
    } ImDrawVert;

    typedef struct ImVector {
        int Size;
        int Capacity;
        void* Data;
    } ImVector;

    typedef struct ImTextureRef_c {
        void* _TexData;
        ImTextureID _TexID;
    } ImTextureRef_c;

    typedef struct ImDrawCmd {
        ImVec4_c ClipRect;
        ImTextureRef_c TexRef;
        unsigned int VtxOffset;
        unsigned int IdxOffset;
        unsigned int ElemCount;
        void* UserCallback;
        void* UserCallbackData;
        int UserCallbackDataSize;
        int UserCallbackDataOffset;
    } ImDrawCmd;

    typedef struct ImDrawList {
        ImVector CmdBuffer;
        ImVector IdxBuffer;
        ImVector VtxBuffer;
        int Flags;
        void* _Data;
    } ImDrawList;

    typedef struct ImDrawData {
        bool Valid;
        int CmdListsCount;
        int TotalIdxCount;
        int TotalVtxCount;
        ImVector CmdLists;
        ImVec2_c DisplayPos;
        ImVec2_c DisplaySize;
        ImVec2_c FramebufferScale;
        void* OwnerViewport;
        void* Textures;
    } ImDrawData;

    typedef struct ImTextureData {
        int UniqueID;
        ImTextureStatus Status;
        void* BackendUserData;
        ImTextureID TexID;
        ImTextureFormat Format;
        int Width;
        int Height;
        int BytesPerPixel;
        unsigned char* Pixels;
    } ImTextureData;

    typedef struct ImFontAtlas {
        ImFontAtlasFlags Flags;
        ImTextureFormat TexDesiredFormat;
        int TexGlyphPadding;
        int TexMinWidth;
        int TexMinHeight;
        int TexMaxWidth;
        int TexMaxHeight;
        void* UserData;
        ImTextureRef_c TexRef;
        ImTextureData* TexData;
        ImVector TexList;
        bool Locked;
        bool RendererHasTextures;
        bool TexIsBuilt;
        bool TexPixelsUseColors;
        ImVec2_c TexUvScale;
        ImVec2_c TexUvWhitePixel;
        ImVector Fonts;
        ImVector Sources;
        ImVec4_c TexUvLines[33];
        int TexNextUniqueID;
        int FontNextUniqueID;
        ImVector DrawListSharedDatas;
        void* Builder;
        void* FontLoader;
        const char* FontLoaderName;
        void* FontLoaderData;
        unsigned int FontLoaderFlags;
        int RefCount;
        void* OwnerContext;
    } ImFontAtlas;

    typedef struct ImGuiKeyData {
        bool Down;
        float DownDuration;
        float DownDurationPrev;
        float AnalogValue;
    } ImGuiKeyData;

    typedef struct ImGuiIO {
        ImGuiConfigFlags ConfigFlags;
        ImGuiBackendFlags BackendFlags;
        ImVec2_c DisplaySize;
        ImVec2_c DisplayFramebufferScale;
        float DeltaTime;
        float IniSavingRate;
        const char* IniFilename;
        const char* LogFilename;
        void* UserData;
        ImFontAtlas* Fonts;
        void* FontDefault;
        float FontGlobalScale;
        bool FontAllowUserScaling;
        bool ConfigNavSwapGamepadButtons;
        bool ConfigNavMoveSetMousePos;
        bool ConfigNavCaptureKeyboard;
        bool ConfigNavEscapeClearFocusItem;
        bool ConfigNavEscapeClearFocusWindow;
        bool ConfigNavCursorVisibleAuto;
        bool ConfigNavCursorVisibleAlways;
        bool ConfigDockingNoSplit;
        bool ConfigDockingNoDockingOver;
        bool ConfigDockingWithShift;
        bool ConfigDockingAlwaysTabBar;
        bool ConfigDockingTransparentPayload;
        bool ConfigViewportsNoAutoMerge;
        bool ConfigViewportsNoTaskBarIcon;
        bool ConfigViewportsNoDecoration;
        bool ConfigViewportsNoDefaultParent;
        bool ConfigViewportsPlatformFocusSetsImGuiFocus;
        bool ConfigDpiScaleFonts;
        bool ConfigDpiScaleViewports;
        bool MouseDrawCursor;
        bool ConfigMacOSXBehaviors;
        bool ConfigInputTrickleEventQueue;
        bool ConfigInputTextCursorBlink;
        bool ConfigInputTextEnterKeepActive;
        bool ConfigDragClickToInputText;
        bool ConfigWindowsResizeFromEdges;
        bool ConfigWindowsMoveFromTitleBarOnly;
        bool ConfigWindowsCopyContentsWithCtrlC;
        bool ConfigScrollbarScrollByPage;
        float ConfigMemoryCompactTimer;
        float MouseDoubleClickTime;
        float MouseDoubleClickMaxDist;
        float MouseDragThreshold;
        float KeyRepeatDelay;
        float KeyRepeatRate;
        bool ConfigErrorRecovery;
        bool ConfigErrorRecoveryEnableAssert;
        bool ConfigErrorRecoveryEnableDebugLog;
        bool ConfigErrorRecoveryEnableTooltip;
        bool ConfigDebugIsDebuggerPresent;
        bool ConfigDebugHighlightIdConflicts;
        bool ConfigDebugHighlightIdConflictsShowItemPicker;
        bool ConfigDebugBeginReturnValueOnce;
        bool ConfigDebugBeginReturnValueLoop;
        bool ConfigDebugIgnoreFocusLoss;
        bool ConfigDebugIniSettings;
        const char* BackendPlatformName;
        const char* BackendRendererName;
        void* BackendPlatformUserData;
        void* BackendRendererUserData;
        void* BackendLanguageUserData;
        bool WantCaptureMouse;
        bool WantCaptureKeyboard;
        bool WantTextInput;
        bool WantSetMousePos;
        bool WantSaveIniSettings;
        bool NavActive;
        bool NavVisible;
        float Framerate;
        int MetricsRenderVertices;
        int MetricsRenderIndices;
        int MetricsRenderWindows;
        int MetricsActiveWindows;
        ImVec2_c MouseDelta;
        void* Ctx;
        ImVec2_c MousePos;
        bool MouseDown[5];
        float MouseWheel;
        float MouseWheelH;
        ImGuiMouseSource MouseSource;
        ImGuiID MouseHoveredViewport;
        bool KeyCtrl;
        bool KeyShift;
        bool KeyAlt;
        bool KeySuper;
        ImGuiKeyChord KeyMods;
        ImGuiKeyData KeysData[155];
        bool WantCaptureMouseUnlessPopupClose;
        ImVec2_c MousePosPrev;
        ImVec2_c MouseClickedPos[5];
        double MouseClickedTime[5];
        bool MouseClicked[5];
        bool MouseDoubleClicked[5];
        ImU16 MouseClickedCount[5];
        ImU16 MouseClickedLastCount[5];
        bool MouseReleased[5];
        double MouseReleasedTime[5];
    } ImGuiIO;

    // ImPlot Specs
    typedef struct ImPlotSpec_c {
        ImVec4_c LineColor;
        float LineWeight;
        ImVec4_c FillColor;
        float FillAlpha;
        ImPlotMarker Marker;
        float MarkerSize;
        ImVec4_c MarkerLineColor;
        ImVec4_c MarkerFillColor;
        float Size;
        int Offset;
        int Stride;
    } ImPlotSpec_c;

    typedef struct ImPlot3DSpec_c {
        ImVec4_c LineColor;
        float LineWeight;
        ImVec4_c FillColor;
        float FillAlpha;
        ImPlot3DMarker Marker;
        float MarkerSize;
        ImVec4_c MarkerLineColor;
        ImVec4_c MarkerFillColor;
        int Offset;
        int Stride;
    } ImPlot3DSpec_c;

    typedef void (*ImDrawCallback)(const ImDrawList* parent_list, const ImDrawCmd* cmd);

    typedef struct ImGuiStyle {
        float       FontSizeBase;
        float       FontScaleMain;
        float       FontScaleDpi;
        float       Alpha;
        float       DisabledAlpha;
        ImVec2_c    WindowPadding;
        float       WindowRounding;
        float       WindowBorderSize;
        float       WindowBorderHoverPadding;
        ImVec2_c    WindowMinSize;
        ImVec2_c    WindowTitleAlign;
        int         WindowMenuButtonPosition;
        float       ChildRounding;
        float       ChildBorderSize;
        float       PopupRounding;
        float       PopupBorderSize;
        ImVec2_c    FramePadding;
        float       FrameRounding;
        float       FrameBorderSize;
        ImVec2_c    ItemSpacing;
        ImVec2_c    ItemInnerSpacing;
        ImVec2_c    CellPadding;
        ImVec2_c    TouchExtraPadding;
        float       IndentSpacing;
        float       ColumnsMinSpacing;
        float       ScrollbarSize;
        float       ScrollbarRounding;
        float       ScrollbarPadding;
        float       GrabMinSize;
        float       GrabRounding;
        float       LogSliderDeadzone;
        float       ImageRounding;
        float       ImageBorderSize;
        float       TabRounding;
        float       TabBorderSize;
        float       TabMinWidthBase;
        float       TabMinWidthShrink;
        float       TabCloseButtonMinWidthSelected;
        float       TabCloseButtonMinWidthUnselected;
        float       TabBarBorderSize;
        float       TabBarOverlineSize;
        float       TableAngledHeadersAngle;
        ImVec2_c    TableAngledHeadersTextAlign;
        int         TreeLinesFlags;
        float       TreeLinesSize;
        float       TreeLinesRounding;
        float       DragDropTargetRounding;
        float       DragDropTargetBorderSize;
        float       DragDropTargetPadding;
        float       ColorMarkerSize;
        int         ColorButtonPosition;
        ImVec2_c    ButtonTextAlign;
        ImVec2_c    SelectableTextAlign;
        float       SeparatorTextBorderSize;
        ImVec2_c    SeparatorTextAlign;
        ImVec2_c    SeparatorTextPadding;
        ImVec2_c    DisplayWindowPadding;
        ImVec2_c    DisplaySafeAreaPadding;
        bool        DockingNodeHasCloseButton;
        float       DockingSeparatorSize;
        float       MouseCursorScale;
        bool        AntiAliasedLines;
        bool        AntiAliasedLinesUseTex;
        bool        AntiAliasedFill;
        float       CurveTessellationTol;
        float       CircleTessellationMaxError;
        ImVec4_c    Colors[55];
    } ImGuiStyle;

    // Functions
    void* igCreateContext(void* shared_font_atlas);
    void igDestroyContext(void* ctx);
    ImGuiIO* igGetIO_Nil(void);
    ImGuiStyle* igGetStyle(void);
    
    // Modern Event API
    void ImGuiIO_AddKeyEvent(ImGuiIO* self, ImGuiKey key, bool down);
    void ImGuiIO_AddInputCharacter(ImGuiIO* self, unsigned int c);
    void ImGuiIO_AddMousePosEvent(ImGuiIO* self, float x, float y);
    void ImGuiIO_AddMouseButtonEvent(ImGuiIO* self, int button, bool down);
    void ImGuiIO_AddMouseWheelEvent(ImGuiIO* self, float wheel_x, float wheel_y);

    void igNewFrame(void);
    void igRender(void);
    ImDrawData* igGetDrawData(void);
    void igEndFrame(void);
    ImDrawList* igGetWindowDrawList(void);
    void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* callback_data);
    void ImDrawList_PathLineTo(ImDrawList* self, const ImVec2_c pos);
    void ImDrawList_PathBezierCubicCurveTo(ImDrawList* self, const ImVec2_c p2, const ImVec2_c p3, const ImVec2_c p4, int num_segments);
    void ImDrawList_PathStroke(ImDrawList* self, unsigned int col, int flags, float thickness);
    void ImDrawList_PathClear(ImDrawList* self);
    
    void igShowDemoWindow(bool* p_open);
    bool igBegin(const char* name, bool* p_open, ImGuiWindowFlags flags);
    void igEnd(void);
    void igText(const char* fmt, ...);
    void igTextColored(const ImVec4_c col, const char* fmt, ...);
    void igTextUnformatted(const char* text, const char* text_end);
    bool igCheckbox(const char* label, bool* v);
    bool igButton(const char* label, const ImVec2_c size);
    bool igArrowButton(const char* str_id, ImGuiDir dir);
    void igProgressBar(float fraction, const ImVec2_c size_arg, const char* overlay);
    void igSeparator(void);
    bool igIsItemHovered(int flags);
    void igBeginTooltip(void);
    void igEndTooltip(void);

    // Window Positioning
    void igSetNextWindowPos(const ImVec2_c pos, ImGuiCond cond, const ImVec2_c pivot);
    void igSetNextWindowSize(const ImVec2_c size, ImGuiCond cond);
    void igSetNextWindowBgAlpha(float alpha);

    // Window Info & Cursor
    ImVec2_c igGetWindowPos(void);
    ImVec2_c igGetWindowSize(void);
    ImVec2_c igGetCursorScreenPos(void);
    ImVec2_c igGetContentRegionAvail(void);
    void igDummy(const ImVec2_c size);
    
    // Child Windows
    bool igBeginChild_Str(const char* str_id, const ImVec2_c size, bool border, ImGuiWindowFlags flags);
    void igEndChild(void);
    void igBeginGroup(void);
    void igEndGroup(void);

    // Widgets
    bool igBeginCombo(const char* label, const char* preview_value, int flags);
    void igEndCombo(void);
    bool igSelectable_Bool(const char* label, bool selected, int flags, const ImVec2_c size);
    bool igInputText(const char* label, char* buf, size_t buf_size, int flags, void* callback, void* user_data);
    bool igTreeNode_Str(const char* label);
    void igTreePop(void);
    void igPushID_Str(const char* str_id);
    void igPushID_Int(int int_id);
    void igPopID(void);
    void igSameLine(float offset_from_start_x, float spacing_w);
    void igSetNextItemWidth(float item_width);
    void igSetKeyboardFocusHere(int offset);
    void igSetCursorPos(const ImVec2_c local_pos);
    ImVec2_c igGetCursorPos(void);
    float igGetCursorPosX(void);
    float igGetCursorPosY(void);
    bool igIsWindowHovered(int flags);
    bool igIsMouseClicked_Bool(int button, bool repeat);
    bool igInvisibleButton(const char* str_id, const ImVec2_c size, int flags);
    void igOpenPopup_Str(const char* str_id, int flags);
    bool igBeginPopupModal(const char* name, bool* p_open, int flags);
    bool igBeginPopup(const char* str_id, int flags);
    void igEndPopup(void);
    bool igBeginPopupContextWindow(const char* str_id, int flags);
    bool igBeginPopupContextItem(const char* str_id, int flags);
    bool igBeginPopupContextVoid(const char* str_id, int flags);
    void igCloseCurrentPopup(void);
    void igPushStyleColor_Vec4(int idx, const ImVec4_c col);
    void igPopStyleColor(int count);
    void igPushStyleVar_Float(int idx, float val);
    void igPushStyleVar_Vec2(int idx, const ImVec2_c val);
    void igPopStyleVar(int count);

    // Menus
    bool igBeginMenuBar(void);
    void igEndMenuBar(void);
    bool igBeginMainMenuBar(void);
    void igEndMainMenuBar(void);
    bool igBeginMenu(const char* label, bool enabled);
    void igEndMenu(void);
    bool igMenuItem_Bool(const char* label, const char* shortcut, bool selected, bool enabled);

    // Columns / Tables
    void igColumns(int count, const char* id, bool border);
    void igNextColumn(void);
    int igGetColumnIndex(void);
    float igGetColumnWidth(int column_index);
    void igSetColumnWidth(int column_index, float width);
    float igGetColumnOffset(int column_index);
    void igSetColumnOffset(int column_index, float offset_x);
    int igGetColumnsCount(void);

    // Logs / Scrolling
    void igSetScrollHereY(float center_y_ratio);
    void igSetScrollY_Float(float scroll_y);
    float igGetScrollY(void);
    float igGetScrollMaxY(void);

    // Font Atlas
    typedef struct ImFontConfig {
        char            Name[40];
        void*           FontData;
        int             FontDataSize;
        bool            FontDataOwnedByAtlas;
        bool            MergeMode;
        bool            PixelSnapH;
        ImS8            OversampleH;
        ImS8            OversampleV;
        ImWchar         EllipsisChar;
        float           SizePixels;
        const ImWchar*  GlyphRanges;
        const ImWchar*  GlyphExcludeRanges;
        ImVec2_c        GlyphOffset;
        float           GlyphMinAdvanceX;
        float           GlyphMaxAdvanceX;
        float           GlyphExtraAdvanceX;
        ImU32           FontNo;
        unsigned int    FontLoaderFlags;
        float           RasterizerMultiply;
        float           RasterizerDensity;
        float           ExtraSizeScale;
        int             Flags;
        void*           DstFont;
        void*           FontLoader;
        void*           FontLoaderData;
    } ImFontConfig;

    void igImFontAtlasBuildMain(ImFontAtlas* atlas);
    void ImTextureData_SetTexID(ImTextureData* self, ImTextureID tex_id);
    void* ImFontAtlas_AddFontFromFileTTF(ImFontAtlas* self, const char* filename, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
    const ImWchar* ImFontAtlas_GetGlyphRangesDefault(ImFontAtlas* self);
    ImFontConfig* ImFontConfig_ImFontConfig(void);

    // DrawList
    void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* userdata, size_t userdata_size);

    // ImPlot (Minimal)
    void* ImPlot_CreateContext(void);
    void ImPlot_DestroyContext(void* ctx);
    bool ImPlot_BeginPlot(const char* title_id, const ImVec2_c size, ImPlotFlags flags);
    void ImPlot_EndPlot(void);
    void ImPlot_PlotLine_FloatPtrInt(const char* label_id, const float* values, int count, double xscale, double x0, const ImPlotSpec_c spec);
    void ImPlot_SetupAxis(int axis, const char* label, int flags);
    void ImPlot_SetupAxisLimits(int axis, double v_min, double v_max, int cond);
    ImVec2_c ImPlot_GetPlotPos(void);
    ImVec2_c ImPlot_GetPlotSize(void);
    
    // ImPlot3D (Minimal)
    void* ImPlot3D_CreateContext(void);
    void ImPlot3D_DestroyContext(void* ctx);
    bool ImPlot3D_BeginPlot(const char* title_id, const ImVec2_c size, ImPlot3DFlags flags);
    void ImPlot3D_EndPlot(void);
    void ImPlot3D_PlotLine_FloatPtr(const char* label_id, const float* xs, const float* ys, const float* zs, int count, const ImPlot3DSpec_c spec);
]]

return function()
    local lib_path = _G.IMGUI_LIB_PATH or "examples/42_robot_visualizer/build/mooncrust_robot.so"
    return ffi.load(lib_path)
end
