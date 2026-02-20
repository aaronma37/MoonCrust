// UNIFIED MOTION KERNEL (Sand, Water, Fire, Displacement)
bool is_static = (flags & 1u) != 0;

if (id != 0 && !is_static) {
    // 1. ATTEMPT TO MOVE (Source Pixel Logic)
    ivec2 below = pos + ivec2(0, 1);
    Pixel b_pix = all_buffers[pc.in_buf_idx].cells[get_idx(below, pc.world_w, pc.world_h)];
    uint bid = GET_ID(b_pix);
    uint b_dens = GET_DENSITY(b_pix);
    bool b_static = (GET_FLAGS(b_pix) & 1u) != 0;

    // Standard Gravity: Fall if below is lighter and not static
    if (!b_static && b_dens < density) {
        next = b_pix; 
    } 
    // Liquid Leveling: If we are water and can't fall, try sideways
    else if (id == 2) {
        int dir = (r > 0.5) ? 1 : -1;
        ivec2 side = pos + ivec2(dir, 0);
        ivec2 diag = pos + ivec2(dir, 1);
        Pixel s_pix = all_buffers[pc.in_buf_idx].cells[get_idx(side, pc.world_w, pc.world_h)];
        Pixel d_pix = all_buffers[pc.in_buf_idx].cells[get_idx(diag, pc.world_w, pc.world_h)];
        
        if (GET_ID(d_pix) == 0) next = d_pix;
        else if (GET_ID(s_pix) == 0) next = s_pix;
    }
}

// 2. DISPLACEMENT (Destination Pixel Logic)
// If we are currently Air, check if something from above/side wants to move here
if (id == 0) {
    // Check neighbors in order of priority: Directly Above > Diagonals > Sides
    ivec2 neighbors[5] = {ivec2(0,-1), ivec2(-1,-1), ivec2(1,-1), ivec2(-1,0), ivec2(1,0)};
    for(int i=0; i<5; i++) {
        ivec2 npos = pos + neighbors[i];
        Pixel n = all_buffers[pc.in_buf_idx].cells[get_idx(npos, pc.world_w, pc.world_h)];
        uint nid = GET_ID(n);
        uint nflags = GET_FLAGS(n);
        uint ndens = GET_DENSITY(n);

        if (nid != 0 && (nflags & 1u) == 0) {
            // Priority check for diagonal/side movement to prevent "cloning"
            bool will_move = false;
            if (i == 0) will_move = true; // Directly above always falls in
            else if (i < 3 && r > 0.7) will_move = true; // Diagonal jitter
            else if (nid == 2 && r > 0.9) will_move = true; // Liquid leveling jitter

            if (will_move) {
                next = n;
                break;
            }
        }
    }
}
