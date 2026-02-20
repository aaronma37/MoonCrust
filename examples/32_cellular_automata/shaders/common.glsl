struct Pixel {
    uint data0; // [ID:8][Temp:8][VX:8][VY:8]
    uint data1; // [Density:8][Life:8][Trigger:4][Payload:8][Flags:4]
};

#define GET_ID(p) ((p.data0 >> 24) & 0xFFu)
#define GET_TEMP(p) ((p.data0 >> 16) & 0xFFu)
#define GET_VX(p) ((int((p.data0 >> 8) & 0xFFu) ^ 128) - 128)
#define GET_VY(p) ((int(p.data0 & 0xFFu) ^ 128) - 128)
#define GET_DENSITY(p) ((p.data1 >> 24) & 0xFFu)
#define GET_LIFE(p) ((p.data1 >> 16) & 0xFFu)
#define GET_PAYLOAD(p) ((p.data1 >> 4) & 0xFFu)
#define GET_FLAGS(p) (p.data1 & 0x0Fu)

// FLAG DEFINITIONS
// Bit 0: IS_STATIC (Defies gravity)
// Bit 1: HAS_BACKWALL (Visual depth)
// Bit 2: IS_HYDRATED (Wood carrying water)

uint pack_data0(uint id, uint temp, int vx, int vy) {
    return (id << 24) | ((temp & 0xFFu) << 16) | ((uint(vx) & 0xFFu) << 8) | (uint(vy) & 0xFFu);
}

uint pack_data1(uint density, uint life, uint trigger, uint payload, uint flags) {
    return ((density & 0xFFu) << 24) | ((life & 0xFFu) << 16) | ((trigger & 0x0Fu) << 12) | ((payload & 0xFFu) << 4) | (flags & 0x0Fu);
}

float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
uint get_idx(ivec2 p, uint w, uint h) { return clamp(p.y, 0, int(h-1)) * w + clamp(p.x, 0, int(w-1)); }

// SIMULATED ANNEALING CONSTANTS
float get_mass(uint id) {
    if (id == 0) return 0.0; // Air
    if (id == 1) return 1.5;  // Sand
    if (id == 2) return 1.0;  // Water
    if (id == 3) return -0.5; // Fire
    if (id == 4) return -0.2; // Steam
    if (id == 5) return 2.0;  // Lava
    if (id == 6) return 10.0; // Stone
    if (id == 7) return 0.1;  // Seed (Lightweight for mobility)
    if (id == 10) return 5.0; // Wood
    if (id == 14) return 20.0; // Trunk (Very Heavy/Solid)
    if (id == 16) return 15.0; // Branch Node
    if (id == 11) return 0.2; // Leaf
    if (id == 12) return 0.5; // Growth Tip
    return 1.0;
}

float get_bond(uint id1, uint id2, uint temp1, uint temp2, ivec2 offset, Pixel p1, Pixel p2) {
    if (id1 == 0 || id2 == 0) {
        // DYNAMIC SEED ATTRACTION
        if (id1 == 7 || id2 == 7) {
            Pixel s = (id1 == 7) ? p1 : p2;
            uint age = GET_LIFE(s);
            vec2 heading = vec2(GET_VX(s), GET_VY(s));
            
            // Phase 1: High Upward Bias
            float up_bias = (age < 120) ? -80.0 : -20.0;
            // Phase 2: Heading Persistence (Attracted to its own trajectory)
            float inertia = dot(heading, vec2(offset)) * -30.0;
            
            if (offset.y == -1) return up_bias + inertia;
            return -15.0 + inertia;
        }
        // GROWTH TIP ATTRACTION
        if (id1 == 12 || id2 == 12) return -15.0;
        return 0.0;
    }
    
    float t_factor = 1.0 - (float(temp1 + temp2) / 510.0);
    if (t_factor < 0.2) t_factor = -1.0; 

    // Self-bonding (Cohesion)
    if (id1 == id2) {
        if (id1 == 1) return -4.0 * t_factor; 
        if (id1 == 2) return -0.3 * t_factor; 
        if (id1 == 6) return -100.0 * t_factor; 
        if (id1 == 7) return 50.0; // Seeds repel each other (forced branching)
        
        if (id1 == 10) { 
            if (offset.x == 0) return -100.0 * t_factor;
            if (abs(offset.x) == 1 && abs(offset.y) == 1) return -60.0 * t_factor; // Diagonal Grain
            return -5.0 * t_factor;
        }

        if (id1 == 14) { 
            // SUPER STRONG TRUNK GRAIN
            if (offset.x == 0) return -250.0 * t_factor;
            return -20.0 * t_factor;
        }

        if (id1 == 16) {
            // BRANCH NODES are stable in all directions
            return -150.0 * t_factor;
        }
        
        if (id1 == 11) return -1.0 * t_factor;  
        if (id1 == 12) return 20.0; 
        return -1.0 * t_factor;
    }
    
    // Specific Interactions
    if ((id1 == 7 && id2 == 10) || (id1 == 10 && id2 == 7)) return -80.0 * t_factor; 
    if ((id1 == 7 && id2 == 14) || (id1 == 14 && id2 == 7)) return -120.0 * t_factor; // Stronger heart anchor
    if ((id1 == 10 && id2 == 14) || (id1 == 14 && id2 == 10)) return -100.0 * t_factor; 
    if ((id1 == 16 && (id2 == 14 || id2 == 10)) || (id2 == 16 && (id1 == 14 || id1 == 10))) return -120.0 * t_factor;
    if ((id1 == 10 && id2 == 11) || (id1 == 11 && id2 == 10)) return -20.0 * t_factor; 
    
    return 0.0;
}
