cmake_minimum_required(VERSION 3.24)
project(OrchestratorDashboard)

set(CMAKE_CXX_STANDARD 17)

include(FetchContent)

# 1. Fetch imnodes (C++ Library)
message(STATUS "Fetching imnodes...")
FetchContent_Declare(
    imnodes
    GIT_REPOSITORY https://github.com/Nelarius/imnodes.git
    GIT_TAG master
)

# 2. Fetch cimnodes (C Wrapper)
message(STATUS "Fetching cimnodes...")
FetchContent_Declare(
    cimnodes
    GIT_REPOSITORY https://github.com/cimgui/cimnodes.git
    GIT_TAG master
)

# Manually populate to avoid add_subdirectory
FetchContent_GetProperties(imnodes)
if(NOT imnodes_POPULATED)
    FetchContent_Populate(imnodes)
endif()

FetchContent_GetProperties(cimnodes)
if(NOT cimnodes_POPULATED)
    FetchContent_Populate(cimnodes)
endif()

# 3. Reuse ImGui Suite from Example 41
set(CIMGUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimgui)
set(CIMPLOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimplot)
set(CIMPLOT3D_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimplot3d)

# 4. Define the Dashboard Shared Library
add_library(orchestrator_all SHARED
    bridge.cpp
    
    # ImGui Core
    ${CIMGUI_DIR}/cimgui.cpp
    ${CIMGUI_DIR}/imgui/imgui.cpp
    ${CIMGUI_DIR}/imgui/imgui_draw.cpp
    ${CIMGUI_DIR}/imgui/imgui_demo.cpp
    ${CIMGUI_DIR}/imgui/imgui_widgets.cpp
    ${CIMGUI_DIR}/imgui/imgui_tables.cpp
    
    # ImPlot Suite
    ${CIMPLOT_DIR}/cimplot.cpp
    ${CIMPLOT_DIR}/implot/implot.cpp
    ${CIMPLOT_DIR}/implot/implot_items.cpp
    ${CIMPLOT_DIR}/implot/implot_demo.cpp
    
    ${CIMPLOT3D_DIR}/cimplot3d.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_items.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_meshes.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_demo.cpp

    # imnodes Suite (Fetched)
    ${cimnodes_SOURCE_DIR}/cimnodes.cpp
    ${imnodes_SOURCE_DIR}/imnodes.cpp
)

target_include_directories(orchestrator_all PUBLIC
    ${CIMGUI_DIR}
    ${CIMGUI_DIR}/imgui
    ${CIMPLOT_DIR}
    ${CIMPLOT_DIR}/implot
    ${CIMPLOT3D_DIR}
    ${CIMPLOT3D_DIR}/implot3d
    ${imnodes_SOURCE_DIR}
    ${cimnodes_SOURCE_DIR}
)

target_compile_definitions(orchestrator_all PUBLIC 
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    IMGUI_DEFINE_ENUMS_AND_STRUCTS
    IMNODES_NAMESPACE=imnodes
)

set_target_properties(orchestrator_all PROPERTIES 
    OUTPUT_NAME "mooncrust_orchestrator"
    PREFIX ""
)
