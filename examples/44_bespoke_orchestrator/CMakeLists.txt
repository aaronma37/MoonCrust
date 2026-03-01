cmake_minimum_required(VERSION 3.24)
project(OrchestratorDashboard)

set(CMAKE_CXX_STANDARD 17)

include(FetchContent)

# 1. Fetch all dependencies (C++ Libraries and C Wrappers)
message(STATUS "Fetching ImGui Suite dependencies...")
FetchContent_Declare(cimgui GIT_REPOSITORY https://github.com/cimgui/cimgui.git GIT_TAG master GIT_SUBMODULES_RECURSE ON)
FetchContent_Declare(cimplot GIT_REPOSITORY https://github.com/cimgui/cimplot.git GIT_TAG master GIT_SUBMODULES_RECURSE ON)
FetchContent_Declare(cimplot3d GIT_REPOSITORY https://github.com/cimgui/cimplot3d.git GIT_TAG master GIT_SUBMODULES_RECURSE ON)
FetchContent_Declare(imnodes GIT_REPOSITORY https://github.com/Nelarius/imnodes.git GIT_TAG master)
FetchContent_Declare(cimnodes GIT_REPOSITORY https://github.com/cimgui/cimnodes.git GIT_TAG master)

FetchContent_MakeAvailable(cimgui cimplot cimplot3d imnodes cimnodes)

# 2. Define the Dashboard Shared Library
add_library(orchestrator_all SHARED
    bridge.cpp
    
    # ImGui Core
    ${cimgui_SOURCE_DIR}/cimgui.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_draw.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_demo.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_widgets.cpp
    ${cimgui_SOURCE_DIR}/imgui/imgui_tables.cpp
    
    # ImPlot Suite
    ${cimplot_SOURCE_DIR}/cimplot.cpp
    ${cimplot_SOURCE_DIR}/implot/implot.cpp
    ${cimplot_SOURCE_DIR}/implot/implot_items.cpp
    ${cimplot_SOURCE_DIR}/implot/implot_demo.cpp
    
    ${cimplot3d_SOURCE_DIR}/cimplot3d.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_items.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_meshes.cpp
    ${cimplot3d_SOURCE_DIR}/implot3d/implot3d_demo.cpp

    # imnodes Suite
    ${cimnodes_SOURCE_DIR}/cimnodes.cpp
    ${imnodes_SOURCE_DIR}/imnodes.cpp
)

target_include_directories(orchestrator_all PUBLIC
    ${cimgui_SOURCE_DIR}
    ${cimgui_SOURCE_DIR}/imgui
    ${cimplot_SOURCE_DIR}
    ${cimplot_SOURCE_DIR}/implot
    ${cimplot3d_SOURCE_DIR}
    ${cimplot3d_SOURCE_DIR}/implot3d
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
