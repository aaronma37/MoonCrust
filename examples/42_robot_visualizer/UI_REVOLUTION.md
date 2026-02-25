# 🚀 The UI Revolution: Headless ImGui & GPU-Native Rendering

This document defines the transition from traditional ImGui vertex-buffer rendering to a **Headless Metadata-Driven Architecture**. By moving UI rendering entirely to the GPU, we eliminate CPU-side vertex generation bottlenecks and unlock infinite flexibility for stylized, high-performance robotics dashboards.

---

## 🎯 The Vision: "Layout on CPU, Pixels on GPU"

The traditional ImGui pipeline (CPU generates thousands of vertices -> Upload to GPU -> Rasterize) is a bottleneck for high-frequency robotics visualizers. Our pivot redefines the boundary:

1.  **CPU (ImGui Headless)**: Performs layout math, calculates bounding boxes, handles widget state (hover/active), and processes text kerning/wrapping. It produces **Metadata**, not Geometry.
2.  **GPU (Vulkan Uber-Shader)**: Receives an array of `UIElement` structs. It uses **Hardware Instancing** to draw a single unit quad per widget, with a fragment shader that evaluates SDFs for perfect borders, rounding, and shadows.

---

## 🏗️ Architectural Pillars

### 1. The 64-Byte `UIElement` (The "Atomic Metadata")
Every UI widget (button, frame, plot area) is reduced to a single 64-byte packet. This size is optimized for cache-line alignment and maximum memory bandwidth during upload.

```cpp
// std430 alignment (64 bytes)
struct UIElement {
    vec2 pos;      // Top-left screen coordinates (pixels)
    vec2 size;     // Width and Height (pixels)
    vec4 color;    // Primary color (RGBA)
    vec4 clip;     // The ImGui ClipRect [min_x, min_y, max_x, max_y]
    uint type;     // Widget type (0=Frame, 1=Button, 2=Plot, etc.)
    uint flags;    // State flags (Bit 0: Hovered, Bit 1: Active)
    float rounding;// Corner radius for SDF rounding
    uint extra;    // Multi-purpose (Texture ID, Plot Index, etc.)
};
```

### 2. The Persistent Ring Buffer (Zero-Stutter Updates)
We avoid mid-frame Vulkan allocations. Instead, we use a **Persistent Mapped Ring Buffer**:
*   **Size**: Allocated for `N` frames-in-flight (usually 2 or 3).
*   **Mapping**: The buffer is mapped once at startup.
*   **Slicing**: Every frame, the CPU harvsters memcpy's the `UIElement` array into the current frame's slice using a dynamic offset.

### 3. Hardware Instancing & The Uber-Shader
We don't use a fullscreen fragment shader or compute shaders for the UI. We use the standard Graphics Pipeline:
*   **Geometry**: A single `1.0x1.0` unit quad stored in a vertex buffer.
*   **Draw Call**: `vkCmdDrawInstanced(count = total_widgets)`.
*   **Vertex Shader**: Uses `gl_InstanceIndex` to pull the `UIElement` from the SSBO. It scales the unit quad by `size` and translates it by `pos`.
*   **Fragment Shader**: A high-performance "Uber-Shader" that uses `type` to branch to specific SDF logic. It respects the `clip` rect by discarding fragments that fall outside the window's scroll area.

### 4. The Hybrid Text Strategy
Text is the only exception to the "Zero Geometry" rule. 
*   **CPU**: ImGui calculates exact character positions (x, y) and UVs for our **SDF Font Atlas**.
*   **Geometry**: We push a lightweight array of quads (4 vertices per character) to a separate vertex buffer.
*   **GPU**: A specialized text shader instances these quads, sampling the SDF atlas for mathematically perfect, anti-aliased text at any scale.

---

## 🛡️ The "Silent Killer": ClipRect
Traditional custom UI renderers often fail because they ignore the **ClipRect**. In ImGui, widgets inside scrolling windows or docking nodes must be clipped to their parent's bounds. 
Our `UIElement` struct includes the `clip` vector. The fragment shader is mathematically guaranteed to discard any pixel outside this box, ensuring that 3D LiDAR data or complex plots never "bleed" out of their designated ImGui windows.

---

## 📈 Performance & Scaling
| Metric | Traditional ImGui | MoonCrust Headless |
| :--- | :--- | :--- |
| **CPU Work** | Vertex Gen + Index Gen | **Bounds Math Only** |
| **GPU Work** | Triangle Rasterization | **SDF Evaluation (Higher Quality)** |
| **Memory Bandwidth** | High (MBs of Vertices) | **Ultra-Low (KBs of Metadata)** |
| **Flexibility** | Fixed Look-and-Feel | **Programmable Aesthetics** |

---

## 🚀 Implementation Roadmap
1.  **[ ] Hollow out `imgui.render`**: Remove the internal vertex/index generation.
2.  **[ ] The Harvester**: Implement the Lua-to-C++ loop that converts `ImDrawList` into `UIElement` packets.
3.  **[ ] UI Uber-Shader**: Write the GLSL SDF logic for the standard ImGui widget set.
4.  **[ ] Text SDF Pipeline**: Integrate the `Roboto` SDF atlas into the instanced quad renderer.
