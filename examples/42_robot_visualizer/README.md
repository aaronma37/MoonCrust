# Example 42: The Robot Pilot

This example demonstrates a high-performance robotics visualization architecture designed to replace traditional web-based tools with a GPU-native, low-latency ecosystem.

## 🚀 The Six Hallmarks of MoonCrust Robotics

### 1. The Zero-Copy Data Mainline (The Death of Deserialization)
Bypass the CPU completely. Utilizing the C++ MCAP SDK, MoonCrust maps raw CDR bytes directly from storage into Vulkan Host-Visible RAM. The CPU never instantiates a single object or pays a garbage collector tax.

### 2. The Compute-Driven Render Graph
Let the GPU think for itself. Using Vulkan 1.4 bindless descriptors, compute shaders (`parser.comp`) read raw MCAP payloads and execute a custom **Bytecode VM** to decode dynamic CDR schemas. It performs coordinate transformations (e.g., Lidar Polar -> Cartesian) and writes vertex data directly into GPU memory. The CPU has no idea what the data actually looks like.

### 3. The "1% C++ / 99% LuaJIT" Philosophy
Bare-metal execution speeds without compile-time friction. C++ is strictly a bridge for hardware boundaries (SDL3, MCAP). The Auto-Sync Render Graph and the entire UI dashboard are controlled via Lua, allowing engineers to modify 3D visualization logic on the fly while the stream is active.

### 4. GPU-Native Modular Panels (Immediate Mode)
A stateless, hyper-lightweight UI footprint. Powered by **Dear ImGui**, the modular panels do not exist in memory. The UI layout is evaluated every frame, compiled into a tiny vertex buffer, and drawn natively on top of 3D viewports at maximum hardware speed.

### 5. The "Aperture" Visualization Strategy (Render-to-Texture)
Render millions of points without breaking a sweat. Instead of injecting brittle callbacks into the UI loop, MoonCrust processes the telemetry payload entirely on the GPU and renders it to a dedicated offscreen texture. We then use **ImPlot** to draw the UI "shell" (grids and axes) and composite the GPU's high-speed texture underneath. The heavy data never touches the ImGui vertex buffers or CPU math.

### 6. The "Bytecode VM" Decoder (Handling Shifting Sands)
Strict alignment without the rigidity. Instead of brittle C-structs that break when a string changes length, MoonCrust compiles schemas into a lightweight instruction set. The GPU interpreter maintains a precise read-pointer, handling ROS2 CDR alignment and dynamic sequence offsets in silicon, ensuring telemetry is always mathematically accurate.

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
