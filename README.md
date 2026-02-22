# 🌙 MoonCrust: Ultra-High-Performance GPU Kernel

MoonCrust is a minimalist, industrial-grade compute and render kernel that exposes **Vulkan 1.4** directly to **LuaJIT**. It follows a "1% C++ / 99% Lua" architecture, providing the raw performance of a compiled engine with the rapid iteration speed of a scripting language.

## 🚀 What MoonCrust Provides

MoonCrust is designed for researchers, graphics engineers, and simulation developers who need maximum GPU control with minimum boilerplate.

*   **Vulkan 1.4 + LuaJIT**: Pure Vulkan power accessible through an ergonomic Lua interface.
*   **The Bindless Revolution**: Direct access to 1,000+ buffers and textures in shaders via push-constant indexing.
*   **Zero-Copy Architecture**: Custom **Lua-TLSF** allocator for O(1) GPU memory management without C++ overhead.
*   **Dynamic & Auto-Sync Render Graph**: Transparent synchronization and layout transitions for complex multi-pass pipelines.
*   **Debug Visualization & Introspection**: Built-in tools to visualize pass dependencies and resource states in real-time.
*   **Industrial-Grade Simulations**: Support for millions of particles, fluid dynamics, path tracing, and real-time path planning.

## 🛠️ Quick Start

### 1. Prerequisites
*   **Linux:** `cmake`, `build-essential`, and X11/Wayland development headers (e.g., `libx11-dev`, `libwayland-dev`).
*   **Drivers:** Vulkan 1.3+ compatible drivers.
*   **glslc:** The Vulkan shader compiler (usually in the Vulkan SDK).

### 2. Building
```bash
cmake -B build
cmake --build build -j$(nproc)
```

### 3. Running Examples
Run an example by passing its number as an argument:
```bash
./build/mooncrust 08
```

---

## 📂 Examples Gallery

MoonCrust includes a wide range of examples demonstrating everything from basic compute to advanced AI and physics.

### 🚀 Basics
*   **01_hello_gpu**: Basic Vulkan initialization and hardware info printing.
*   **02_compute_basic**: A "Hello World" for compute shaders with buffer readback.
*   **05_clear_screen**: Minimal graphics pipeline setup to clear the screen.

### 🔬 Physics & Simulations
*   **04_particles_1m**: A massive 1-million particle simulation running at high framerates.
*   **06_particles_visual**: Particle system with custom vertex/fragment shaders for stylized rendering.
*   **07_interactive_particles**: Force-field based particle interaction with mouse and spatial boundaries.
*   **08_slime_mold**: 1M agent Physarum (slime mold) simulation with trail diffusion and evaporation.
*   **09_fluid_sph**: Real-time Smoothed Particle Hydrodynamics (SPH) fluid simulation using spatial hashing.
*   **29_magic_sandbox**: A multi-element falling sand simulation with physics, light propagation, and botany.
*   **32_cellular_automata**: High-speed GPU implementation of Conway's Game of Life and Wireworld.

### 🎨 Rendering & Visuals
*   **11_grass_mesh_shader**: High-performance grass rendering using modern Vulkan Mesh Shaders.
*   **12_path_tracer**: A real-time progressive path tracer for global illumination.
*   **20_gpu_culling**: GPU-driven occlusion and frustum culling for complex scenes.
*   **21_volumetric_fog**: Real-time volumetric fog rendering with compute-based light scattering.
*   **26_mesh_cathedral**: A complex mesh rendering demo featuring a cathedral.
*   **27_obj_viewer**: A high-performance OBJ file loader and viewer.
*   **30_sponza_gltf**: Loading and rendering the classic Sponza scene from GLTF with modern techniques.
*   **40_particle_term**: A particle-based terminal emulator using **Simulated Annealing** and **SDF Fonts** to fluidly morph and settle particles into text characters.

### 🤖 Pathfinding & AI
*   **10_moo_graph_search**: Multi-Objective Optimization (MOO) graph search on the GPU.
*   **14_moo_graph_search_reward3d**: 3D lattice-based MOO path planning with reward/cost trade-offs.
*   **15_wavefront_rrt_dubins3d**: Wavefront-expanded RRT path planning for Dubins cars in 3D space.
*   **16_hybrid_astar**: GPU-accelerated Hybrid A* pathfinding for non-holonomic vehicles.
*   **17_mppi_gpu**: Model Predictive Path Integral control with thousands of parallel GPU rollouts.
*   **19_octree_astar**: A* pathfinding implemented on a sparse 3D octree structure.
*   **33_gpu_vrp**: Solving the Vehicle Routing Problem (VRP) using parallel GPU heuristics.
*   **35_ant_colony**: Path optimization through decentralized Ant Colony Simulation.

### 🧠 Machine Learning & Signal
*   **13_graph_visualizer**: Real-time visualization of the kernel's **Dynamic Render Graph** and its pass dependencies.
*   **22_neural_regression**: Training and inference of a Multi-Layer Perceptron (MLP) entirely on the GPU.
*   **24_neuro_audio**: Real-time physical modeling audio synthesis and visualization using GPU compute and SDL3.
*   **31_neuro_symbolic_mesh**: Mesh optimization using Simulated Annealing on the GPU to refine vertex positions.
*   **41_imgui_visualizer**: Advanced real-time visualization suite integrating **Dear ImGui**, **ImPlot**, and **ImPlot3D** for 2D/3D data inspection.

### 🏗️ Advanced Math & Geometry
*   **18_voronoi_sdf_graph**: Real-time generation of 3D Voronoi graphs from Signed Distance Field sites.
*   **23_sa_tsp_massing**: Solving the Traveling Salesperson Problem (TSP) using parallel Simulated Annealing chains.
*   **25_voxel_atrium / 28_voxel_world**: Efficient voxel-based world generation and rendering.

### ⚙️ Optimization & Solvers
*   **34_optimal_transport**: Computing the Wasserstein distance and optimal transport plans via Sinkhorn iterations.
*   **36_topology_opt**: Real-time structural topology optimization for engineering design.
*   **37_admm_consensus**: Distributed optimization using the Alternating Direction Method of Multipliers.
*   **38_job_shop_scheduling**: Combinatorial optimization of factory tasks using parallel Genetic Algorithms.
*   **39_branch_and_bound**: Global optimization solver for discrete mathematical programs.

---

## 📜 Core Architectural Pillars

### 1. Bindless Resource Access
MoonCrust uses modern Vulkan descriptor indexing. You never have to call "BindTexture" again.
```glsl
// GLSL (Shaders)
layout(set = 0, binding = 1) uniform sampler2D all_textures[];
void main() {
    vec4 val = texture(all_textures[pc.tex_id], uv);
}
```

### 2. The Dynamic & Auto-Sync Render Graph
The graph removes manual synchronization and supports per-frame dynamic reconstruction. You define dependencies; the kernel handles the rest. Built-in introspection allows for real-time visualization of the entire pipeline.
```lua
graph:add_pass("Physics", function(cb)
    vk.vkCmdDispatch(cb, groups, 1, 1)
end):using(pBuffer, vk.VK_ACCESS_SHADER_WRITE_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT)
```

MIT Licensed.
