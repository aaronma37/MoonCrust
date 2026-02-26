# 🏗️ MoonCrust Robotics Architecture: GPU-Native Pipeline

This document defines the architectural "North Star" for Example 42. The goal is to maximize throughput by ensuring data flows from **Disk to Pixel** with zero CPU-side deserialization or string allocation.

## 🎯 The Mission: Outperforming Rerun
To be faster than Rust-based tools like Rerun, we cannot simply optimize CPU code. We must eliminate the CPU from the data mainline entirely. In this architecture, the CPU stops being a **Translator** and becomes an **Orchestrator**.

---

## 🏗️ The "Aperture Pattern" Architecture (Render-to-Texture)

Instead of injecting brittle Vulkan callbacks *inside* the ImGui draw list (which corrupts pipeline state), we use a decoupled Aperture pattern:

### 1. The ImGui Pass (The "Aperture")
*   **Role**: Handles window management, docking, splitting, and user input.
*   **Aperture**: ImPlot defines a "hole" on the screen (the plot axes). 
*   **Compositing**: ImPlot natively draws a pre-rendered GPU texture (`ImPlot_PlotImage`) inside the axes bounds, allowing perfect handling of overlapping windows (like file pickers) without artifacting.

### 2. The MoonCrust Pass (The "Payload")
*   **Role**: Executes the high-throughput rendering (Plots, Lidar, 3D Models, Text Kernels) onto an offscreen texture.
*   **Timing**: Runs asynchronously *before* the ImGui pass begins.
*   **Payload**: The GPU reads directly from the **Global Telemetry Buffer (GTB)** and draws directly into the offscreen framebuffer (`M.plot_image`).

---

## 🛰️ Core Architectural Pillars

### 1. The Global Telemetry Buffer (GTB)
*   A 512MB pre-allocated, host-visible circular buffer.
*   The C++ bridge blits raw MCAP bytes directly into reserved channel slots.
*   **Zero CPU Deserialization**: The CPU never reads or casts the bytes in the mainline.

### 2. Parameterized GPU Kernels
*   `parser.comp` (Lidar Mode): Maps raw LiDAR bytes to vertex positions in parallel.
*   `parser.comp` (Universal Telemetry Mode): A **Bytecode VM** that sequentially decodes dynamic MCAP/CDR payloads (handling shifting offsets from strings and sequences) without CPU intervention.
*   `text_grid.comp`: A character-generation shader. It performs float-to-ascii conversion inside the shader and selects quads from the Roboto atlas.
*   `tf_resolver.comp`: Solves the kinematic transform tree on the GPU.

### 3. The Schema Bytecode VM (Interpreter Pattern)
Traditional parallel parsing fails when schema offsets shift dynamically (due to variable-length strings or sequences). We solve this using a hybrid approach:
*   **Compiler (Lua)**: When a channel is opened, the CPU walks the schema once and emits a compact 16-byte instruction stream (`OP_STATIC`, `OP_STRING`, `OP_DYN_ARRAY`).
*   **Interpreter (GPU)**: A single-threaded GPU kernel executes this bytecode against the raw message buffer, maintaining a precise read-pointer that handles CDR alignment and dynamic jumps.
*   **Output**: Flattened telemetry data is written to a dedicated storage buffer, ready for the UI or Plotter to consume.

### 4. GPU-Side Filtering & Selection
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
2.  **[DONE] Render-To-Texture Plotter**: Decoupling line rendering to an offscreen buffer (Aperture Pattern).
3.  **[DONE] GPU Bytecode VM**: Decoupling schema parsing from the CPU (Interpreter Pattern).
4.  **[CURRENT] GPU Text Renderer**: Moving the telemetry `pretty_viewer` table to the GPU to entirely eliminate CPU string deserialization.
