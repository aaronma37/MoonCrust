local ffi = require("ffi")

ffi.cdef[[
    typedef enum {
        ImNodesCol_NodeBackground = 0,
        ImNodesCol_NodeBackgroundHovered,
        ImNodesCol_NodeBackgroundSelected,
        ImNodesCol_NodeOutline,
        ImNodesCol_TitleBar,
        ImNodesCol_TitleBarHovered,
        ImNodesCol_TitleBarSelected,
        ImNodesCol_Link,
        ImNodesCol_LinkHovered,
        ImNodesCol_LinkSelected,
        ImNodesCol_Pin,
        ImNodesCol_PinHovered,
        ImNodesCol_BoxSelector,
        ImNodesCol_BoxSelectorOutline,
        ImNodesCol_GridBackground,
        ImNodesCol_GridLine,
        ImNodesCol_GridLinePrimary,
        ImNodesCol_MiniMapBackground,
        ImNodesCol_MiniMapBackgroundHovered,
        ImNodesCol_MiniMapOutline,
        ImNodesCol_MiniMapOutlineHovered,
        ImNodesCol_MiniMapNodeBackground,
        ImNodesCol_MiniMapNodeBackgroundHovered,
        ImNodesCol_MiniMapNodeBackgroundSelected,
        ImNodesCol_MiniMapNodeOutline,
        ImNodesCol_MiniMapLink,
        ImNodesCol_MiniMapLinkSelected,
        ImNodesCol_MiniMapCanvas,
        ImNodesCol_MiniMapCanvasOutline,
        ImNodesCol_COUNT
    } ImNodesCol;

    typedef enum {
        ImNodesStyleVar_GridSpacing,
        ImNodesStyleVar_NodeCornerRounding,
        ImNodesStyleVar_NodePadding,
        ImNodesStyleVar_NodeBorderThickness,
        ImNodesStyleVar_LinkThickness,
        ImNodesStyleVar_LinkLineSegmentsPerLength,
        ImNodesStyleVar_LinkHoverDistance,
        ImNodesStyleVar_PinCircleRadius,
        ImNodesStyleVar_PinQuadSideLength,
        ImNodesStyleVar_PinTriangleSideLength,
        ImNodesStyleVar_PinLineThickness,
        ImNodesStyleVar_PinHoverRadius,
        ImNodesStyleVar_PinOffset,
        ImNodesStyleVar_MiniMapPadding,
        ImNodesStyleVar_MiniMapOffset,
        ImNodesStyleVar_COUNT
    } ImNodesStyleVar;

    typedef int ImNodesStyleFlags;
    typedef int ImNodesPinShape;
    typedef int ImNodesAttributeFlags;

    typedef struct ImNodesStyle {
        float GridSpacing;
        float NodeCornerRounding;
        float NodePaddingX;
        float NodePaddingY;
        float NodeBorderThickness;
        float LinkThickness;
        float LinkLineSegmentsPerLength;
        float LinkHoverDistance;
        float PinCircleRadius;
        float PinQuadSideLength;
        float PinTriangleSideLength;
        float PinLineThickness;
        float PinHoverRadius;
        float PinOffset;
        unsigned int Colors[24];
        ImNodesStyleFlags Flags;
    } ImNodesStyle;

    typedef struct ImNodesConfigFlags {
        int Flags;
    } ImNodesConfigFlags;

    typedef struct ImNodesIO {
        struct { const bool* Modifier; } EmulateThreeButtonMouse;
        struct { const bool* Modifier; } LinkDetachWithModifierClick;
        struct { const bool* Modifier; } MultipleSelectModifier;
        int AltMouseButton;
        float AutoPanningSpeed;
    } ImNodesIO;

    // imnodes Functions (Corrected to imnodes_ prefix from cimnodes)
    void* imnodes_CreateContext();
    void imnodes_DestroyContext(void* context);
    void imnodes_SetCurrentContext(void* context);
    ImNodesStyle* imnodes_GetStyle();
    ImNodesIO* imnodes_GetIO();
    void imnodes_StyleColorsDark(ImNodesStyle* dest);
    
    void imnodes_PushColorStyle(ImNodesCol item, unsigned int color);
    void imnodes_PopColorStyle();
    void imnodes_PushStyleVar_Float(ImNodesStyleVar item, float value);
    void imnodes_PushStyleVar_Vec2(ImNodesStyleVar item, const ImVec2_c value);
    void imnodes_PopStyleVar(int count);

    void imnodes_BeginNodeEditor();
    void imnodes_EndNodeEditor();
    
    void imnodes_BeginNode(int id);
    void imnodes_EndNode();
    
    void imnodes_BeginNodeTitleBar();
    void imnodes_EndNodeTitleBar();
    
    void imnodes_BeginInputAttribute(int id, ImNodesPinShape shape);
    void imnodes_EndInputAttribute();
    
    void imnodes_BeginOutputAttribute(int id, ImNodesPinShape shape);
    void imnodes_EndOutputAttribute();
    
    void imnodes_Link(int id, int start_attr, int end_attr);
    
    void imnodes_SetNodeScreenSpacePos(int node_id, ImVec2_c screen_pos);
    void imnodes_SetNodeEditorSpacePos(int node_id, ImVec2_c editor_pos);
    void imnodes_SetNodeGridSpacePos(int node_id, ImVec2_c grid_pos);
    
    ImVec2_c imnodes_GetNodeEditorSpacePos(int node_id);
    ImVec2_c imnodes_GetNodeGridSpacePos(int node_id);
    
    ImVec2_c imnodes_EditorContextGetPanning();
    void imnodes_EditorContextResetPanning(const ImVec2_c pos);
    
    bool imnodes_IsEditorHovered();
    bool imnodes_IsNodeHovered(int* node_id);
    bool imnodes_IsLinkHovered(int* link_id);
    bool imnodes_IsPinHovered(int* pin_id);
    
    int imnodes_NumSelectedNodes();
    int imnodes_NumSelectedLinks();
    void imnodes_GetSelectedNodes(int* node_ids);
    void imnodes_GetSelectedLinks(int* link_ids);
]]

return {}
