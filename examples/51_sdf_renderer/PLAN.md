# Example 51: Neurosymbolic SDF Renderer (PBD Cloth & ID-Based Raymarching)

This example implements a custom, pure SDF-based renderer with hierarchical skeletons (TF Trees), neurosymbolic asset generation (LLM-designed), and PBD-based cloth/equipment simulation using SDF collision projection.

## 📋 Core Components

### 1. The SDF Primitive Library (`sdf.glsl`)
A collection of pure mathematical functions for distance estimation.
- **Primitives:** `sdSphere`, `sdCapsule`, `sdBox`, `sdEllipsoid`, `sdCylinder`.
- **Operators:** `opUnion`, `opSmoothUnion` (smin), `opSubtraction`, `opIntersection`.
- **Space Ops:** `opTranslate`, `opRotate`, `opScale`.

### 2. Hierarchical TF Skeleton (`generator.lua`)
A Lua-side transformation tree that manages bone hierarchies.
- **Bone Buffer:** A GPU buffer storing `mat4` transforms for each bone.
- **SDF Descriptor Buffer:** A buffer defining which primitive is attached to which bone, its ID, color, and local parameters.

### 3. ID-Based Raymarching Kernel (`render.comp`)
A compute shader that performs sphere tracing at a variable (lower) resolution.
- **Raymarching Loop:** For each pixel, march along the ray, sampling the global SDF.
- **DDA Grid Accelerator:** Uses a 3D grid to efficiently sample dynamic PBD particles.
- **ID & Color Selection:** During the distance check, track the ID of the closest primitive. For matching IDs, use smooth blending; otherwise, use discrete color selection.

### 4. PBD/XPBD Physics & Dynamic Assets (`physics.comp`)
Dynamic assets (clothes, capes, hair) are simulated as a particle-based lattice.
- **XPBD Solver:** Multi-substep solver for stable distance and bending constraints.
- **SDF Collision Projection:** Particles sample the skeleton's global SDF and project out along the gradient.
- **Skeleton Pull:** Particles are weakly tethered to anchor bones to prevent drifting.

## 🧠 Neurosymbolic Generation Architecture

The character and equipment generation follows a two-step decoupled workflow:

### Step 1: Localized TF Tree (The Skeleton)
The skeleton is generated as a hierarchical tree of coordinate spaces where each bone only defines its relationship to its parent.

### Step 2: Decoupled SDF Attachment (The Fleshing & Equipment)
SDF primitives are "equipped" to specific bones.
- **Body SDFs:** Shared IDs for smooth skin-blending.
- **Equipment/Clothes:** Discrete IDs for sharp material transitions.

## 🚀 Execution Phases

### Phase 1 & 2: Foundations [COMPLETE]
- [x] Basic SDF Renderer with Bone Transforms.
- [x] Hierarchical Skeleton Generation in Lua.
- [x] ID-Based Rendering with Smooth Blending.

### Phase 3: PBD Physics & Grid Rendering [CURRENT]
- [ ] Implement `physics.comp` with XPBD and SDF projection.
- [ ] Add `ParticleBuffer` and `ConstraintBuffer` to `main.lua`.
- [ ] Implement Grid Binning pass.
- [ ] Update `render.comp` with DDA grid traversal.

### Phase 4: Final Polish & Character Recipes
- [ ] Define "Tall/Strong" vs "Small/Agile" humanoid recipes.
- [ ] Add procedural accessories (Horns, Tails, Pauldrons).
- [ ] Implement complex clothes (Robes/Cloaks) with multi-bone anchoring.
