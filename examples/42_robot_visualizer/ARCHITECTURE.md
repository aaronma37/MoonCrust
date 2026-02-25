# 🏗️ MoonCrust Robotics Architecture: GPU-Native Pipeline

This document defines the architectural "North Star" for Example 42. The goal is to maximize throughput by ensuring data flows from **Disk to Pixel** with zero CPU-side deserialization or string allocation.

## 🎯 The Mission: Outperforming Rerun
To be faster than Rust-based tools like Rerun, we cannot simply optimize CPU code. We must eliminate the CPU from the data mainline entirely. In this architecture, the CPU stops being a **Translator** and becomes an **Orchestrator**.

---

## 🏗️ The "Shadow Pass" Architecture (Director/Performer)

Instead of injecting Vulkan code *inside* ImGui (which is brittle), we use a decoupled pass system:

### 1. The ImGui Pass (The "Director" / Aperture)
*   **Role**: Handles window management, docking, splitting, and user input.
*   **Aperture Pattern**: ImGui defines a "hole" on the screen (a rectangle). 
*   **Coord Sync**: Lua reads the window's position and size (`igGetWindowPos()`) and stores them in a **Shadow Draw List**.
*   **Interaction**: ImGui provides the mouse hit-boxes and scroll offsets.

### 2. The MoonCrust Pass (The "Performer" / Payload)
*   **Role**: Executes the high-throughput rendering (Plots, Lidar, 3D Models, Text Kernels).
*   **Timing**: Runs **AFTER** the ImGui pass has finished its logic but **BEFORE** the final present call.
*   **Scissor Mapping**: To handle overlapping windows, we use Vulkan scissoring. If ImGui reports that only a portion of our window is visible, we apply that as a hardware-level scissor rect.
*   **Payload**: The GPU reads directly from the **Global Telemetry Buffer (GTB)** and draws directly into the framebuffer.

---

## 🛰️ Core Architectural Pillars

### 1. The Global Telemetry Buffer (GTB)
*   A 512MB pre-allocated, host-visible circular buffer.
*   The C++ bridge blits raw MCAP bytes directly into reserved channel slots.
*   **Zero CPU Deserialization**: The CPU never reads or casts the bytes in the mainline.

### 2. Parameterized GPU Kernels
*   `generic_plotter.comp`: Maps 100k points to window pixels, calculating min/max per-pixel column in parallel.
*   `text_grid.comp`: A character-generation shader. It performs float-to-ascii conversion inside the shader and selects quads from the Roboto atlas.
*   `tf_resolver.comp`: Solves the kinematic transform tree on the GPU.

### 3. GPU-Side Filtering & Selection
*   Filtering logic (e.g., "Only show Speed > 10") is passed as a push constant.
*   The GPU performs the search and compaction, only rendering the matching data rows.

---

## 📈 Performance Comparison (Steady State)

| Feature | Rerun (Rust/CPU) | MoonCrust (GPU-Native) |
| :--- | :--- | :--- |
| **Data Loop** | CPU-side loop over Rust structs | **Parallel GPU Dispatch** |
| **Geometry** | CPU generates quads/lines | **GPU generates geometry in VRAM** |
| **Bus Usage** | High (transfers vertices) | **Low (transfers raw bytes once)** |
| **Throughput** | ~2GB/s | **~10GB/s+ (GPU Bandwidth)** |

---

## 🚀 Implementation Roadmap
1.  **[DONE] Global Telemetry Buffer**: High-speed blitting from C++ to GPU.
2.  **[CURRENT] Shadow Plotter**: Decoupling the line rendering from the ImGui loop.
3.  **[NEXT] Scissor Mapping**: Implementing overlapping window safety.
4.  **[FUTURE] GPU Text Renderer**: Moving the telemetry table to the GPU.
