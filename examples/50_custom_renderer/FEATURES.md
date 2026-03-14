# 🚀 Example 50: Super-Optimized Hierarchical OBB Renderer

This example demonstrates an industrial-grade compute-based ray tracer capable of rendering hundreds of thousands of Oriented Bounding Boxes (OBBs) at high frame rates using the MoonCrust GPU kernel.

## 🏗️ Architectural Features

### 1. Two-Level Spatial Acceleration (Hierarchical Grid)
- **Coarse Level**: An 8x8x8 macro-grid used for "empty space skipping." Rays jump through large empty volumes in a single step.
- **Fine Level**: A 64x64x64 micro-grid for localized object gathering.
- **Conservative Hashing**: Objects are registered in every cell their bounding sphere touches, ensuring no artifacts during camera movement.

### 2. Digital Differential Analyzer (DDA) Traversal
- Replaced tiled gathering with per-ray DDA.
- Rays step through the grid cell-by-cell with **Early Exit** logic (stopping at the first hit).
- Significantly reduces the number of intersection tests compared to brute-force or coarse-tile methods.

### 3. Bindless SoA (Structure of Arrays)
- Direct push-constant indexing into massive GPU buffers.
- Separated data into specialized buffers (`Transform`, `Material`, `Sphere`, `Grid`, `Indices`) to maximize cache efficiency and memory alignment.

## ⚡ Performance Optimizations

### 1. Sphere-Precheck (16x Faster Skip)
- Before fetching a heavy 64-byte transformation matrix, the shader performs a fast ray-sphere intersection using a lightweight 16-byte `Sphere` buffer.
- Minimizes global memory bandwidth and latency by skipping matrix math for 99% of potential candidates.

### 2. World-to-Local Matrix Inversion
- Transformation matrices are pre-inverted on the CPU.
- Ray-OBB intersection is reduced to a simple Ray-AABB test in local space via a single matrix-vector multiplication.

### 3. Intelligent Shadow Throttling
- **Backface Culling**: Shadow rays are skipped for surfaces facing away from the light.
- **Aggressive Traversal**: Shadow DDA is capped at 24 steps and 8-16 objects per cell to prevent performance "hotspots" in dense clusters.
- **Early Exit**: Shadow rays return immediately upon the first occlusion hit.

## 🛠️ Technical Rendering Stack (The Pipeline)

### Pass 1: Primary Ray & Lighting (Compute)
- **Compute Shader**: `render.comp` (Local Size: 16x16)
- **Target**: Internal Storage Image (`RGBA32F`, `1280x720`)
- **Operations**:
    - DDA traversal through Hierarchical Grid.
    - Sphere pre-check + OBB intersection.
    - Diffuse + Emissive shading.
    - Secondary shadow ray DDA pass.
- **Sync**: `VkImageMemoryBarrier` transitions image from `UNDEFINED` to `GENERAL` (initially) and ensures `SHADER_WRITE` visibility.

### Pass 2: Blit & UI (Graphics)
- **Graphics Pipeline**: Full-screen triangle (Vertex shader generated index-based).
- **Fragment Shader**: Sample from Pass 1's Storage Image and output to Swapchain.
- **Target**: Current Swapchain Image (`BGRA8_UNORM` / `RGBA8_SRGB`).
- **Sync**: `VkImageMemoryBarrier` transitions Pass 1 image from `GENERAL` to `GENERAL` (ensuring `COMPUTE_SHADER` writes are visible to `FRAGMENT_SHADER` reads).

### Pass 3: Debug Overlay (ImGui)
- **Renderer**: `imgui.render(cb)`
- **Integration**: Injected directly into the command buffer before Pass 2's `EndRendering` call.
- **State**: Wall-clock FPS measurement using `SDL_GetPerformanceCounter`.

## 📦 Data Structures

| Buffer | Element Size | Purpose |
| :--- | :--- | :--- |
| `tf_buf` | 64 bytes | World-to-Local `mat4` for every block. |
| `mat_buf` | 32 bytes | Color, roughness, metallic, emissive data. |
| `sphere_buf` | 16 bytes | `vec3 center`, `float radius` for fast skipping. |
| `grid_buf` | 8 bytes | `u32 offset`, `u32 count` for every cell. |
| `idx_buf` | 4 bytes | Global object index stored per grid cell. |
| `coarse_buf`| 4 bytes | Occupancy bit (0 or 1) for 8x8x8 macro-cells. |

## 🛠️ Interactive Controls
- **WASD**: Camera movement.
- **ImGui Settings**: 
  - Real-time FPS counter (Wall-clock).
  - Live block count reporting (100,000 blocks).
  - **Shadow Toggle**: Dynamically enable/disable the shadow pass.

## 📈 Scalability
- Current Milestone: **100,000 blocks**.
- Targeted toward **1,000,000 blocks** using the foundation of hierarchical grids and GPU-side acceleration building.
