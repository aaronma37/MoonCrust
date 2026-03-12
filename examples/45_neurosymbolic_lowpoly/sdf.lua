local M = {}

local function length(x, y, z) return math.sqrt(x*x + y*y + z*z) end

-- 1. ANATOMICAL PRIMITIVES
function M.sd_anatomical_capsule(px, py, pz, ax, ay, az, bx, by, bz, rx, rz, profile_type)
    local pax, pay, paz = px - ax, py - ay, pz - az
    local bax, bay, baz = bx - ax, by - ay, bz - az
    local h = (pax*bax + pay*bay + paz*baz) / (bax*bax + bay*bay + baz*baz + 1e-6)
    if h < 0 then h = 0 elseif h > 1 then h = 1 end
    local lpx, lpy, lpz = pax - bax*h, pay - bay*h, paz - baz*h
    local scale = 1.0
    if profile_type == "muscle" then scale = 0.8 + 0.4 * math.sin(h * math.pi)
    elseif profile_type == "taper" then scale = 1.0 - 0.5 * h
    elseif profile_type == "bell" then scale = 0.8 + 1.2 * (h * h) end
    local dx, dy, dz = lpx / (rx * scale), lpy / (rz * scale), lpz / (rz * scale)
    return length(dx, dy, dz) * math.min(rx, rz) * scale - 1.0
end

function M.sd_sphere(px, py, pz, r) return length(px, py, pz) - r end

function M.sd_box(px, py, pz, bx, by, bz)
    local qx, qy, qz = math.abs(px)-bx, math.abs(py)-by, math.abs(pz)-bz
    return length(math.max(qx,0), math.max(qy,0), math.max(qz,0)) + math.min(math.max(qx,math.max(qy,qz)), 0.0)
end

function M.sd_torus(px, py, pz, tx, ty)
    local qx = length(px, 0, pz) - tx
    return length(qx, py, 0) - ty
end

-- 2. OPERATORS
function M.op_smooth_union(d1, d2, k)
    local h = 0.5 + 0.5 * (d2 - d1) / k
    if h < 0 then h = 0 elseif h > 1 then h = 1 end
    return (1.0 - h) * d2 + h * d1 - k * h * (1.0 - h)
end

function M.op_subtract(d1, d2) return math.max(-d1, d2) end

-- 3. PROFILING (Anatomical taper/bulge)
function M.profile_muscle(t) return 0.8 + 0.4 * math.sin(t * math.pi) end
function M.profile_taper(t) return 1.0 - 0.4 * t end
function M.profile_bell(t) return 1.0 + 0.8 * (t * t) end

return M
