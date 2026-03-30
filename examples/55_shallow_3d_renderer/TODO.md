# 🤖 Project: MoonCrust - Voxel Automation (Large Scale)

## 🧪 Testing & Validation (Immediate Priority)
- [x] **Voxel Grid Unit Tests:**
    - [x] **Indexing Logic:** Verify 3D-to-1D index mapping for 16x16x16 chunks.
    - [x] **Neighbor Lookup:** Test correct boundary handling for CA neighbor access.
- [x] **Physics Unit Tests:**
    - [x] **AABB vs Voxel:** Test intersection logic for various robot positions.
    - [x] **Grounded Detection:** Verify the "is_grounded" flag triggers correctly on voxel contact.
- [x] **Automation Logic Tests:**
    - [x] **60Hz Tick Stability:** A test to verify the simulation clock remains steady regardless of render frame time.
    - [x] **Resource Transfer:** Verify an item moves from Voxel A to Voxel B over X ticks.
- [x] **Lua API Unit Tests:**
    - [x] **Component Detection:** Mock a "chassis" with chips and verify the Lua environment injects the correct methods.
    - [x] **Sandbox Security:** Ensure scripts cannot access global Lua libraries (io, os) or MoonCrust internals.
- [x] **Regression Suite:** Automate the execution of these tests after every architectural change.

## 🏗️ Sparse Voxel Architecture
- [x] **16³ Chunk Partitioning:** Refactor the world into a grid of 16x16x16 voxel chunks.
- [x] **Activity Map:** Maintain a bitmask/texture of "Active" chunks.
    - **Criteria for Activity:** Proximity to player, presence of "Automation" voxels, or recent CA state changes (falling sand, fluids).
- [x] **Selective CA Execution:**
    - Use an **Indirect Dispatch** system to only run compute shaders on chunks marked as "Active" in the Activity Map.
    - Skip empty or static (sleeping) chunks to save GPU cycles.
- [ ] **Chunk LOD (Far-Field Approximation):**
    - For chunks outside the high-fidelity radius, run a "Macro-CA" that only simulates bulk flow (e.g., total energy in/out) rather than individual voxel ticks.

## ⚙️ Automation & Factorio-Scale Simulation
- [x] **60Hz Automation Tick:** 
    - Decouple "Machine Logic" from the main render loop.
    - Ensure all 16³ chunks containing machines tick exactly at 60Hz.
- [ ] **Memoized Machine State:**
    - Cache the internal state of automation chunks. If a chunk's inputs and internal machines haven't changed, reuse the previous tick's output instead of re-simulating every voxel.
- [ ] **Physical Item Buffers:** Implement a GPU-side messaging system for voxels to "push/pull" items across chunk boundaries.

## 🤖 Modular Robot (The "Player" Chassis)
- [ ] **Snap-On Component Architecture:** 
    - The player is a 3D chassis with specific "Grip Points."
    - Hardware Components (Physical Chips, Thrusters, Drills) occupy physical voxels on the chassis.
- [ ] **Hardware-Aware Lua API:**
    - **Discovery:** On boot, the Lua VM scans the chassis for attached components.
    - **Dynamic Injection:** If a `Hover_Module` is detected at `Grip_01`, the global `robot` table is injected with `robot.hover()`.
    - **Interrupts/Events:** Allow hardware to trigger Lua callbacks (e.g., `on_collision()`, `on_low_battery()`).
- [ ] **Third-Person Physics:** Move from discrete voxel stepping to a smooth AABB/Sphere-cast collision system against the voxel grid.

## 🛰️ Programmable Drones & Machine Protocols
- [ ] **Instruction Sets:** Define a "Reduced Instruction Set" for dumber drones to save on Lua VM overhead.
- [ ] **Protocol Broadcast:** Use a "Radio Voxel" to beam Lua scripts/protocols to all drones within a certain chunk radius.
- [ ] **Fleet Management:** A UI to monitor the status and "Code Version" of various drone groups.

## 🔥 Voxel World & Interaction
- [ ] **Material Physics:** 
    - **Conductive:** Voxels that carry electricity for automation.
    - **Fragile:** Voxels that crumble under robot weight.
    - **Dense:** Requires specific drill upgrades to mine.
- [ ] **Dynamic Destruction:** High-speed "Carving" of the 3D Image when tools/explosives are used.

## 💡 Voxel Global Illumination (Light Propagation CA)
- [ ] **Dual Light Buffers:** Replace the single `signal_vol` with `light_vol_a` and `light_vol_b` (using packed `r32ui` for RGB channels) to enable ping-pong CA read/writes.
- [ ] **Light Injection:**
    - Constant warm sunlight injected at the top of the grid (`y = grid_h - 1`).
    - Emissive voxel materials (e.g., glowing crystals or lava) injecting their own colored light locally.
    - Dynamic entities (robot, DNA) injecting light directly into the volume.
- [ ] **Fluid Propagation Logic (`sim.comp`):**
    - Treat light like a diffusing fluid. Each air voxel samples its 6 neighbors, averages incoming RGB light, and applies a decay/attenuation factor.
    - Occlusion: Solid blocks block light propagation naturally, creating soft shadows and directional bouncing.
- [ ] **GI Rendering (`render.frag`):**
    - Sample the 3D light volume using the fragment's world position slightly offset by the vertex normal.
    - Unpack the RGB values and multiply by the base voxel color/diffuse lighting.
- [ ] **Sparsity Optimization:** Ensure light propagation updates the chunk `active_map` so illuminated areas eventually settle and go to "sleep" (costing zero GPU cycles) once the lighting state reaches equilibrium.

## ✨ Visuals & Tooling
- [ ] **Voxel Ambient Occlusion (VAO):** Calculate 3-bit AO per voxel during the meshing pass for "crunchy" depth.
- [ ] **In-Game IDE:** A specialized ImGui window with syntax highlighting for the robot's Lua scripts.
- [ ] **Diagnostic View:** Overlay showing chunk activity, "Automation Tick" performance, and power-grid flow.
