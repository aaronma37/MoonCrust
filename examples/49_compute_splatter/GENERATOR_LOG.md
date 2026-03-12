# 🧠 Neuro-Symbolic Splat Generator Log

## Project Goal
Build a library of hundreds of procedurally generated, mathematically defined 3D assets using Gaussian Splats in the MoonCrust kernel.

## Core Architectural Mandates
1.  **Gaussian Thickness:** All primitives must support a thickness parameter that clusters splats toward the mathematical center/surface using a Gaussian distribution.
2.  **Artifact Suppression:** The Resolve pass and splatting logic must strictly ignore splats with zero opacity or scale to prevent "black hole" artifacts at the origin.
3.  **Performance First:** Avoid expensive per-pixel/per-splat noise calculations. Use a pre-computed Permutation Table (Noise Buffer) for all stochastic distributions.
4.  **Slow & Steady:** Prioritize clean, modular primitives over rapid asset dumping.

---

## 📅 Progress Tracker

### Phase 1: Infrastructure Hardening [COMPLETE]
- [x] Create Permutation Table (Noise Buffer) in Lua and bind to Shaders.
- [x] Implement `gaussian_rand()` and `jitter()` helpers in `splat.comp`.
- [x] Update `resolve.comp` with artifact suppression logic.
- [x] Refactor `splat.comp` to use a "Primitive Dispatcher" structure.

### Phase 2: The Primitive Library [COMPLETE]
- [x] `splatSphere` (Shell + Volume)
- [x] `splatBox` (Faces + Volume)
- [x] `splatCylinder` (Tube + Caps)
- [ ] `splatBezier` (Curves)

### Phase 3: Asset Generation [TODO]
- [ ] Asset 001: Refactored Ghost
- [ ] Asset 002: Stylized Tree
- [ ] Asset 003: Simple Chair
