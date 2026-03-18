# 🌙 Architecture: "Born in Place" Dynamic Meshing

This document provides a detailed technical specification for the Neuro-Symbolic Character Engine. Unlike traditional game engines that use static meshes and weight-painted skinning, this engine generates a perfect, anatomically correct mesh **every single frame** on the GPU.

---

## 1. Core Philosophy: "Born in Place"
In traditional pipelines, a character is sculpted once (T-Pose) and then "deformed" to match a skeleton. This causes volume loss (pinching) and requires manual skin weight painting.

Our approach treats the mesh as a **mathematical envelope** generated from the *current* state of the skeleton. Vertices are not moved from a rest pose; they are **born in their final world-space position** for that specific frame.

### Key Benefits:
*   **Zero Volume Loss:** Joints (elbows, knees) use mathematical bisectors to maintain volume regardless of the bend angle.
*   **Zero Weight Painting:** Skinning is inherent to the generation process. A vertex created at distance $t$ along Bone $A$ is mathematically attached to Bone $A$ with zero manual labor.
*   **Procedural DNA:** Character proportions (muscle mass, height, torso shape) are just variables in an equation that can be changed in real-time.

---

## 2. The Per-Frame Lifecycle
Every 16.6ms (60fps), the engine executes the following pipeline:

### Phase A: Skeletal Update (CPU)
1.  **Animation Sampling:** Fetch local joint transforms from the DAE animation channels.
2.  **Global Forward Kinematics:** Calculate the world-space position of every joint in the hierarchy.
3.  **Joint Mitering (Bisectors):** For every joint connection (e.g., Upper Arm to Forearm), calculate the **Angle Bisector Plane**.
    *   The normal of this plane is the normalized average of the two bone directions.
    *   This plane ensures that the "rings" of the upper arm and forearm meet perfectly at the joint with zero gaps or "steps."

### Phase B: Metadata Upload (CPU -> GPU)
The CPU uploads a "Bone Buffer" to the GPU containing:
*   `start_pos`, `end_pos` (World space).
*   `plane_start`, `plane_end` (Normals for the ring orientation).
*   `Gene_ID`: Indices into a "Fourier Gene" buffer that defines the character's shape.

### Phase C: Procedural Meshing (GPU Compute Shader)
The `mesher.comp` shader executes in parallel for every vertex:
1.  **Orthonormal Basis:** For any point $t \in [0, 1]$ along a bone, it interpolates the start/end planes and generates a local $U, V$ coordinate system.
2.  **Fourier-Radial Expansion:** The radius $R$ at angle $\theta$ is calculated:
    $$R(\theta, t) = R_{base}(t) + \sum_{n=1}^{k} [a_n(t) \cos(n\theta) + b_n(t) \sin(n\theta)]$$
    *   **$n=1$ (Translation):** Pushes the ring center (Belly, Buttocks).
    *   **$n=2$ (Ovality):** Squashes/Stretches the ring (Torso, Forearm muscles).
    *   **$n=3+$ (Definition):** Adds complex musculature (Quads, Deltoids).
3.  **Position Calculation:** $V_{final} = Center(t) + R(\theta, t) \cdot (U \cos \theta + V \sin \theta)$.
4.  **Normal Calculation:** Calculated analytically from the Fourier derivative or via stable cross-products with neighbors.

### Phase D: Rasterization (GPU Graphics Pipeline)
1.  **Vertex Shader:** Acts as a simple passthrough. No heavy matrix skinning math is required because Phase C already placed the vertices in world space.
2.  **Fragment Shader:** Applies **Cel-Shading** with quantized diffuse lighting and decoupled "Anime Normals" for a crisp, hand-drawn look.

---

## 3. Procedural Clothing & Shells (The "Onion" Strategy)
Clothing is handled as a secondary pass or an offset within the same Compute Shader.

### Zero-Clipping Guarantee:
Because the clothes are generated as a mathematical offset of the body rings ($R_{cloth} = R_{body} + thickness$), it is impossible for the skin to clip through the fabric. 

### Layering Logic:
*   **Base Layer:** Skin (Humanoid Fourier coefficients).
*   **Shell Layer 1:** Undergarments (Offset 0.05).
*   **Shell Layer 2:** Outercoat (Offset 0.2 + high-frequency "wrinkle" harmonics at bent joints).

---

## 4. Analytical Normal Decoupling
One of the most important aspects of the "Genshin" aesthetic.
*   **Geometric Normals:** Used for physical interactions and depth.
*   **Lighting Normals:** Overridden in the shader. For example, the entire face mesh uses normals pointing outward from a single point in the center of the head. This removes "geometric noise" (like nose/eye socket shadows) and creates the clean, flat shadow planes seen in anime.

---

## 5. Future Extensions
*   **Jiggle Physics:** Inject virtual "spring" bones into the hierarchy before the Bisector phase to handle hair and capes.
*   **LOD Scaling:** Dynamically adjust `verts_per_ring` based on camera distance in the Compute Shader dispatch.
*   **Neural Refinement:** Feed the current bone angles into a small MLP to output the Fourier coefficients, allowing for automated "Muscle Bulging" based on pose.
