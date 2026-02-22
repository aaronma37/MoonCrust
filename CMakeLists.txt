cmake_minimum_required(VERSION 3.24)
project(MoonCrust)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)
include(ExternalProject)

# 1. Vulkan Headers
message(STATUS "Fetching Vulkan-Headers...")
FetchContent_Declare(
    VulkanHeaders
    URL https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.4.304.tar.gz
)
FetchContent_MakeAvailable(VulkanHeaders)

# 2. Volk (Dynamic Vulkan Loader)
message(STATUS "Fetching volk...")
FetchContent_Declare(
    volk
    URL https://github.com/zeux/volk/archive/refs/heads/master.tar.gz
)
FetchContent_MakeAvailable(volk)

# 3. SDL3
message(STATUS "Fetching SDL3...")
FetchContent_Declare(
    SDL3
    URL https://github.com/libsdl-org/SDL/archive/refs/tags/release-3.2.0.tar.gz
)
set(SDL_SHARED ON CACHE BOOL "" FORCE)
set(SDL_STATIC OFF CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(SDL_AUDIO ON CACHE BOOL "" FORCE)
set(SDL_RENDER OFF CACHE BOOL "" FORCE)
set(SDL_JOYSTICK OFF CACHE BOOL "" FORCE)
set(SDL_HAPTIC OFF CACHE BOOL "" FORCE)
set(SDL_HIDAPI OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(SDL3)

# 4. LuaJIT (Official Repository via ExternalProject)
message(STATUS "Fetching and building official LuaJIT...")
set(LUAJIT_PREFIX ${CMAKE_BINARY_DIR}/luajit)
set(LUAJIT_SOURCE_DIR ${CMAKE_BINARY_DIR}/luajit-src)
set(LUAJIT_INSTALL_DIR ${CMAKE_BINARY_DIR}/luajit-install)

ExternalProject_Add(luajit_project
    URL https://github.com/LuaJIT/LuaJIT/archive/refs/heads/v2.1.tar.gz
    SOURCE_DIR ${LUAJIT_SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND make -C ${LUAJIT_SOURCE_DIR} -j$(nproc)
    INSTALL_COMMAND make -C ${LUAJIT_SOURCE_DIR} install PREFIX=${LUAJIT_INSTALL_DIR}
    BUILD_IN_SOURCE 1
)

# Setup variables for MoonCrust to use LuaJIT
set(LUAJIT_INCLUDE_DIR ${LUAJIT_INSTALL_DIR}/include/luajit-2.1)
set(LUAJIT_LIBRARY ${LUAJIT_INSTALL_DIR}/lib/libluajit-5.1.so)

add_executable(mooncrust src/main.cpp)
add_dependencies(mooncrust luajit_project)

# Export symbols for LuaJIT FFI
set_target_properties(mooncrust PROPERTIES 
    ENABLE_EXPORTS ON
    CMAKE_ENABLE_EXPORTS ON
)

if(UNIX AND NOT APPLE)
    # On Linux, we need -rdynamic to ensure LuaJIT can see the symbols
    target_link_options(mooncrust PRIVATE "-rdynamic")
endif()

target_link_libraries(mooncrust 
    PRIVATE 
    volk 
    SDL3::SDL3-shared
    ${LUAJIT_LIBRARY}
)

target_compile_definitions(mooncrust PRIVATE VK_NO_PROTOTYPES)

target_include_directories(mooncrust PRIVATE 
    ${VulkanHeaders_SOURCE_DIR}/include
    ${LUAJIT_INCLUDE_DIR}
)

if(UNIX AND NOT APPLE)
    target_link_libraries(mooncrust PRIVATE dl pthread)
endif()
