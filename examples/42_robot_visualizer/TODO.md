# Robot Pilot Project Roadmap

This document tracks the progress of the high-performance robotics visualizer prototype based on the MoonCrust hallmarks.

## 🏁 Progress Tracker

### 1. The Zero-Copy Data Mainline
- [x] C++ MCAP Bridge (Reading & Seeking)
- [x] Direct FFI memory mapping of CDR payloads
- [x] Host-Visible Vulkan buffer streaming
- [ ] **Next:** Efficiently handle larger-than-RAM bag files via partial mapping.

### 2. The Compute-Driven Render Graph
- [x] GPU-based vertex parsing (`parser.comp`)
- [x] Async compute-to-graphics barrier management
- [ ] **Next:** Compute-based point culling and LOD (Level of Detail) generation.

### 3. The "1% C++ / 99% LuaJIT" Philosophy
- [x] 100% of 3D projection and UI logic in Lua
- [x] Dynamic pipeline reloading
- [ ] **Next:** Live-edit shader support for field re-mapping.

### 4. GPU-Native Modular Panels
- [x] Immediate mode Telemetry dashboard
- [x] High-DPI and pixel-perfect coordinate alignment
- [ ] **Next:** Draggable/dockable visualization modules.

### 5. The "Aperture" Strategy (Render-to-Texture)
- [x] ImPlot "Shell" integration
- [x] GPU-side telemetry rendering to offscreen texture
- [ ] **Next:** Depth-buffer sharing between custom 3D passes and ImGui.

### 6. Shared Memory Layouts
- [x] Hardened FFI alignment for input and window state
- [ ] **Next:** Dynamic CDR Schema parsing (handling different Lidar strides/offsets).

---

## 🚀 Immediate Next Steps

### 🛠️ Feature: Schema Hardening (CDR Decoder)
- Update `parser.comp` to accept dynamic strides.
- Map ROS2 `PointCloud2` field metadata to shader push constants.
- Enable support for Intensity, Ring, and Reflectivity mapping.

### 🛠️ Feature: Advanced 3D Navigation
- Implement **Scroll Zoom** (hooked into `_MOUSE_WHEEL`).
- Implement **Middle-Click Pan**.
- Perspective vs. Orthographic toggle.

### 🛠️ Feature: Topic Explorer
- [x] Add a sidebar to browse all channels in the MCAP file.
- [x] Implement a checkbox system to toggle visibility of different sensors.
- [x] Add metadata tooltips (Encoding, Schema).

---

## 📦 Missing Components
- **URDF Support:** Rendering the robot's physical geometry alongside the Lidar data.
- **Coordinate Transforms (TF):** Correctly applying the transform tree to move points from `sensor_frame` to `map_frame` on the GPU.
- **Marker Support:** Visualizing waypoints, obstacles, and path planning rollouts.
