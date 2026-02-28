#include <imgui.h>
#include <imgui_internal.h>
#include <implot.h>
#include <implot_internal.h>
#include <implot3d.h>
#include <imnodes.h>

extern "C" {
#include "cimgui.h"
#include "cimplot.h"
#include "cimplot3d.h"
#include "cimnodes.h"
}

#include <iostream>

// Export C functions for LuaJIT FFI
extern "C" {

void orchestrator_init() {
    std::cout << "[Orchestrator] Initializing C++ Bridge..." << std::endl;
}

void orchestrator_draw_node_background(const ImDrawList* parent_list, const ImDrawCmd* cmd) {
    // Custom callback for shader injection (Vulkan)
}

void orchestrator_dummy_callback(const ImDrawList* parent_list, const ImDrawCmd* cmd) {
    // Just a placeholder to pass the assertion in ImGui
}

}
