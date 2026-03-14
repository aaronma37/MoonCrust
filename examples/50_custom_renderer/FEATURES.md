# 🚀 Example 50: Super-Optimized Hierarchical OBB Renderer

This example demonstrates an industrial-grade compute-based ray tracer capable of rendering **1,048,576 (2^20)** Oriented Bounding Boxes (OBBs) at high frame rates using the MoonCrust GPU kernel.

## 🏗️ Architectural Features

### 1. GPU-Side Spatial Hashing (Milestone: 1 Million Blocks)
- **Zero-CPU Building**: The entire spatial hierarchy is constructed on the GPU using a multi-pass compute pipeline.
- **Pass 1: Binning**: Objects are binned into cell keys based on their spatial position.
- **Pass 2: Bitonic Sort**: A high-performance parallel sort groups all objects by their cell index contiguously in memory.
- **Pass 3: Grid Build**: A final pass calculates cell offsets and counts, making the grid ready for ray tracing.

### 2. Hierarchical Spatial Acceleration
- **Macro Level**: An 8x8x8 coarse occupancy grid for high-level empty space skipping.
- **Micro Level**: A 64x64x64 fine grid for localized object gathering.
- **Micro-Occupancy Bitmasks**: A third level of acceleration using **64-bit bitmasks** for 4x4x4 "bricks." This allows rays to skip 64 empty cells in a single cycle without touching global memory.

### 3. Digital Differential Analyzer (DDA) Traversal
- Replaced tiled gathering with per-ray DDA.
- Rays step through the hierarchy cell-by-cell with **Early Exit** logic (stopping at the first hit).
- Significantly reduces the number of intersection tests compared to brute-force or coarse-tile methods.

### 4. Bindless SoA (Structure of Arrays)
- Direct push-constant indexing into massive GPU buffers.
- Separated data into specialized buffers (`Transform`, `Material`, `Sphere`, `Grid`, `Indices`, `Bitmask`) to maximize cache efficiency and memory alignment.

## ⚡ Performance Optimizations

### 1. Sphere-Precheck (16x Faster Skip)
- Before fetching a heavy 64-byte transformation matrix, the shader performs a fast ray-sphere intersection using a lightweight 16-byte `Sphere` buffer.
- Minimizes global memory bandwidth and latency by skipping matrix math for 99.9% of potential candidates.

### 2. Bitmask-Guided Skipping
- Rays perform a bitwise `AND` against a 64-bit occupancy mask for every "brick" they enter.
- If the bit is zero, the ray skips the grid fetch and all object tests for that cell, dramatically reducing memory controller pressure.

### 3. Intelligent Shadow Throttling
- **Backface Culling**: Shadow rays are skipped for surfaces facing away from the light.
- **Aggressive Traversal**: Shadow DDA is capped at 32 steps and 8 objects per cell to prevent performance "hotspots" in dense clusters.
- **Early Exit**: Shadow rays return immediately upon the first occlusion hit.

## 🛠️ Technical Rendering Stack (The Pipeline)

### Pass 1: Hierarchy Rebuild (Optional/Compute)
- **Shaders**: `hash.comp`, `sort.comp`, `build_grid.comp`.
- **Logic**: Triggered only when geometry changes (`needs_rebuild`).
- **Result**: A fully sorted `idx_buf` and updated `grid_buf` + `bitmask_buf`.

### Pass 2: Primary Ray & Lighting (Compute)
- **Compute Shader**: `render.comp` (Local Size: 16x16).
- **Operations**: Hierarchical DDA, Bitmask skipping, Sphere pre-check, OBB intersection, and Shadows.

### Pass 3: Blit & UI (Graphics)
- **Graphics Pipeline**: Full-screen triangle blit to swapchain.
- **Renderer**: `imgui.render(cb)` for debug settings.

## 📦 Data Structures (1M Block Scale)

| Buffer | Size (1M Blocks) | Purpose |
| :--- | :--- | :--- |
| `tf_buf` | 64.0 MB | World-to-Local `mat4` transformation matrices. |
| `sphere_buf` | 16.0 MB | `vec3 center`, `float radius` for fast skipping. |
| `sort_buf` | 8.0 MB | Intermediate `{u32 key, u32 val}` pairs for sorting. |
| `idx_buf` | 4.0 MB | Sorted global object indices. |
| `grid_buf` | 2.0 MB | `u32 offset`, `u32 count` for 64x64x64 cells. |
| `bitmask_buf`| 32 KB | 64-bit micro-occupancy masks (16x16x16 bricks). |

## 🛠️ Interactive Controls
- **WASD**: Camera movement.
- **ImGui Settings**: 
  - Real-time Wall-Clock FPS counter.
  - **Shadow Toggle**: Dynamically enable/disable the shadow pass.
  - **Force Rebuild**: Manually trigger a GPU spatial hash rebuild.
