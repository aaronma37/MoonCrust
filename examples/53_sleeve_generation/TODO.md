# TODO: Example 53 - Multi-Asset & Sleeve Generation

## 1. Sleeve Generation (The "Onion Strategy")
- [ ] Update `mesher.lua` to include `cloth_pins` in `MeshRingParams`.
- [ ] Update `mesher.comp` to generate two layers of vertices using a layer offset.
- [ ] Implement puffy-sleeve logic (radial expansion) for arm segments.
- [ ] Add degenerate triangle handling for segments that don't have clothing.

## 2. SDF Head Refinement
- [ ] Increase Grid Resolution to 64x64x64.
- [ ] Implement QEF vertex placement for sharper features (Genshin chin/jawline).
- [ ] Author Eye and Hair SDFs in `head_sdf.glsl`.
- [ ] Add vertex color IDs to differentiate skin, eyes, and hair.

## 3. Pipeline & Performance
- [ ] Move toward a Mega-Buffer pool for all generated assets.
- [ ] Implement `is_static` check to skip compute dispatch for assets that haven't changed.
- [ ] Clean up magenta debug coloring and restore PBR/Cel shading.

## 4. Advanced Features
- [ ] Soft Body / Jiggle bones for hair and clothing.
- [ ] SDF-based "Gravity Droop" for soft tissues.
