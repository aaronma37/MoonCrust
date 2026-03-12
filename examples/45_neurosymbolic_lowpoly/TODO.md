# TODO: Adaptive Point-Sleeve Reconstruction

## Concept: "The High-Fidelity Character Mesher"
The goal is to move away from fixed 3D grids (voxels) and simple parametric tubes toward an adaptive system that captures high-fidelity CSG detail while maintaining professional low-poly edge flow.

### Phase 1: Normal-Adaptive Sampling
- **Radial Bombardment**: Shoot rays in spiral/ring patterns around each bone in the skeleton.
- **Surface Detection**: Use Raymarching/SDF evaluation to find the "0" crossing.
- **Adaptive Density (SSAO-style)**: Compare the surface normal of the current hit with the previous one. If the angular difference is large (a sharp corner/edge), recursively subdivide the sampling angle to shoot more rays in that specific area.

### Phase 2: Ordered Reconstruction
- **Grid-Ordered Connectivity**: Instead of general point-cloud reconstruction (which is unstable), leverage the "Ring Index" and "Slice Index" of the bones.
- **Topology Stitching**: Connect `Point(Ring_A, Index_i)` to `Point(Ring_B, Index_i)` to form guaranteed watertight "Sleeves."
- **Handle Joint Welding**: Use global field sampling to naturally "weld" sleeves into the torso volume.

### Phase 3: High-Detail CSG Primitives
- **Hard-Boolean Math**: Use `math.min`/`math.max` instead of `smin` for sharp features (jawlines, hat brims, swords).
- **Advanced Warps**: Implement angular squashing (radius_x vs radius_z) and profile functions (muscle bulges, robe flares).

## Status
- Currently reverted to Triangle-Based CSG.
- Next Session: Implement the "Adaptive Sampler" in `mesher.lua` to prove the sharp-edge reconstruction.
