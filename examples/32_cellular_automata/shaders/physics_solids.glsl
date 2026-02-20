// 2. SOLID / GRAIN PHYSICS (Sand, Dirt)
if (id == 1 && (flags & 1u) == 0) { // Sand (non-static)
    ivec2 below = pos + ivec2(0, 1);
    Pixel b_pix = all_buffers[pc.in_buf_idx].cells[get_idx(below, pc.world_w, pc.world_h)];
    
    if (GET_ID(b_pix) == 0 || GET_DENSITY(b_pix) < density) {
        next = b_pix;
    } else {
        int dir = (r > 0.5) ? 1 : -1;
        ivec2 diag = pos + ivec2(dir, 1);
        Pixel d_pix = all_buffers[pc.in_buf_idx].cells[get_idx(diag, pc.world_w, pc.world_h)];
        if (GET_ID(d_pix) == 0 || GET_DENSITY(d_pix) < density) {
            next = d_pix;
        }
    }
}
