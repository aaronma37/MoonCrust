# 🏗️ MoonCrust Robotics Architecture: GPU-Native Pipeline

This document defines the architectural "North Star" for Example 42. The goal is to maximize throughput by ensuring data flows from **Disk to Pixel** with zero CPU-side deserialization or string allocation.

## 🎯 The Mission: Outperforming Rerun
To be faster than Rust-based tools like Rerun, we cannot simply optimize CPU code. We must eliminate the CPU from the data mainline entirely. In this architecture, the CPU stops being a **Translator** and becomes an **Orchestrator**.

---

## 🛠️ The Two-Phase Evolution

### Phase 1: Hybrid Bootstrap (Current State)
*   **Lidar**: Direct-to-GPU parsing via `parser.comp`. (Zero-Copy).
*   **Pose/Telemetry**: Decoded in Lua via FFI, converted to strings, and handed to standard ImGui.
*   **Bottleneck**: Lua string allocation and CPU-side iteration for metadata.

### Phase 2: GPU-Driven Intelligence (Target State)
*   **Lua as "Director"**: Lua manages window layout, input, and high-level topic selection. It tells the GPU *where* a window is and *which* data topic is bound to it.
*   **GLSL as "Performer"**: Shaders read raw binary (CDR) and generate visual geometry (Plots, Text, 3D Labels) directly into the GPU framebuffer.
*   **Zero-Copy**: Raw bytes from the MCAP bridge are mapped to Host-Visible VRAM and never leave the GPU.

---

## 🛰️ Core Architectural Pillars

### 1. The "Callback Hijack" (Hollowing out ImGui)
We use **Dear ImGui** strictly for window management (borders, splits, buttons). 
*   We use `ImDrawList::AddCallback` to pause the ImGui renderer.
*   We inject a custom Vulkan pipeline to draw complex data (Plots/Tables) directly into the "hole" left by ImGui.
*   **Benefit**: Massive data sets never touch ImGui vertex buffers or CPU-side rendering logic.

### 2. Parameterized GPU Kernels
Instead of writing unique shaders for every sensor, we build generic, high-performance kernels controlled via **Push Constants**:
*   `generic_plotter.comp`: Takes a buffer handle and a byte-offset. It maps 100k points to window pixels, calculating min/max per-pixel column in parallel.
*   `text_grid.comp`: Converts binary numbers (float/int) to character quads inside the shader. No strings are ever created in Lua.
*   `tf_resolver.comp`: Solves the entire kinematic Transform Tree (TF) on the GPU, allowing millions of points to be re-projected every frame.

### 3. Alignment-Perfect Memory
*   **Shared Silicon Alignment**: Using LuaJIT FFI, the Lua structs, C++ bridge, and GLSL storage buffers must match the **ROS2 CDR (DDS)** standard perfectly.
*   **Strict 8-Byte Boundaries**: Ensuring `double` and `float64` values are read from the exact memory offset to prevent data drift.

---

## 📈 Performance Comparison (Theoretical)

| Feature | Web-Based (Foxglove) | Rust-Based (Rerun) | MoonCrust (GPU-Native) |
| :--- | :--- | :--- | :--- |
| **Data Path** | JSON/Protobuf Deserialization | Rust Struct Deserialization | **Zero-Copy Memory Map** |
| **UI Rendering** | Browser/DOM Layout | egui (CPU-based geometry) | **GPU-Compute Geometry** |
| **String Cost** | High (GC pressure) | Moderate (Memory alloc) | **Zero (Shader-based ftoa)** |
| **Throughput** | ~50MB/s | ~2GB/s | **~10GB/s+ (GPU Bandwidth)** |

---

## 🚀 Next Implementation Steps
1.  **GPU-Native Plotter**: Implement a compute shader that replaces `ImPlot` for high-frequency topics.
2.  **Shader-based `ftoa`**: Implement a character-generation shader to render the "Live Values" table without string overhead.
3.  **TF Buffer**: Move the robot pose transform into a global GPU state buffer.
