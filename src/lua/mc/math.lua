local ffi = require("ffi")

local M = {}

-- 1. FFI Type Definitions
ffi.cdef[[
    typedef struct mc_vec2 { float x, y; } mc_vec2;
    typedef struct mc_vec3 { float x, y, z; } mc_vec3;
    typedef struct mc_vec4 { float x, y, z, w; } mc_vec4;
    typedef struct mc_mat4 { float m[16]; } mc_mat4;
]]

-- Pre-allocated internal scratchpad for math operations to avoid table churn
local scratch = {
    f = ffi.new("float[3]"),
    s = ffi.new("float[3]"),
    u = ffi.new("float[3]"),
    temp_mat = ffi.new("mc_mat4"),
}

function M.mat4_identity(out)
    local m = out or ffi.new("mc_mat4")
    for i=0,15 do m.m[i] = 0 end
    m.m[0], m.m[5], m.m[10], m.m[15] = 1, 1, 1, 1
    return m
end

function M.mat4_perspective(fovy, aspect, near, far, out)
    local f = 1.0 / math.tan(fovy / 2.0)
    local m = out or ffi.new("mc_mat4")
    for i=0,15 do m.m[i] = 0 end
    m.m[0] = f / aspect
    m.m[5] = -f 
    m.m[10] = far / (near - far)
    m.m[11] = -1.0
    m.m[14] = (near * far) / (near - far)
    return m
end

function M.mat4_look_at(eye, center, up, out)
    local f = scratch.f
    f[0], f[1], f[2] = center[1] - eye[1], center[2] - eye[2], center[3] - eye[3]
    local fn = math.sqrt(f[0]^2 + f[1]^2 + f[2]^2)
    if fn == 0 then return M.mat4_identity(out) end
    f[0], f[1], f[2] = f[0]/fn, f[1]/fn, f[2]/fn
    
    local s = scratch.s
    s[0] = f[1]*up[3] - f[2]*up[2]
    s[1] = f[2]*up[1] - f[0]*up[3]
    s[2] = f[0]*up[2] - f[1]*up[1]
    local sn = math.sqrt(s[0]^2 + s[1]^2 + s[2]^2)
    if sn == 0 then return M.mat4_identity(out) end
    s[0], s[1], s[2] = s[0]/sn, s[1]/sn, s[2]/sn
    
    local u = scratch.u
    u[0] = s[1]*f[2] - s[2]*f[1]
    u[1] = s[2]*f[0] - s[0]*f[2]
    u[2] = s[0]*f[1] - s[1]*f[0]
    
    local m = out or ffi.new("mc_mat4")
    m.m[0] = s[0]; m.m[1] = u[0]; m.m[2] = -f[0]; m.m[3] = 0
    m.m[4] = s[1]; m.m[5] = u[1]; m.m[6] = -f[1]; m.m[7] = 0
    m.m[8] = s[2]; m.m[9] = u[2]; m.m[10] = -f[2]; m.m[11] = 0
    m.m[12] = -(s[0]*eye[1] + s[1]*eye[2] + s[2]*eye[3])
    m.m[13] = -(u[0]*eye[1] + u[1]*eye[2] + u[2]*eye[3])
    m.m[14] = (f[0]*eye[1] + f[1]*eye[2] + f[2]*eye[3])
    m.m[15] = 1
    return m
end

function M.mat4_multiply(a, b, out)
    local c = out or ffi.new("mc_mat4")
    local res = (c == a or c == b) and scratch.temp_mat or c
    for j = 0, 3 do
        for i = 0, 3 do
            local sum = 0
            for k = 0, 3 do sum = sum + a.m[k*4 + i] * b.m[j*4 + k] end
            res.m[j*4 + i] = sum
        end
    end
    if res == scratch.temp_mat then ffi.copy(c, scratch.temp_mat, 64) end
    return c
end

function M.mat4_scale(s, out)
    local m = M.mat4_identity(out)
    m.m[0], m.m[5], m.m[10] = s, s, s
    return m
end

function M.mat4_ortho(left, right, bottom, top, near, far, out)
    local m = out or ffi.new("mc_mat4")
    for i=0,15 do m.m[i] = 0 end
    m.m[0] = 2.0 / (right - left)
    m.m[5] = 2.0 / (bottom - top)
    m.m[10] = 1.0 / (near - far)
    m.m[12] = -(right + left) / (right - left)
    m.m[13] = -(bottom + top) / (bottom - top)
    m.m[14] = near / (near - far)
    m.m[15] = 1.0
    return m
end

function M.mat4_inverse(m, out)
    local inv = out or ffi.new("mc_mat4")
    local s = m.m
    local b00 = s[0]*s[5] - s[1]*s[4]; local b01 = s[0]*s[6] - s[2]*s[4]; local b02 = s[0]*s[7] - s[3]*s[4]
    local b03 = s[1]*s[6] - s[2]*s[5]; local b04 = s[1]*s[7] - s[3]*s[5]; local b05 = s[2]*s[7] - s[3]*s[6]
    local b06 = s[8]*s[13] - s[9]*s[12]; local b07 = s[8]*s[14] - s[10]*s[12]; local b08 = s[8]*s[15] - s[11]*s[12]
    local b09 = s[9]*s[14] - s[10]*s[13]; local b10 = s[9]*s[15] - s[11]*s[13]
    local b11 = s[10]*s[15] - s[11]*s[14]
    local det = b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06
    if det == 0 then return M.mat4_identity(out) end
    local idet = 1.0 / det
    inv.m[0] = (s[5]*b11 - s[6]*b10 + s[7]*b09) * idet; inv.m[1] = (-s[1]*b11 + s[2]*b10 - s[3]*b09) * idet
    inv.m[2] = (s[13]*b05 - s[14]*b04 + s[15]*b03) * idet; inv.m[3] = (-s[9]*b05 + s[10]*b04 - s[11]*b03) * idet
    inv.m[4] = (-s[4]*b11 + s[6]*b08 - s[7]*b07) * idet; inv.m[5] = (s[0]*b11 - s[2]*b08 + s[3]*b07) * idet
    inv.m[6] = (-s[12]*b05 + s[14]*b02 - s[15]*b01) * idet; inv.m[7] = (s[8]*b05 - s[10]*b02 + s[11]*b01) * idet
    inv.m[8] = (s[4]*b10 - s[5]*b08 + s[7]*b06) * idet; inv.m[9] = (-s[0]*b10 + s[1]*b08 - s[3]*b06) * idet
    inv.m[10] = (s[12]*b04 - s[13]*b02 + s[15]*b00) * idet; inv.m[11] = (-s[8]*b04 + s[9]*b02 - s[11]*b00) * idet
    inv.m[12] = (-s[4]*b09 + s[5]*b07 - s[6]*b06) * idet; inv.m[13] = (s[0]*b09 - s[1]*b07 + s[2]*b06) * idet
    inv.m[14] = (-s[12]*b03 + s[13]*b01 - s[14]*b00) * idet; inv.m[15] = (s[8]*b03 - s[9]*b01 + s[10]*b00) * idet
    return inv
end

function M.rad(deg) return deg * (math.pi / 180.0) end

return M
