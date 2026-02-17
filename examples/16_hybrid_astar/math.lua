local M = {}

function M.identity()
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
end

function M.perspective(fovy, aspect, near, far)
    local f = 1.0 / math.tan(fovy / 2.0)
    local m = {}
    for i=1,16 do m[i] = 0 end
    
    m[1] = f / aspect
    m[6] = f
    m[11] = far / (near - far)
    m[12] = -1.0
    m[15] = (near * far) / (near - far)
    m[16] = 0
    return m
end

function M.look_at(eye, center, up)
    local f = { center[1] - eye[1], center[2] - eye[2], center[3] - eye[3] }
    local fn = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
    f[1], f[2], f[3] = f[1]/fn, f[2]/fn, f[3]/fn

    local s = { f[2]*up[3] - f[3]*up[2], f[3]*up[1] - f[1]*up[3], f[1]*up[2] - f[2]*up[1] }
    local sn = math.sqrt(s[1]^2 + s[2]^2 + s[3]^2)
    s[1], s[2], s[3] = s[1]/sn, s[2]/sn, s[3]/sn

    local u = { s[2]*f[3] - s[3]*f[2], s[3]*f[1] - s[1]*f[3], s[1]*f[2] - s[2]*f[1] }

    local m = M.identity()
    -- Column 0
    m[1] = s[1]
    m[2] = u[1]
    m[3] = -f[1]
    m[4] = 0
    -- Column 1
    m[5] = s[2]
    m[6] = u[2]
    m[7] = -f[2]
    m[8] = 0
    -- Column 2
    m[9] = s[3]
    m[10] = u[3]
    m[11] = -f[3]
    m[12] = 0
    -- Column 3
    m[13] = -(s[1]*eye[1] + s[2]*eye[2] + s[3]*eye[3])
    m[14] = -(u[1]*eye[1] + u[2]*eye[2] + u[3]*eye[3])
    m[15] = (f[1]*eye[1] + f[2]*eye[2] + f[3]*eye[3])
    m[16] = 1
    return m
end

function M.multiply(a, b)
    local c = {}
    for j = 0, 3 do -- Column of B
        for i = 0, 3 do -- Row of A
            local sum = 0
            for k = 0, 3 do
                sum = sum + a[k*4 + i + 1] * b[j*4 + k + 1]
            end
            c[j*4 + i + 1] = sum
        end
    end
    return c
end

return M
