struct Pixel {
    uint data0; // [ID:8][Temp:8][VX:8][VY:8]
    uint data1; // [Density:8][Life:8][Trigger:4][Payload:8][Flags:4]
};

#define GET_ID(p) ((p.data0 >> 24) & 0xFFu)
#define GET_TEMP(p) ((p.data0 >> 16) & 0xFFu)
#define GET_DENSITY(p) ((p.data1 >> 24) & 0xFFu)
#define GET_LIFE(p) ((p.data1 >> 16) & 0xFFu)
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
