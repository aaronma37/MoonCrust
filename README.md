# 🌙 MoonCrust: High-Performance GPU Kernel

MoonCrust is a minimalist, ultra-high-performance compute and render kernel that exposes **Vulkan 1.4** directly to **LuaJIT**. It is designed for engine architects, roboticists, and simulation developers who require maximum GPU control with near-zero CPU overhead.

## 🚀 Key Features

*   **1% Binary Rule:** The C++ bootstrapper is a tiny shell (< 200KB); 99% of all logic, including memory allocation and command orchestration, is written in pure Lua.
*   **Zero-Copy Architecture:** Optimized for `VK_EXT_external_memory_host`, allowing LuaJIT FFI memory to be shared directly with the GPU without explicit copies.
*   **Pure Lua-TLSF:** A custom Two-Level Segregated Fit memory allocator implemented in Lua for $O(1)$ GPU sub-allocation.
*   **Automated Render Graph:** Define high-level passes and dependencies; the kernel automatically generates synchronization barriers and image layout transitions.
*   **Hot-Reloading Shaders:** Pipelines are file-watched and automatically recompiled/hot-swapped at runtime.

---

## 🏗️ Technical Architecture

### 1. Memory Management (`vulkan.memory`, `vulkan.heap`)
MoonCrust bypasses heavy C++ allocators like VMA. Instead, it manages GPU memory blocks using a pure Lua implementation of the TLSF algorithm.
```lua
local heap = require("vulkan.heap")
-- Allocate 64MB of Device-Local VRAM
local vram = heap.new(physical_device, device, vram_type_idx, 64 * 1024 * 1024)
local allocation = vram:malloc(1024) -- Offset-based sub-allocation
```

### 2. Staging Engine (`vulkan.staging`)
Efficiently move data from LuaJIT's heap to Device-Local VRAM using an asynchronous transfer pipeline.
```lua
local staging = require("vulkan.staging")
local engine = staging.new(physical_device, device, host_heap, 1MB)
engine:upload_buffer(vram_buffer, lua_data, offset, queue, family)
```

### 3. Fluent Command Encoder (`vulkan.command`)
Record complex Vulkan commands with a modern, readable API.
```lua
local command = require("vulkan.command")
command.encode(cb, function(cmd)
    cmd:bind_pipeline(vk.VK_PIPELINE_BIND_POINT_COMPUTE, pipe)
       :bind_descriptor_sets(vk.VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, sets)
       :dispatch(groups_x, 1, 1)
end)
```

### 4. Render Graph (`vulkan.graph`)
The graph eliminates manual `VkPipelineBarrier` management. It tracks resource state and injects barriers only when necessary.
```lua
local rg = graph.new(device)
local res = rg:add_resource("particles", graph.TYPE_BUFFER, buf_handle)

rg:add_pass("ComputePhysics", function(cmd) 
    -- Compute logic here
end):write(res, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
```

---

## 🛠️ Development & Build

### Prerequisites
*   **LuaJIT** (with FFI support)
*   **Vulkan SDK 1.3+**
*   **SDL3**
*   **glslc** (for shader compilation)

### Building the Bootstrapper
```bash
mkdir build && cd build
cmake ..
make
```

### Running Examples
MoonCrust features a modular example system. To run an example, modify the `CURRENT_EXAMPLE` variable in `src/lua/init.lua`:

```lua
-- src/lua/init.lua
local CURRENT_EXAMPLE = "examples.04_particles_1m.main"
```

Then run the bootstrapper:
```bash
./build/mooncrust
```

### Available Examples
*   **01_hello_gpu**: Basic initialization and hardware info.
*   **02_compute_basic**: Simple array math on the GPU.
*   **04_particles_1m**: High-performance simulation of 1,048,576 particles.

---

## 📜 License
MoonCrust is released under the MIT License. Built for the future of GPU-driven logic.
