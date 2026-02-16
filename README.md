# 🌙 MoonCrust: Ultra-High-Performance GPU Kernel

MoonCrust is a minimalist, industrial-grade compute and render kernel that exposes **Vulkan 1.4** Directly to **LuaJIT**. It follows a "1% C++ / 99% Lua" architecture, giving you the raw performance of a compiled engine with the rapid iteration speed of a scripting language.

## 🚀 The MoonCrust Advantage

*   **Hybrid Universal Bootstrapper:** A stable C++/SDL3 shell handles fragile driver handshakes and dynamic hardware discovery, then hands full control to Lua.
*   **The Bindless Revolution:** Forget "Binding Slots." Shaders access a global array of 1,000+ buffers and textures instantly via push-constant indexing.
*   **Auto-Sync Render Graph:** A 150-line Lua "brain" that automatically calculates `VkPipelineBarrier` and Image Layout transitions based on pass requirements.
*   **Data-Driven Interactivity:** Uses mapped host-visible buffers for real-time input (Mouse/Time) instead of expensive command re-recording, ensuring rock-solid driver stability.
*   **Zero-Copy Memory:** Managed by a custom **Lua-TLSF** (Two-Level Segregated Fit) allocator for $O(1)$ GPU sub-allocation without C++ overhead.
*   **"Death Row" Resource Safety:** An asynchronous garbage collector that prevents GPU crashes by delaying resource destruction until they are guaranteed to be unused (Frame-in-Flight safety).

---

## 🏗️ Core Architectural Pillars

### 1. Bindless Resource Access
MoonCrust uses modern Vulkan descriptor indexing. You never have to call "BindTexture" again.
```glsl
// GLSL (Shaders)
layout(set = 0, binding = 1) uniform sampler2D all_textures[];
layout(set = 0, binding = 2) uniform image2D all_storage_images[]; // Writable!

void main() {
    vec4 val = texture(all_textures[pc.tex_id], uv);
    imageStore(all_storage_images[pc.out_id], ivec2(uv * 1024), val);
}
```

### 2. The Auto-Sync Render Graph
The graph removes the most dangerous part of Vulkan: manual synchronization. You define what you need; the kernel handles the rest.
```lua
graph:add_pass("Physics", function(cb)
    vk.vkCmdDispatch(cb, groups, 1, 1)
end):using(pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)

graph:add_pass("Render", function(cb)
    vk.vkCmdDraw(cb, count, 1, 0, 0)
end):using(pBuffer, vk.VK_ACCESS_SHADER_READ_BIT, vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT)
   :using(swImage, vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
```

---

## 🛠️ Build & Execute

### Prerequisites
*   **Vulkan SDK 1.3+** (Roadmap 2026 Profile)
*   **LuaJIT**
*   **SDL3**
*   **glslc** (Shader compiler)

### Building the Shell
```bash
mkdir build && cd build
cmake ..
make
```

### Running the Examples
Switch between examples using command line arguments:

**1. The Flagship Interactive Demo (Default)**
Simulates **1,048,576 particles** in a 3D figure-eight attractor.
```bash
./build/mooncrust 07
```

**2. The Visual Benchmark**
A non-interactive version of the particle system (useful for benchmarking raw GPU throughput).
```bash
./build/mooncrust 06
```

---

## 📜 Roadmap: Phase 2 "The Simulation Era"

We are expanding MoonCrust to support advanced compute simulations and modern geometry processing.

### Core Features (The "Finite Four" Bindings)
*   [x] **Storage Buffers** (Binding 0) - Physics/Data
*   [x] **Sampled Images** (Binding 1) - Textures/Sprites
*   [ ] **Storage Images** (Binding 2) - Writable Textures (Required for Slime Mold/Ray Tracing)
*   [ ] **Mesh Shaders** (Pipeline Type) - Infinite Geometry (100M instances)
*   [ ] **Indirect Dispatch** (Command) - GPU-driven work generation

### Planned Examples
*   [ ] **Neural Cellular Automata:** "Slime Mold" simulation using Storage Images.
*   [ ] **Fluid Dynamics (SPH):** 1M particle liquid simulation using Spatial Hashing.
*   [ ] **Mesh Shader Grass:** Rendering 100 million blades of grass.
*   [ ] **Path Tracer:** Real-time ray tracing in a Compute Shader.

MoonCrust is built for those who want to drive the GPU at 200mph without wearing a C++ straightjacket. MIT Licensed.
