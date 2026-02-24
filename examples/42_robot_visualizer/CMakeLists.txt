cmake_minimum_required(VERSION 3.24)
project(RobotVisualizer)

set(CMAKE_CXX_STANDARD 17)

include(FetchContent)

# 1. Fetch MCAP
message(STATUS "Fetching MCAP...")
FetchContent_Declare(
    mcap
    GIT_REPOSITORY https://github.com/foxglove/mcap.git
    GIT_TAG releases/cpp/v1.4.0
)
FetchContent_MakeAvailable(mcap)

# 2. Reuse ImGui/ImPlot/ImPlot3D sources from Example 41
set(CIMGUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimgui)
set(CIMPLOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimplot)
set(CIMPLOT3D_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../41_imgui_visualizer/cimplot3d)

# 3. Define the Bridge
add_library(robot_all SHARED
    bridge.cpp
    
    # ImGui Suite
    ${CIMGUI_DIR}/cimgui.cpp
    ${CIMGUI_DIR}/imgui/imgui.cpp
    ${CIMGUI_DIR}/imgui/imgui_draw.cpp
    ${CIMGUI_DIR}/imgui/imgui_demo.cpp
    ${CIMGUI_DIR}/imgui/imgui_widgets.cpp
    ${CIMGUI_DIR}/imgui/imgui_tables.cpp
    
    ${CIMPLOT_DIR}/cimplot.cpp
    ${CIMPLOT_DIR}/implot/implot.cpp
    ${CIMPLOT_DIR}/implot/implot_items.cpp
    ${CIMPLOT_DIR}/implot/implot_demo.cpp
    
    ${CIMPLOT3D_DIR}/cimplot3d.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_items.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_meshes.cpp
    ${CIMPLOT3D_DIR}/implot3d/implot3d_demo.cpp
)

target_include_directories(robot_all PUBLIC
    ${mcap_SOURCE_DIR}/cpp/mcap/include
    ${CIMGUI_DIR}
    ${CIMGUI_DIR}/imgui
    ${CIMPLOT_DIR}
    ${CIMPLOT_DIR}/implot
    ${CIMPLOT3D_DIR}
    ${CIMPLOT3D_DIR}/implot3d
)

target_compile_definitions(robot_all PUBLIC 
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(ZSTD REQUIRED libzstd)
pkg_check_modules(LZ4 REQUIRED liblz4)

target_link_libraries(robot_all PRIVATE
    ${ZSTD_LIBRARIES}
    ${LZ4_LIBRARIES}
)

target_include_directories(robot_all PUBLIC
    ${ZSTD_INCLUDE_DIRS}
    ${LZ4_INCLUDE_DIRS}
)

set_target_properties(robot_all PROPERTIES 
    OUTPUT_NAME "mooncrust_robot"
    PREFIX ""
)
