# 🚀 The UI Revolution: Headless ImGui & GPU-Native Rendering

This document defines the transition from traditional ImGui vertex-buffer rendering to a **Headless Metadata-Driven Architecture**. By moving UI rendering entirely to the GPU, we eliminate CPU-side vertex generation bottlenecks and unlock infinite flexibility for stylized, high-performance robotics dashboards.

---

## 🎯 The Vision: "Layout on CPU, Pixels on GPU"

The traditional ImGui pipeline (CPU generates thousands of vertices -> Upload to GPU -> Rasterize) is a bottleneck for high-frequency robotics visualizers. Our pivot redefines the boundary:

1.  **CPU (ImGui Headless)**: Performs layout math, calculates bounding boxes, handles widget state (hover/active), and processes text kerning/wrapping. It produces **Metadata**, not Geometry.
2.  **GPU (Vulkan Uber-Shader)**: Receives an array of `UIElement` structs. It uses **Hardware Instancing** to draw a single unit quad per widget, with a fragment shader that evaluates SDFs for perfect borders, rounding, and shadows.

---

## 🏗️ Architectural Pillars

### 1. The 64-Byte "Masterpiece" Structs
To ensure perfect alignment with Vulkan `std430` layout rules and maximum cache-line efficiency, all metadata packets are standardized to exactly 64 bytes.

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
    uint padding[4]; 
};

struct TextInstance {
    vec2 pos;      // Character position
    vec2 size;     // Character size
    vec2 uv;       // Font atlas start
    vec2 uv_size;  // Font atlas delta
    vec4 clip;     // The ImGui ClipRect
    uint color;    // Packed RGBA8
    uint padding[3];
};
```

### 2. The Persistent Ring Buffer (Zero-Stutter Updates)
We avoid mid-frame Vulkan allocations. Instead, we use a **Persistent Mapped Ring Buffer**:
*   **Capacity**: 10,000 UI Elements and 20,000 Text Instances per frame.
*   **Double Buffering**: Two slices (Frame 0, Frame 1) indexed via dynamic bindless descriptors (60-63).
*   **Efficiency**: CPU performs a single `memcpy` per frame; GPU reads directly from host-visible VRAM.

### 3. Hardware Instancing & The Uber-Shader
We use the standard Graphics Pipeline for maximum performance:
*   **Geometry**: A single `1.0x1.0` unit quad.
*   **Draw Call**: `vkCmdDraw(count = 4, instances = total_elements)`.
*   **Vertex Shader**: Uses `gl_InstanceIndex` to pull metadata. It maps (0,0) to (-1,-1) and (W,H) to (1,1) in NDC.
*   **Fragment Shader**: Evaluates SDFs for rounding and anti-aliasing. Uses the `flat` qualifier to ensure widget types and flags don't interpolate across pixels.

### 4. The Hybrid Text Strategy
Text leverages ImGui's layout engine but uses our custom GPU renderer:
*   **Harvester**: Iterates through the ImGui `DrawList`, extracting character quads.
*   **Heuristic**: Uses the font atlas `white_uv` pixel coordinates to distinguish actual characters from solid UI widgets.
*   **Rasterized Sampling**: Samples the MoonCrust font atlas (Binding 1, Index 0) with a specialized alpha-channel shader.

---

## 🛡️ The "Silent Killer": ClipRect
Every UI element and text character carries its parent window's `ClipRect`. The fragment shader performs a per-pixel discard if `gl_FragCoord` falls outside these bounds. This ensures 3D data and scrolling lists never "bleed" across the dashboard.

---

## 🚀 Accomplishments
- [x] **Headless Bridge**: ImGui functions (igButton, igBegin, etc.) wrapped to harvest metadata.
- [x] **Zero-Copy Pipeline**: No CPU vertex generation or heavy memory movement.
- [x] **Instanced Text**: Full words and sentences rendered via GPU instances.
- [x] **SDF Aesthetic**: Rounded corners and anti-aliased widgets integrated.

---

## 📈 Next Steps
1.  **[ ] Telemetry Compositing**: Map the LiDAR and Plot data textures into the UI "Apertures" (Type 2 widgets).
2.  **[ ] Dynamic Themeing**: Expose the Uber-shader constants to Lua for real-time dashboard styling.
3.  **[ ] SDF Font Atlas**: Generate a true SDF atlas for infinite-resolution text zooming.
