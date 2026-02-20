// 5. GLOBAL WEATHER & WIND
// Inject Rain at the top of the simulation window
if (id == 0 && pos.y == int(pc.cam_y)) {
    // 0.05% chance per pixel per frame (Much more reasonable)
    if (r > 0.9995) { 
        next.data0 = pack_data0(2, 128, 0, 0); // Water
        next.data1 = pack_data1(100, 0, 0, 0, 0);
    }
}

// Global Wind: Nudge non-static elements sideways
float wind_force = sin(pc.time * 0.5) * 0.4; 

if (id != 0 && (flags & 1u) == 0) {
    bool is_light = (density < 120);
    if (is_light && r < abs(wind_force)) {
        int wind_dir = (wind_force > 0) ? 1 : -1;
        ivec2 side = pos + ivec2(wind_dir, 0);
        Pixel s_pix = all_buffers[pc.in_buf_idx].cells[get_idx(side, pc.world_w, pc.world_h)];
        if (GET_ID(s_pix) == 0) {
            next = s_pix; 
        }
    }
}

if (id == 0) {
    int wind_dir = (wind_force > 0) ? 1 : -1;
    ivec2 source = pos - ivec2(wind_dir, 0);
    Pixel s_pix = all_buffers[pc.in_buf_idx].cells[get_idx(source, pc.world_w, pc.world_h)];
    if (GET_ID(s_pix) != 0 && (GET_FLAGS(s_pix) & 1u) == 0 && r < abs(wind_force)) {
        next = s_pix;
    }
}
