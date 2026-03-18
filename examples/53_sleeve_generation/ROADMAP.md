# 🌙 Procedural Character Roadmap: Towards AAA Aesthetics

This document outlines the neuro-symbolic strategies for evolving our procedural mesh generator toward high-fidelity, stylized aesthetics (e.g., Genshin Impact style).

## 1. Advanced Cross-Section Expressiveness
*   **Beyond Fourier:** Transition from simple Fourier harmonics to **2D Bezier Splines** or **Superellipses** for ring shapes.
*   **Artistic Control:** Use neural network outputs to define 2D control points, allowing for sharp edges (shins), flat planes (backs), and stylized musculature.
*   **SDF Slicing:** Support 2D Signed Distance Fields for rings to mathematically define "half-triangle, half-circle" cross-sections.

## 2. Analytical Normal Decoupling
*   **Lighting vs. Geometry:** Decouple vertex normals from geometric orientation.
*   **Anime Shading:** Implement mathematical normal overrides (e.g., radial facial normals) to ensure crisp, hand-drawn shadow boundaries regardless of mesh density.
*   **Curated Tangents:** Pre-calculate tangents along the "bone-path" to support high-quality anisotropic highlights (hair/silk).

## 3. Layered Clothing & Shells
*   **Extrusion Shells:** Generate clothing as offset "shells" driven by the underlying body mesh.
*   **Gene-Based Masking:** Use a 0.0-1.0 "clothing mask" output from the generator to determine where the skin mesh extrudes into sleeves, boots, or armor.
*   **Seamless Topology:** Ensure clothing shares the same ring-structure as the body for perfect skinning and zero clipping.

## 4. Soft Body & Non-Skeletal Volumes
*   **Procedural Jiggle Bones:** Dynamically inject virtual bones with spring-physics into the hierarchy for hair, capes, and soft tissue.
*   **Gravity Modifiers:** Apply localized spatial functions to the Fourier/Bezier coefficients to model gravity-driven "droop" (glutes, breasts).
*   **Ribbon Generation:** Use the same skeletal-tube logic but with degenerate cross-sections to create flat, expressive hair ribbons and tassels.

## 5. Topological Integrity (In-Code Validation)
*   **Continuity Checkers:** Implement static analyzers that verify C0/C1 continuity at joint boundaries.
*   **Constraint Solvers:** Ensure that the radius and harmonic coefficients of the "End-Ring" of Bone A exactly match the "Start-Ring" of Bone B.
