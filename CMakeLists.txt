cmake_minimum_required(VERSION 3.10)
project(MoonCrust)

set(CMAKE_CXX_STANDARD 17)

# Find Vulkan
find_package(Vulkan REQUIRED)

# Find LuaJIT (Manual find because CMake's FindLua often misses LuaJIT)
find_path(LUAJIT_INCLUDE_DIR NAMES lua.hpp PATH_SUFFIXES luajit-2.1 lua5.1)
find_library(LUAJIT_LIBRARY NAMES luajit-5.1 luajit-5.1.so.2)

# Find SDL3
# In 2026, this should be standard. 
# If not found, we'll try to use a local path or environment variable.
find_package(SDL3)

if(NOT SDL3_FOUND)
    message(WARNING "SDL3 not found. Please set SDL3_DIR or install SDL3.")
endif()

include_directories(${Vulkan_INCLUDE_DIRS} ${LUAJIT_INCLUDE_DIR})

add_executable(mooncrust src/main.cpp)
set_target_properties(mooncrust PROPERTIES ENABLE_EXPORTS ON)
target_link_libraries(mooncrust ${Vulkan_LIBRARIES} ${LUAJIT_LIBRARY} SDL3::SDL3)
