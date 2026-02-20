// LOCAL SIMULATED ANNEALING (HAMILTONIAN HYBRID + HIERARCHICAL CONSTRUCTION)

float calculate_energy(Pixel p, ivec2 at_pos, uint in_buf_idx, ivec2 partner_pos) {
    uint id = GET_ID(p);
    if (id == 0) return 0.0;

    float mass = get_mass(id);
    // 1. GRAVITATIONAL ENERGY
    float e_grav = -mass * float(at_pos.y) * 1.0;
    
    // 2. KINETIC ENERGY
    vec2 v = vec2(GET_VX(p), GET_VY(p));
    float e_kin = -dot(v, vec2(at_pos)) * 0.5;

    // 3. PHOTOTROPISM
    float e_light = 0.0;
    if (id == 7 || id == 12) {
        uint age = GET_LIFE(p);
        if (id == 7 && age > 150) {
            float center_x = float(pc.world_w) / 2.0;
            float horiz_bias = (pos.x % 200 > 100) ? 1.0 : -1.0;
            e_light = float(at_pos.x) * horiz_bias * 30.0;
            e_light += float(at_pos.y) * 20.0;
        } else {
            e_light = float(at_pos.y) * 100.0; 
        }
    }

    // 4. BOND ENERGY
    float e_bond = 0.0;
    uint temp = GET_TEMP(p);
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            ivec2 npos = at_pos + ivec2(dx, dy);
            if (npos == partner_pos) continue; 

            Pixel n = all_buffers[in_buf_idx].cells[get_idx(npos, pc.world_w, pc.world_h)];
            e_bond += get_bond(id, GET_ID(n), temp, GET_TEMP(n), ivec2(dx, dy), p, n);
        }
    }
    
    return e_grav + e_kin + e_bond + e_light;
}

void main_sa() {
    uint idx = pos.y * pc.world_w + pos.x;
    Pixel self = all_buffers[pc.in_buf_idx].cells[idx];
    uint id = GET_ID(self);
    uint flags = GET_FLAGS(self);

    // 1. UPDATE VELOCITY (Physics Kernel)
    if (id != 0 && (flags & 1u) == 0) {
        float mass = get_mass(id);
        float vx = float(GET_VX(self));
        float vy = float(GET_VY(self));
        
        // Gravity
        if (mass > 0 && vy < 16.0) vy += 0.5;
        if (mass < 0 && vy > -16.0) vy -= 0.5;
        
        // DRAG: Material-specific friction
        float drag = (id == 1) ? 0.6 : 0.95; // Sand has heavy friction (0.6)
        vx *= drag;
        vy *= drag;
        
        self.data0 = pack_data0(id, GET_TEMP(self), int(vx), int(vy));
    }

    // BRANCH NODE SPAWNER (A stationary heart that buds tips)
    if (id == 16) {
        if (rand(vec2(pos) + pc.time) > 0.99) { // 1% chance per frame to sprout
            // Look for adjacent Air
            for (int dy = -1; dy <= 1; dy++) {
                for (int dx = -1; dx <= 1; dx++) {
                    ivec2 tpos = pos + ivec2(dx, dy);
                    uint tidx = get_idx(tpos, pc.world_w, pc.world_h);
                    Pixel tp = all_buffers[pc.in_buf_idx].cells[tidx];
                    if (GET_ID(tp) == 0) {
                        // Sprout a new Growth Tip!
                        Pixel tip;
                        tip.data0 = pack_data0(12, 128, dx * 2, dy * 2);
                        tip.data1 = pack_data1(150, 255, 0, 0, 1);
                        all_buffers[pc.out_buf_idx].cells[tidx] = tip;
                        // Branch nodes are "Static" but they keep existing
                        break;
                    }
                }
            }
        }
        next = self;
        all_buffers[pc.out_buf_idx].cells[idx] = next;
        return;
    }

    // SYMMETRIC PAIR SELECTION
    int phase = int(pc.frame_count % 4);
    ivec2 target_offset = ivec2(0, 0);
    if (phase == 0) target_offset.x = (pos.x % 2 == 0) ? 1 : -1;
    else if (phase == 1) target_offset.y = (pos.y % 2 == 0) ? 1 : -1;
    else if (phase == 2) target_offset.x = ((pos.x + 1) % 2 == 0) ? 1 : -1;
    else if (phase == 3) target_offset.y = ((pos.y + 1) % 2 == 0) ? 1 : -1;

    ivec2 target_pos = pos + target_offset;
    if (target_pos.x < 0 || target_pos.x >= int(pc.world_w) || target_pos.y < 0 || target_pos.y >= int(pc.world_h)) {
        next = self; return;
    }
    
    uint target_idx = target_pos.y * pc.world_w + target_pos.x;
    Pixel other = all_buffers[pc.in_buf_idx].cells[target_idx];
    uint oid = GET_ID(other);

    float e_current = calculate_energy(self, pos, pc.in_buf_idx, target_pos) + calculate_energy(other, target_pos, pc.in_buf_idx, pos);
    float e_proposed = calculate_energy(self, target_pos, pc.in_buf_idx, pos) + calculate_energy(other, pos, pc.in_buf_idx, target_pos);
    
    float delta_e = e_proposed - e_current;
    float t_sys = (float(GET_TEMP(self) + GET_TEMP(other)) / 255.0) * 5.0 + 0.1;
    
    bool do_swap = false;
    if (delta_e < -0.1) do_swap = true;
    else if (abs(delta_e) < 0.01) { 
        // STABILITY BIAS: Sand is more static/heavy
        float bias = (id == 1 || oid == 1) ? 0.01 : 0.05;
        if (rand(vec2(pos) + pc.time) < bias) do_swap = true; 
    }
    else { if (rand(vec2(pos) + pc.time) < exp(-delta_e / t_sys)) do_swap = true; }

    if (do_swap) {
        if (id == 7 && oid == 0) {
            uint age = GET_LIFE(self);
            if (age > 80 && rand(vec2(pos) + pc.time) > 0.98) {
                // DROP A BRANCH NODE: Seed turns into a permanent spawner
                next.data0 = pack_data0(16, 128, 0, 0);
                next.data1 = pack_data1(255, 0, 0, 0, 1);
            } else {
                // Standard Trunk
                next.data0 = pack_data0(14, 128, 0, 0);
                next.data1 = pack_data1(255, 0, 0, 0, 1);
            }
        }
        else if (id == 0 && oid == 7) {
            uint age = GET_LIFE(other);
            if (age < 255) { if (age < 150 || (pc.frame_count % 20 == 0)) age++; }
            next.data0 = pack_data0(7, 128, 0, 0);
            next.data1 = pack_data1(100, age, 0, 0, 0);
        }
        else if (id == 12 && oid == 0) {
            uint life = GET_LIFE(self);
            if (life > 0 && (pc.frame_count % 10 == 0)) life--; 
            if (life > 40) {
                next.data0 = pack_data0(10, 128, 0, 0);
                next.data1 = pack_data1(200, 0, 0, 0, 1);
            } else {
                next.data0 = pack_data0(11, 128, 0, 0);
                next.data1 = pack_data1(50, 0, 0, 0, 1);
            }
        }
        else if (id == 0 && oid == 12) {
            uint life = GET_LIFE(other);
            if (life > 0 && (pc.frame_count % 10 == 0)) life--;
            next.data0 = pack_data0(12, 128, 0, 0);
            next.data1 = (other.data1 & 0xFF00FFFFu) | (life << 16);
        }
        else {
            next = other;
        }
    } else {
        next = self;
        // DYNAMIC FREEZING: If not moving, cool down rapidly
        uint t = GET_TEMP(next);
        if (id == 1) { // Sand cools very fast
            if (t > 5) t -= 5; else t = 0;
        } else {
            if (t > 0 && (pc.frame_count % 10 == 0)) t--;
        }
        
        // If temperature is 0 and we are sand, lose all velocity
        int vx = GET_VX(next); int vy = GET_VY(next);
        if (t == 0 && id == 1) { vx = 0; vy = 0; }
        
        next.data0 = pack_data0(id, t, vx, vy);
    }
    
    all_buffers[pc.out_buf_idx].cells[idx] = next;
}
