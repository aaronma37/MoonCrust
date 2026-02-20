// 3. ORGANIC NERVOUS SYSTEM (Stochastic Transport)
void run_botany() {
    uint id = GET_ID(next);
    uint payload = GET_PAYLOAD(next);
    float r = rand(vec2(pos) + pc.time);

    // STOCHASTIC SIGNAL PROPAGATION
    if (id == 7) { // The Seed Heart
        payload = 255;
    } else if (id == 10 || id == 11 || id == 12) {
        // Pick ONE random neighbor to pull signal from (Random Walk logic)
        int dx = int(rand(vec2(pos.x, pc.time)) * 3.0) - 1;
        int dy = int(rand(vec2(pos.y, pc.time)) * 3.0) - 1;
        
        if (dx != 0 || dy != 0) {
            Pixel n = all_buffers[pc.in_buf_idx].cells[get_idx(pos + ivec2(dx, dy), pc.world_w, pc.world_h)];
            uint nid = GET_ID(n);
            if (nid == 10 || nid == 11 || nid == 7 || nid == 12) {
                uint n_signal = GET_PAYLOAD(n);
                // Stochastic "Pull": If neighbor has more hormone, take some.
                if (n_signal > payload) {
                    payload = uint(mix(float(payload), float(n_signal), 0.8));
                }
            }
        }
        // Continuous Metabolic Decay (Signal fades as it travels)
        if (payload > 0) payload--;
    }

    next.data1 = (next.data1 & 0xFFFF000Fu) | (payload << 4);

    // INTELLIGENT GROWTH (Based on Hormone Field)
    if (id == 12) {
        uint timer = GET_LIFE(next) & 0xFu;
        
        // APICAL DOMINANCE:
        // High Signal (200+) = We are inside the trunk. Don't grow, just maturate into Wood.
        // Mid Signal (50-200) = Active growth zone.
        // Low Signal (<50) = Too far. Maturate into Leaf.
        
        if (timer > 0) {
            if (r > 0.8) timer--;
            next.data1 = (next.data1 & 0xFFF0FFFFu) | (timer << 16);
        } else {
            if (payload > 180) {
                next.data0 = pack_data0(10, 128, 0, 0); // Becomes Trunk
            } else {
                next.data0 = pack_data0(11, 128, 0, 0); // Becomes Canopy
            }
        }
    }
}
