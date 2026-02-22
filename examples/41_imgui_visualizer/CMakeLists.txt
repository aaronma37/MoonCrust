cmake_minimum_required(VERSION 3.24)
project(ImGuiVisualizer)

set(CMAKE_CXX_STANDARD 17)

# 1. cimgui
set(cimgui_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cimgui)
# 2. cimplot
set(cimplot_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cimplot)
# 3. cimplot3d
set(cimplot3d_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cimplot3d)

add_library(imgui_all SHARED
    ${cimgui_SOURCE_DIR}/cimgui.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_draw.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_demo.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_widgets.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_tables.cpp
    
    ${cimplot_SOURCE_DIR}/cimplot.cpp
    ${cimplot_SOURCE_DIR}/implot/implot.cpp
    ${cimplot_SOURCE_DIR}/implot/implot_items.cpp
    ${cimplot_SOURCE_DIR}/implot/implot_demo.cpp
    
    ${cimplot3d_SOURCE_DIR}/cimplot3d.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_items.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_meshes.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_demo.cpp
)

target_include_directories(imgui_all PUBLIC
    ${cimgui_SOURCE_DIR}
    ${cimgui_SOURCE_DIR}/imgui
    ${cimplot_SOURCE_DIR}
    ${cimplot_SOURCE_DIR}/implot
    ${cimplot3d_SOURCE_DIR}
    ${cimplot3d_SOURCE_DIR}/implot3d
)

target_compile_definitions(imgui_all PUBLIC 
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS
)

set_target_properties(imgui_all PROPERTIES 
    OUTPUT_NAME "mooncrust_imgui"
    PREFIX ""
)
