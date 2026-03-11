local M = {}

-- 1. Corrected Symbolic IK Solver (Handles per-limb orientations)
function M.solve_ik(target, upper_len, lower_len, is_leg)
    local tx, ty, tz = target[1], target[2], target[3]
    
    local dist = math.sqrt(tx*tx + ty*ty + tz*tz)
    dist = math.min(dist, upper_len + lower_len - 0.01)
    dist = math.max(dist, math.abs(upper_len - lower_len) + 0.01)
    
    local cos_lower = (upper_len*upper_len + lower_len*lower_len - dist*dist) / (2 * upper_len * lower_len)
    local angle_lower = math.acos(math.max(-1, math.min(1, cos_lower)))
    
    -- Pitch Calculation
    local angle_upper_pitch = math.atan2(-tz, -ty) 
    
    local cos_upper_off = (upper_len*upper_len + dist*dist - lower_len*lower_len) / (2 * upper_len * dist)
    local angle_upper_off = math.acos(math.max(-1, math.min(1, cos_upper_off)))
    
    if is_leg then
        -- LEGS: Standard atan2 works for downward-to-forward reach
        local angle_upper = angle_upper_pitch - angle_upper_off
        return { angle_upper, 0, 0 }, { (math.pi - angle_lower), 0, 0 }
    else
        -- ARMS: Need the negated pitch we confirmed earlier
        local angle_upper = -angle_upper_pitch + angle_upper_off
        return { angle_upper, 0, 0 }, { -(math.pi - angle_lower), 0, 0 }
    end
end

-- 2. Pose Definitions (-Z is Forward)
M.poses = {
    idle = {
        torso = { rot = {0, 0, 0}, pos = {0, 0, 0} },
        head = { rot = {0.1, 0, 0} },
        arm_l_target = {-0.5, -3.5, -0.8},
        arm_r_target = {0.5, -3.5, -0.8},
        staff_rot = {math.pi/2, 0, 0}, 
        leg_l_target = {0, -4.2, 0.1},
        leg_r_target = {0, -4.2, 0.1},
    },
    walk_a = {
        torso = { rot = {0.1, 0, 0.05}, pos = {0, 0.2, 0} },
        head = { rot = {-0.05, 0, 0} },
        arm_l_target = {0, -2.5, -1.5}, -- Swing Forward
        arm_r_target = {0, -3.0, 1.5},  -- Swing Back
        staff_rot = {math.pi/2 + 0.4, 0, 0},
        leg_l_target = {0, -3.8, 1.5},  -- Swing Back
        leg_r_target = {0, -3.5, -1.5}, -- Swing Forward
    },
    walk_b = {
        torso = { rot = {0.1, 0, -0.05}, pos = {0, 0.2, 0} },
        head = { rot = {-0.05, 0, 0} },
        arm_l_target = {0, -3.0, 1.5},
        arm_r_target = {0, -2.5, -1.5},
        staff_rot = {math.pi/2 - 0.4, 0, 0},
        leg_l_target = {0, -3.5, -1.5},
        leg_r_target = {0, -3.8, 1.5},
    },
    cast = {
        torso = { rot = {0.2, 0, 0}, pos = {0, -0.2, 0} },
        head = { rot = {-0.3, 0, 0} },
        arm_l_target = {-2.0, 1.0, -1.5},
        arm_r_target = {1.5, 3.5, -2.5},
        staff_rot = {0, 0, 0},
        leg_l_target = {0, -4.2, 0.2}, -- Stable stance
        leg_r_target = {0, -4.2, -0.2},
    }
}

function M.get_pose(time, state)
    local pose = {}
    local p1, p2, weight
    
    if state == "cast" then
        p1, p2, weight = M.poses.cast, M.poses.cast, 0
        p1.arm_r_target[2] = 3.5 + math.sin(time * 20.0) * 0.1
    elseif state == "walk" then
        local cycle = (time * 1.5) % 1.0
        if cycle < 0.5 then
            p1, p2, weight = M.poses.walk_a, M.poses.walk_b, cycle * 2
        else
            p1, p2, weight = M.poses.walk_b, M.poses.walk_a, (cycle - 0.5) * 2
        end
    else
        p1, p2, weight = M.poses.idle, M.poses.idle, 0
        p1.torso.pos[2] = math.sin(time * 2.0) * 0.1
    end
    
    local function lerp(a, b, w) return a + (b - a) * w end
    local function lerp_rot(a, b, w)
        local res = {}
        for i=1,3 do res[i] = lerp(a[i], b[i], w) end
        return res
    end

    pose.torso = { rot = lerp_rot(p1.torso.rot, p2.torso.rot, weight), pos = lerp_rot(p1.torso.pos, p2.torso.pos, weight) }
    pose.head = { rot = lerp_rot(p1.head.rot, p2.head.rot, weight), pos = {0,0,0} }
    
    local arm_up_l, arm_low_l = M.solve_ik(lerp_rot(p1.arm_l_target, p2.arm_l_target, weight), 2.0, 2.0, false)
    pose.arm_l_up = { rot = arm_up_l, pos = {0,0,0} }
    pose.arm_l_low = { rot = arm_low_l, pos = {0,0,0} }
    local arm_up_r, arm_low_r = M.solve_ik(lerp_rot(p1.arm_r_target, p2.arm_r_target, weight), 2.0, 2.0, false)
    pose.arm_r_up = { rot = arm_up_r, pos = {0,0,0} }
    pose.arm_r_low = { rot = arm_low_r, pos = {0,0,0} }
    
    local s_rot = lerp_rot(p1.staff_rot or {0,0,0}, p2.staff_rot or {0,0,0}, weight)
    pose.staff = { rot = s_rot, pos = {0,0,0} }
    
    local leg_up_l, leg_low_l = M.solve_ik(lerp_rot(p1.leg_l_target, p2.leg_l_target, weight), 2.2, 2.2, true)
    pose.leg_l_up = { rot = leg_up_l, pos = {0,0,0} }
    pose.leg_l_low = { rot = leg_low_l, pos = {0,0,0} }
    local leg_up_r, leg_low_r = M.solve_ik(lerp_rot(p1.leg_r_target, p2.leg_r_target, weight), 2.2, 2.2, true)
    pose.leg_r_up = { rot = leg_up_r, pos = {0,0,0} }
    pose.leg_r_low = { rot = leg_low_r, pos = {0,0,0} }

    local names = {"beard", "hat"}
    for _, n in ipairs(names) do if not pose[n] then pose[n] = {rot={0,0,0}, pos={0,0,0}} end end
    
    return pose
end

return M
