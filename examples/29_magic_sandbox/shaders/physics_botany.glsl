// 3. ORGANIC GROWTH & CIRCULATION
uint self_life = GET_LIFE(self);
bool hydrated = (flags & 4u) != 0;

if (id == 12) { // TREE GROWTH TIP
    uint timer = self_life & 0xFu;
    uint energy = self_life >> 4;

    // nutrient siphoning from wood below
    ivec2 below = pos + ivec2(0, 1);
    Pixel b_pix = all_buffers[pc.in_buf_idx].cells[get_idx(below, pc.world_w, pc.world_h)];
    if (GET_ID(b_pix) == 10 && (GET_FLAGS(b_pix) & 4u) != 0) {
        energy = clamp(energy + 5, 0, 15);
    }

    if (timer > 0) {
        next.data1 = pack_data1(150, (energy << 4) | (timer - 1), 0, 0, 1);
    } else {
        if (energy > 0) {
            next.data0 = pack_data0(10, 128, 0, 0); 
            next.data1 = pack_data1(200, 0, 0, 0, 1 | (hydrated ? 4 : 0));
        } else {
            next.data0 = pack_data0(11, 128, 0, 0);
            next.data1 = pack_data1(50, 20, 0, 0, 1);
        }
    }
}

if (id == 10) { // WOOD CAPILLARY
    // Absorb water from any neighbor
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            uint nid = GET_ID(all_buffers[pc.in_buf_idx].cells[get_idx(pos + ivec2(dx, dy), pc.world_w, pc.world_h)]);
            if (nid == 2) { next.data1 |= 4u; break; }
        }
    }
    // Siphon UP
    if (!hydrated) {
        Pixel b_pix = all_buffers[pc.in_buf_idx].cells[get_idx(pos + ivec2(0, 1), pc.world_w, pc.world_h)];
        if (GET_ID(b_pix) == 10 && (GET_FLAGS(b_pix) & 4u) != 0) next.data1 |= 4u;
    }
}

if (id == 0 || id == 11) { // GROWTH TRIGGERS
    bool pulled = false;
    // Standard growth (pulling from tip below)
    for (int dx = -1; dx <= 1; dx++) {
        Pixel n = all_buffers[pc.in_buf_idx].cells[get_idx(pos + ivec2(dx, 1), pc.world_w, pc.world_h)];
        if (GET_ID(n) == 12 && (GET_LIFE(n) >> 4) > 0) {
            if (r < 0.3) {
                next.data0 = pack_data0(12, 128, 0, 0);
                next.data1 = pack_data1(150, (((GET_LIFE(n) >> 4) - 1) << 4) | 5u, 0, 0, 1);
                pulled = true; break;
            }
        }
    }
    
    // NEW: SPROUTING TRIGGER (Wood + Water = New Tip)
    if (!pulled) {
        bool touching_wood = false;
        bool touching_water = false;
        for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
                uint nid = GET_ID(all_buffers[pc.in_buf_idx].cells[get_idx(pos + ivec2(dx, dy), pc.world_w, pc.world_h)]);
                if (nid == 10) touching_wood = true;
                if (nid == 2) touching_water = true;
            }
        }
        if (touching_wood && touching_water && r > 0.999) {
            next.data0 = pack_data0(12, 128, 0, 0);
            next.data1 = pack_data1(150, (10u << 4) | 5u, 0, 0, 1);
        }
    }
}
