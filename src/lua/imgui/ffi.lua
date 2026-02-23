local ffi = require("ffi")

-- Minimal ImGui FFI for MoonCrust
ffi.cdef[[
    typedef struct ImVec2_c { float x, y; } ImVec2_c;
    typedef struct ImVec4_c { float x, y, z, w; } ImVec4_c;
    typedef struct ImRect_c { ImVec2_c Min, Max; } ImRect_c;
    typedef unsigned short ImDrawIdx;
    typedef unsigned int ImGuiID;
    typedef void* ImTextureID;
    typedef unsigned char ImU8;
    typedef unsigned short ImU16;
    typedef unsigned int ImU32;
    typedef unsigned long long ImU64;
    typedef signed int ImS32;
    typedef signed long long ImS64;
    typedef float ImWchar16;
    typedef unsigned int ImWchar32;
    typedef ImWchar16 ImWchar;
    
    typedef int ImGuiWindowFlags;
    typedef int ImGuiChildFlags;
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

    // Functions
    void* igCreateContext(void* shared_font_atlas);
    void igDestroyContext(void* ctx);
    ImGuiIO* igGetIO_Nil(void);
    
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
    
    void igShowDemoWindow(bool* p_open);
    bool igBegin(const char* name, bool* p_open, ImGuiWindowFlags flags);
    void igEnd(void);
    void igText(const char* fmt, ...);
    void igTextColored(const ImVec4_c col, const char* fmt, ...);
    bool igCheckbox(const char* label, bool* v);
    bool igButton(const char* label, const ImVec2_c size);
    void igSeparator(void);
    bool igIsItemHovered(int flags);
    void igBeginTooltip(void);
    void igEndTooltip(void);

    // Window Info & Cursor
    ImVec2_c igGetWindowPos(void);
    ImVec2_c igGetWindowSize(void);
    ImVec2_c igGetCursorScreenPos(void);
    ImVec2_c igGetContentRegionAvail(void);
    void igDummy(const ImVec2_c size);
    
    // Child Windows
    bool igBeginChild_Str(const char* str_id, const ImVec2_c size, bool border, ImGuiWindowFlags flags);
    void igEndChild(void);

    // Font Atlas
    void igImFontAtlasBuildMain(ImFontAtlas* atlas);
    void ImTextureData_SetTexID(ImTextureData* self, ImTextureID tex_id);

    // DrawList
    void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* userdata, size_t userdata_size);

    // ImPlot (Minimal)
    void* ImPlot_CreateContext(void);
    void ImPlot_DestroyContext(void* ctx);
    bool ImPlot_BeginPlot(const char* title_id, const ImVec2_c size, ImPlotFlags flags);
    void ImPlot_EndPlot(void);
    void ImPlot_PlotLine_FloatPtrInt(const char* label_id, const float* values, int count, double xscale, double x0, const ImPlotSpec_c spec);
    ImVec2_c ImPlot_GetPlotPos(void);
    ImVec2_c ImPlot_GetPlotSize(void);
    
    // ImPlot3D (Minimal)
    void* ImPlot3D_CreateContext(void);
    void ImPlot3D_DestroyContext(void* ctx);
    bool ImPlot3D_BeginPlot(const char* title_id, const ImVec2_c size, ImPlot3DFlags flags);
    void ImPlot3D_EndPlot(void);
    void ImPlot3D_PlotLine_FloatPtr(const char* label_id, const float* xs, const float* ys, const float* zs, int count, const ImPlot3DSpec_c spec);
]]

local lib_path = _G.IMGUI_LIB_PATH or "examples/41_imgui_visualizer/build/mooncrust_imgui.so"
local M = ffi.load(lib_path)
return M
