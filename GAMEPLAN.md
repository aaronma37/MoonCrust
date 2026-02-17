# MoonCrust: Gameplan & Technical Roadmap (2026)

MoonCrust is a High-Performance Compute & Render Kernel that exposes Vulkan 1.4 directly to LuaJIT. It is designed for engine architects, roboticists, and developers who require maximum GPU control with minimum CPU overhead.

## 1. Core Philosophy
*   **Minimalism:** < 10,000 LOC core.
*   **The "1% Binary" Rule:** The C++ bootstrapper remains a tiny shell; 99% of logic is Lua.
*   **Bindless First:** No legacy "BindPoint" abstractions. Everything is a descriptor index.
*   **Zero-Copy:** Use `VK_EXT_external_memory_host` to share LuaJIT FFI memory with the GPU.

---

## 2. Technical Architecture

### A. The Bootstrapper (C++/SDL3)
*   **Role:** Window creation, Vulkan Instance/Device initialization, LuaJIT setup.
*   **FFI Bridge:** Exports `vkGetInstanceProcAddr` and the `SDL_Window` handle to Lua.
*   **Binary Size:** Aiming for < 200KB.

### B. Memory & Allocation
*   **Approach:** Pure Lua TLSF (Two-Level Segregated Fit) Allocator.
*   **Why:** Avoids heavy C++ dependencies (like VMA) and allows LuaJIT to manage GPU memory offsets directly via FFI.
*   **The Heap:** A single massive `DescriptorSet` (Bindless) containing every resource ID.

### C. The "Death Row" (Async GC)
*   **Mechanism:** A queue of `(resource, frame_index)` pairs.
*   **Logic:** Resources are only freed when `current_frame - frame_index > MAX_FLIGHT_FRAMES`.
*   **Sync:** Driven by Vulkan Timeline Semaphores for nanosecond-precision cleanup.

### D. Render Graph & Synchronization
*   **Goal:** Automate `VkPipelineBarrier2` and Image Layout Transitions.
*   **API:** Users define "Passes" with Input/Output dependencies; MoonCrust calculates the barriers.

---

## 3. Development Phases

### Phase 1: The Foundation (Month 1) - [COMPLETE]
- [x] **Bootstrapper:** SDL3 + LuaJIT shell.
- [x] **Binding Gen:** Python script successfully converts `vk.xml` to `vulkan_ffi.lua` (~17k lines).
- [x] **FFI Hardening:** Solved topological sorting, 64-bit bitmasks, C-literal cleanup, and dependency resolution.
- [x] **PFN Resolution:** Function Pointers and Struct dependencies finalized for LuaJIT.
- [x] **Hello Instance:** Successfully created a Vulkan Instance via pure Lua FFI.

### Phase 2: Memory & Resource Management (Month 2) - [COMPLETE]
- [x] **Lua-TLSF:** Implement the memory allocator in pure Lua.
- [x] **Heap Manager:** Logic for sub-allocating Buffers and Images from large `VkDeviceMemory` blocks.
- [x] **Staging Engine:** Async transfer queue for uploading data without stalling the render thread.

### Phase 3: The Pipeline & Command Layer (Month 3) - [COMPLETE]
- [x] **Pipeline Cache:** Table-based wrapper for Graphics and Compute pipelines.
- [x] **Live-Reload:** File watchers to recompile SPIR-V and hot-swap pipelines at runtime.
- [x] **Command Encoder:** A "Fluent" API for recording commands (`cmd:draw(mesh_id):end()`).

### Phase 4: The Kernel Release (Month 4) - [COMPLETE]
- [x] **Render Graph:** Automatic barrier generation for multi-pass effects.
- [x] **Compute-First Logic:** Example projects (Slime Mold, SPH Fluid, MOO Search, Path Tracer) showing complex GPU-driven simulations, interactive pathfinding, and cinematic rendering.
- [x] **Documentation:** The "MoonCrust Manual" (README.md).

---

## 6. Engineering Journal (Lessons Learned)

### The FFI Gauntlet
Generating Vulkan bindings for LuaJIT is significantly harder than for C++. We encountered and solved:
*   **Topological Sorting:** Structs in Vulkan are deeply nested. The generator now performs a dependency-crawl to ensure `VkPhysicalDeviceLimits` is defined before `VkPhysicalDeviceProperties` is used.
*   **64-bit Enum Limitation:** LuaJIT enums are signed 32-bit. Vulkan 1.3+ uses 64-bit bitmasks (`VkAccessFlags2`). We moved these out of `cdef` and into a raw Lua table.
*   **The Recursive Pointer Trap:** `VkBaseOutStructure` and its peers are self-referential. We now use explicit forward declarations and simplified recursive definitions.
*   **C Macro Cleanup:** Python now pre-evaluates `(~0U)` and `1.0F` into raw numbers because LuaJIT's parser is strictly limited.

### Final Stance
The MoonCrust Kernel is fully operational. We have achieved a 1% C++ / 99% Lua split while maintaining the ability to run 1M+ particle simulations at high performance.

---

## 4. Competitive Advantages
| Feature | MoonCrust | Traditional (LÖVE/Godot) |
| :--- | :--- | :--- |
| **Abstraction** | Kernel (Direct) | Engine (Boxed) |
| **Throughput** | Bindless / Zero-Copy | Bind-heavy / Copy-heavy |
| **Hot-Reload** | Full Pipeline & Shaders | Mostly Script-only |
| **Footprint** | Tiny (< 10k LOC) | Large (100k - 1M+ LOC) |

---

## 5. Risk Mitigation
*   **Synchronization:** We will implement a "Validation Layer" in Lua that warns if a resource is used without a proper barrier during development.
*   **Hardware:** Strict requirement for Vulkan 1.3+ (Roadmap 2026 profile) to keep the code clean.
