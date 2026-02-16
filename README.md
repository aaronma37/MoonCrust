# 🌙 MoonCrust: Ultra-High-Performance GPU Kernel

MoonCrust is a minimalist, industrial-grade compute and render kernel that exposes **Vulkan 1.4** Directly to **LuaJIT**. It follows a "1% C++ / 99% Lua" architecture, giving you the raw performance of a compiled engine with the rapid iteration speed of a scripting language.

## 🚀 The MoonCrust Advantage

*   **Hybrid Universal Bootstrapper:** A stable C++/SDL3 shell handles fragile driver handshakes and dynamic hardware discovery, then hands full control to Lua.
*   **The Bindless Revolution:** Forget "Binding Slots." Shaders access a global array of 1,000+ buffers and textures instantly via push-constant indexing.
*   **Auto-Sync Render Graph:** A 150-line Lua "brain" that automatically calculates `VkPipelineBarrier` and Image Layout transitions based on pass requirements.
*   **Zero-Copy Memory:** Managed by a custom **Lua-TLSF** (Two-Level Segregated Fit) allocator for $O(1)$ GPU sub-allocation without C++ overhead.
*   **Hot-Reloading Shaders:** Shaders and pipelines are file-watched and hot-swapped at runtime without restarting the kernel.

---

## 🏗️ Core Architectural Pillars

### 1. Bindless Resource Access
MoonCrust uses modern Vulkan descriptor indexing. You never have to call "BindTexture" again.
```glsl
// GLSL (Shaders)
layout(set = 0, binding = 1) uniform sampler2D all_textures[];
void main() {
    vec4 tex = texture(all_textures[pc.texture_id], uv);
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

### 3. High-Speed Staging
Upload massive datasets (like 1M particles or 4K textures) using the async staging engine.
```lua
local staging = require("vulkan.staging")
local engine = staging.new(physical_device, device, host_heap, 64MB)
engine:upload_buffer(vram_buffer, lua_data, 0, queue, family)
engine:upload_image(vram_image, w, h, pixels, queue, family)
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

### Running the Flagship Demo
The flagship demo simulates **1,048,576 particles** using a figure-eight attractor and additive solar glow.
```bash
./build/mooncrust
```

To switch examples, modify `src/lua/init.lua`.

---

## 📜 Roadmap
*   [x] Universal Bootstrapper (C++/Lua Hybrid)
*   [x] Bindless Buffer & Texture Arrays
*   [x] Auto-Sync Render Graph
*   [ ] **Full 3D Support** (Depth/Stencil buffers)
*   [ ] **Death Row Manager** (Async resource cleanup)
*   [ ] **SDL3 Input & Audio Bridge**

MoonCrust is built for those who want to drive the GPU at 200mph without wearing a C++ straightjacket. MIT Licensed.
