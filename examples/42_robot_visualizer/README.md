# Example 42: The Robot Pilot

This example demonstrates a high-performance robotics visualization architecture designed to replace traditional web-based tools with a GPU-native, low-latency ecosystem.

## 🚀 The Six Hallmarks of MoonCrust Robotics

### 1. The Zero-Copy Data Mainline (The Death of Deserialization)
Bypass the CPU completely. Utilizing the C++ MCAP SDK, MoonCrust maps raw CDR bytes directly from storage into Vulkan Host-Visible RAM. The CPU never instantiates a single object or pays a garbage collector tax.

### 2. The Compute-Driven Render Graph
Let the GPU think for itself. Using Vulkan 1.4 bindless descriptors, compute shaders (`parser.comp`) read raw MCAP payloads, perform coordinate transformations (e.g., Lidar Polar -> Cartesian), and write vertex data directly into GPU memory. The CPU has no idea what the data actually looks like.

### 3. The "1% C++ / 99% LuaJIT" Philosophy
Bare-metal execution speeds without compile-time friction. C++ is strictly a bridge for hardware boundaries (SDL3, MCAP). The Auto-Sync Render Graph and the entire UI dashboard are controlled via Lua, allowing engineers to modify 3D visualization logic on the fly while the stream is active.

### 4. GPU-Native Modular Panels (Immediate Mode)
A stateless, hyper-lightweight UI footprint. Powered by **Dear ImGui**, the modular panels do not exist in memory. The UI layout is evaluated every frame, compiled into a tiny vertex buffer, and drawn natively on top of 3D viewports at maximum hardware speed.

### 5. The "Callback Hijack" Visualization Strategy
Render millions of points without breaking a sweat. MoonCrust uses **ImPlot** to draw the UI "shell" (grids and axes). To draw the payload, we use `ImDrawList::AddCallback` to pause the UI renderer and inject a custom Vulkan pipeline. The heavy data never touches the ImGui vertex buffers or CPU math.

### 6. Shared Memory Layouts (The Antidote to Dependency Hell)
Strict silicon alignment. Using LuaJIT FFI, the Lua UI scripts map exactly to the underlying C-structs of the robot data. The CPU telemetry structs and Vulkan GLSL shaders are mathematically guaranteed to match perfectly, eliminating silent type-coercion bugs.

---

## 🛠️ Build and Run

1. **Build the Integrated Library**:
   ```bash
   cd examples/42_robot_visualizer/build
   cmake ..
   make -j$(nproc)
   ```

2. **Launch the Visualizer**:
   ```bash
   ./build/mooncrust 42
   ```
