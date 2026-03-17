# Anime Stylization Roadmap (Genshin Style)

This document outlines the technical strategy for achieving a high-fidelity anime aesthetic using MoonCrust's GPU Dual Contouring and Forward+ pipeline.

## 💇 1. Procedural Hair (Current Task)
Anime hair is defined by sharp clumps and specific specular behaviors.
- **Geometry**: Represent hair as a collection of "clumps" using tapered SDF Capsules or Ellipsoids.
- **Blending**: Use `opSmoothUnion` within the Hair ID to merge clumps into a single mass, but use a hard `min()` against the skin to maintain a clean scalp line.
- **Shading (Anisotropic)**: Implement a "Hair Sheen" (Angel Ring) using the tangent of the hair flow instead of standard normals.
- **Outlines**: Use a thinner Inverted Hull specifically for hair clumps to maintain detail without clutter.

## 👁️ 2. Expressive Eyes
Eyes must remain clear and vibrant regardless of the character's lighting environment.
- **Material ID**: Assign a unique ID for the eye region.
- **Unlit Shading**: Bypass the light-ramp quantization; eyes should maintain their base brightness and color.
- **Parallax Mapping**: Use the material ID to "project" pupil and iris depth into the flat geometry of the face.
- **Static Highlights**: Eye glints should be procedurally generated in the fragment shader to stay fixed relative to the viewer.

## 🍑 3. Soft Body & Secondary Motion
Deformation and jiggle add "life" and weight to the character.
- **Jiggle Bones**: Add leaf bones parented to the main skeleton (e.g., for hair, accessories, or soft tissue).
- **Physics Sim (Lua)**: Use a simple spring-mass or XPBD simulation in the Lua `update` loop to drive these bones based on character velocity and inertia.
- **Automatic Binding**: Rely on the existing `field.comp` distance-based weighting to bind the generated mesh to these dynamic bones.
- **Subsurface Scattering (SSS) Approximation**: For soft skin areas, use a slightly wider transition (smoother ramp) between the light and shadow tones.

## 🎨 4. Global Cel-Shading
- **Forward+ Light Integration**: Ensure the 3-tone quantization applies to all point/spot lights in the scene.
- **Tone Ramp**: Use a 3-step quantized diffuse (Highlight, Mid, Shadow).
- **Inverted Hull Outlines**: Extrude vertices along normals in a second pass with front-face culling.
- **Saturation Boost**: Maintain high vibrance in mid-tones to match the anime color palette.
