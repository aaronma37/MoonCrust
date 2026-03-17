local mc = require("mc")
local ffi = require("ffi")

local M = {}

local function pack_color(r, g, b)
	local ir = math.floor(r * 255)
	local ig = math.floor(g * 255)
	local ib = math.floor(b * 255)
	return bit.bor(bit.lshift(ir, 16), bit.lshift(ig, 8), ib)
end

-- --- ANTHROPOMETRIC DATA ---
local HEIGHT = 1.8
local H = HEIGHT / 8.0

local DATA = {
	head_w = 0.75 * H,
	head_h = 1.0 * H,
	head_d = 0.9 * H,
	shoulder_w = 2.0 * H,
	chest_w = 1.4 * H,
	chest_d = 0.9 * H,
	waist_w = 0.9 * H,
	waist_d = 0.7 * H,
	hip_w = 1.1 * H,
	pelvis_d = 0.7 * H,
	upper_arm_l = 1.25 * H,
	lower_arm_l = 1.0 * H,
	upper_leg_l = 2.0 * H,
	lower_leg_l = 1.75 * H,
	neck_r = 0.18 * H,
}

function M.create_skeleton()
	local tree = {
		root = { parent = nil, offset = { 0, 0.85, 0 }, rot = { 0, 0, 0 }, base_offset = { 0, 0.85, 0 } },
		spine = { parent = "root", offset = { 0, 0.15, 0 }, rot = { 0, 0, 0 } },
		neck = { parent = "spine", offset = { 0, 0.35, 0 }, rot = { 0, 0, 0 } },
		head = { parent = "neck", offset = { 0, 0.1, 0 }, rot = { 0, 0, 0 } },
		shoulder_L = { parent = "spine", offset = { -0.17, 0.2, 0.0 }, rot = { 0, 0, 0 }, length = DATA.upper_arm_l },
		arm_upper_L = {
			parent = "shoulder_L",
			offset = { 0, -DATA.upper_arm_l, 0 },
			rot = { 0, 0, 0 },
			length = DATA.lower_arm_l,
		},
		arm_lower_L = { parent = "arm_upper_L", offset = { 0, -DATA.lower_arm_l, 0 }, rot = { 0, 0, 0 } },
		hand_L = { parent = "arm_lower_L", offset = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
		shoulder_R = { parent = "spine", offset = { 0.17, 0.2, 0.0 }, rot = { 0, 0, 0 }, length = DATA.upper_arm_l },
		arm_upper_R = {
			parent = "shoulder_R",
			offset = { 0, -DATA.upper_arm_l, 0 },
			rot = { 0, 0, 0 },
			length = DATA.lower_arm_l,
		},
		arm_lower_R = { parent = "arm_upper_R", offset = { 0, -DATA.lower_arm_l, 0 }, rot = { 0, 0, 0 } },
		hand_R = { parent = "arm_lower_R", offset = { 0, -0.1, 0 }, rot = { 0, 0, 0 } },
		hip_L = { parent = "root", offset = { -0.35 * H, -0.05, 0 }, rot = { 0, 0, 0 }, length = DATA.upper_leg_l },
		leg_upper_L = {
			parent = "hip_L",
			offset = { 0, -DATA.upper_leg_l, 0 },
			rot = { 0, 0, 0 },
			length = DATA.lower_leg_l,
		},
		leg_lower_L = { parent = "leg_upper_L", offset = { 0, -DATA.lower_leg_l, 0 }, rot = { 0, 0, 0 } },
		foot_L = { parent = "leg_lower_L", offset = { 0, -0.05, 0.05 }, rot = { 0, 0, 0 } },
		hip_R = { parent = "root", offset = { 0.35 * H, -0.05, 0 }, rot = { 0, 0, 0 }, length = DATA.upper_leg_l },
		leg_upper_R = {
			parent = "hip_R",
			offset = { 0, -DATA.upper_leg_l, 0 },
			rot = { 0, 0, 0 },
			length = DATA.lower_leg_l,
		},
		leg_lower_R = { parent = "leg_upper_R", offset = { 0, -DATA.lower_leg_l, 0 }, rot = { 0, 0, 0 } },
		foot_R = { parent = "leg_lower_R", offset = { 0, -0.05, 0.05 }, rot = { 0, 0, 0 } },
	}
	local order = {
		"root",
		"spine",
		"neck",
		"head",
		"shoulder_L",
		"arm_upper_L",
		"arm_lower_L",
		"hand_L",
		"shoulder_R",
		"arm_upper_R",
		"arm_lower_R",
		"hand_R",
		"hip_L",
		"leg_upper_L",
		"leg_lower_L",
		"foot_L",
		"hip_R",
		"leg_upper_R",
		"leg_lower_R",
		"foot_R",
	}
	return tree, order
end

function M.apply_pose(tree, time, state)
	for k, v in pairs(tree) do
		v.rot = { 0, 0, 0 }
	end
	tree.shoulder_L.rot[3] = 0.35
	tree.shoulder_R.rot[3] = -0.35
	if state == "rest" then
		-- T-Pose Flare (to prevent webbing)
		tree.hip_L.rot[3] = 0.3
		tree.hip_R.rot[3] = -0.3
	elseif state == "walk" then
		local t = time * 5.0
		tree.root.rot[2] = math.sin(t) * 0.12
		tree.root.rot[3] = math.cos(t) * 0.04
		tree.hip_L.rot[1] = math.sin(t) * 0.6
		tree.hip_R.rot[1] = math.sin(t + math.pi) * 0.6
		tree.leg_upper_L.rot[1] = -math.max(0, math.sin(t + 1.2)) * 1.1
		tree.leg_upper_R.rot[1] = -math.max(0, math.sin(t + math.pi + 1.2)) * 1.1
		tree.leg_lower_L.rot[1] = -tree.hip_L.rot[1] - tree.leg_upper_L.rot[1] + 0.1
		tree.leg_lower_R.rot[1] = -tree.hip_R.rot[1] - tree.leg_upper_R.rot[1] + 0.1
		tree.spine.rot[2] = -tree.root.rot[2] * 0.8
		tree.shoulder_L.rot[1] = math.sin(t + math.pi) * 0.4
		tree.shoulder_R.rot[1] = math.sin(t) * 0.4
		tree.arm_upper_L.rot[1] = math.max(0, math.sin(t + math.pi + 0.5)) * 0.6
		tree.arm_upper_R.rot[1] = math.max(0, math.sin(t + 0.5)) * 0.6
	end
end

local equipment_lib = {
	helmets = {
		bucket = function(sdfs)
			local m, dm = pack_color(0.6, 0.6, 0.65), pack_color(0.3, 0.3, 0.35)
			table.insert(sdfs, {
				bone = "head",
				type = "capsule",
				id = 10,
				color = m,
				params = { 0.12, -0.05, 0.05, 0.01 },
				offset = { 0, 0, 0 },
			})
			table.insert(sdfs, {
				bone = "head",
				type = "box",
				id = 11,
				color = dm,
				params = { 0.08, 0.02, 0.04, 0.0 },
				offset = { 0, 0.02, 0.1 },
			})
		end,
	},
	right_hand = {
		sword = function(sdfs)
			local m = pack_color(0.6, 0.6, 0.65)
			table.insert(sdfs, {
				bone = "hand_R",
				type = "box",
				id = 17,
				color = m,
				params = { 0.02, 0.4, 0.05, 0.0 },
				offset = { 0, -0.3, 0.1 },
			})
		end,
	},
}

function M.equip_character(tree, loadout, time)
	local grouped = {}
	local body_color = pack_color(0.8, 0.7, 0.6)
	local debug_red = pack_color(1, 0, 0)
	local function add_sdfs(bone, list)
		if not grouped[bone] then
			grouped[bone] = { sdfs = {}, radius = 0 }
		end
		for _, s in ipairs(list) do
			table.insert(grouped[bone].sdfs, s)
			local r = 0
			local off = s.offset or { 0, 0, 0 }
			local max_off = math.sqrt(off[1] ^ 2 + off[2] ^ 2 + off[3] ^ 2)
			if s.type == "sphere" then
				r = max_off + s.params[1]
			elseif s.type == "capsule" then
				local d1 = math.sqrt(off[1] ^ 2 + (off[2] + s.params[2]) ^ 2 + off[3] ^ 2)
				local d2 = math.sqrt(off[1] ^ 2 + (off[2] + s.params[3]) ^ 2 + off[3] ^ 2)
				r = math.max(d1, d2) + s.params[1]
			elseif s.type == "box" or s.type == "ellipsoid" then
				r = max_off + math.sqrt(s.params[1] ^ 2 + s.params[2] ^ 2 + s.params[3] ^ 2)
			end
			if r > grouped[bone].radius then
				grouped[bone].radius = r
			end
		end
	end

	local breathe = math.sin(time * 2.0) * 0.01
	local SK = 0.04

	-- HEAD
	add_sdfs("head", {
		{
			bone = "head",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { DATA.head_w / 2, DATA.head_h / 2, DATA.head_d / 2, 0.03 },
		}
	})
	add_sdfs("neck", {
		{ bone = "neck", type = "capsule", id = 1, color = body_color, params = { 0.05, 0.0, 0.15, 0.03 } },
		{
			bone = "neck",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.02, 0.1, 0.02, 0.05 },
			offset = { -0.03, -0.05, 0.04 },
		},
		{
			bone = "neck",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.02, 0.1, 0.02, 0.05 },
			offset = { 0.03, -0.05, 0.04 },
		},
	})

	-- TORSO
	add_sdfs("spine", {
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { DATA.chest_w / 2 + breathe, 0.15, DATA.chest_d / 2, SK },
			offset = { 0, 0.15, 0 },
		},

		-- HIGH-DETAIL ORGANIC PECS
		-- Left Pec
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.08, 0.06, 0.03, 0.06 },
			offset = { -0.1, 0.2, 0.08 },
		}, -- Main mass
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.08, 0.04, 0.05 },
			offset = { -0.16, 0.2, 0.05 },
		}, -- Upper armpit blend

		-- Right Pec
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.08, 0.06, 0.03, 0.06 },
			offset = { 0.1, 0.2, 0.08 },
		}, -- Main mass
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.08, 0.04, 0.05 },
			offset = { 0.16, 0.2, 0.05 },
		}, -- Upper armpit blend

		-- Rest of Torso
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { DATA.waist_w / 2, 0.12, 0.04, 0.1 },
			offset = { 0, 0.0, 0.05 },
		},
		{
			bone = "spine",
			type = "box",
			id = 1,
			color = body_color,
			params = { 0.045, 0.03, 0.015, 0.04 },
			offset = { 0, 0.05, 0.07 },
		},
		{
			bone = "spine",
			type = "box",
			id = 1,
			color = body_color,
			params = { 0.045, 0.03, 0.015, 0.04 },
			offset = { 0, -0.05, 0.07 },
		},
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.1, 0.04, 0.08 },
			offset = { -0.08, 0.0, 0.02 },
		},
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.1, 0.04, 0.08 },
			offset = { 0.08, 0.0, 0.02 },
		},
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.15, 0.03, 0.05 },
			offset = { -0.04, -0.05, -0.05 },
		},
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.04, 0.15, 0.03, 0.05 },
			offset = { 0.04, -0.05, -0.05 },
		},
		{
			bone = "spine",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.08, 0.12, 0.04, 0.05 },
			offset = { 0, 0.05, -0.08 },
		},
		{
			bone = "spine",
			type = "capsule",
			id = 1,
			color = body_color,
			params = { 0.02, 0.0, 0.18, 0.02 },
			offset = { 0.02, 0.22, 0.05 },
		},
		{
			bone = "spine",
			type = "capsule",
			id = 1,
			color = body_color,
			params = { 0.02, 0.0, -0.18, 0.02 },
			offset = { -0.02, 0.22, 0.05 },
		},
	})
	add_sdfs("root", {
		{
			bone = "root",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { DATA.hip_w / 2, 0.1, DATA.pelvis_d / 2, SK },
			offset = { 0, 0, 0 },
		},
		-- GLUTES (Reduced thickness)
		{
			bone = "root",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.08, 0.09, 0.05, 0.06 },
			offset = { -0.07, -0.05, -0.07 },
		},
		{
			bone = "root",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.08, 0.09, 0.05, 0.06 },
			offset = { 0.07, -0.05, -0.07 },
		},
		{
			bone = "root",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { 0.07, 0.06, 0.05, 0.08 },
			offset = { 0, -0.12, 0.03 },
		},
	})

	local function add_organic_leg(side, sign, id)
		local hi, uleg, lleg = "hip_" .. side, "leg_upper_" .. side, "leg_lower_" .. side
		local L, rot_x = tree[hi].length, tree[hi].rot[1]
		local quad_bulge = math.max(0, -rot_x) * 0.03
		local glute_bulge = math.max(0, rot_x) * 0.02
		add_sdfs(hi, {
			{ bone = hi, type = "sphere", id = id, color = body_color, params = { 0.09 + glute_bulge, 0, 0, SK } },
			{ bone = hi, type = "capsule", id = id, color = body_color, params = { 0.08, 0.05, -L - 0.05, SK } },
			{
				bone = hi,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.02, 0.08, 0.02, 0.1 },
				offset = { sign * 0.1, -0.05, 0.05 },
			},
			{
				bone = hi,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.07 + quad_bulge, 0.18, 0.07, 0.06 },
				offset = { 0, -0.15, 0.08 },
			},
			{
				bone = hi,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.06, 0.22, 0.06, 0.06 },
				offset = { sign * 0.05, -0.2, 0.02 },
			},
			{
				bone = hi,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.05, 0.12, 0.04, 0.08 },
				offset = { sign * -0.04, -0.1, 0.02 },
			},
			-- HAMSTRING (Reduced thickness)
			{
				bone = hi,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.045, 0.15, 0.045, 0.06 },
				offset = { 0, -0.18, -0.05 },
			},
		})
		add_sdfs(uleg, {
			{ bone = uleg, type = "sphere", id = id, color = body_color, params = { 0.05, 0, 0, 0.03 } },
			{
				bone = uleg,
				type = "sphere",
				id = id,
				color = body_color,
				params = { 0.04, 0, 0, 0.02 },
				offset = { 0, 0, 0.06 },
			},
			{
				bone = uleg,
				type = "capsule",
				id = id,
				color = body_color,
				params = { 0.07, 0.05, -tree[uleg].length - 0.05, SK },
			},
			{
				bone = uleg,
				type = "ellipsoid",
				id = id,
				color = body_color,
				params = { 0.055, 0.14, 0.05, 0.05 },
				offset = { 0, -0.12, -0.05 },
			},
		})
		add_sdfs(lleg, {
			{ bone = lleg, type = "box", id = id, color = body_color, params = { 0.06, 0.04, 0.12, 0.02 } },
			{
				bone = lleg,
				type = "sphere",
				id = id,
				color = body_color,
				params = { 0.045, 0, 0, 0.02 },
				offset = { 0, 0, -0.08 },
			},
		})
	end
	add_organic_leg("L", -1, 2)
	add_organic_leg("R", 1, 3)

	add_sdfs("head", {
		{
			bone = "head",
			type = "ellipsoid",
			id = 1,
			color = body_color,
			params = { DATA.head_w / 2, DATA.head_h / 2, DATA.head_d / 2, 0.03 },
		},
	})
	add_sdfs(
		"neck",
		{ { bone = "neck", type = "capsule", id = 1, color = body_color, params = { 0.045, 0.0, 0.15, 0.02 } } }
	)

	local function add_anatomical_arm(side, sign, id)
		local sh, up, lo = "shoulder_" .. side, "arm_upper_" .. side, "arm_lower_" .. side
		add_sdfs(sh, {
			{ bone = sh, type = "sphere", id = id, color = body_color, params = { 0.05, 0, 0, SK } },
			{
				bone = sh,
				type = "capsule",
				id = id,
				color = body_color,
				params = { 0.05, 0.05, -tree[sh].length - 0.05, SK },
			},
		})
		add_sdfs(up, {
			{ bone = up, type = "sphere", id = id, color = body_color, params = { 0.04, 0, 0, 0.02 } },
			{
				bone = up,
				type = "capsule",
				id = id,
				color = body_color,
				params = { 0.04, 0.05, -tree[up].length - 0.05, SK },
			},
		})
		add_sdfs(lo, { { bone = lo, type = "sphere", id = id, color = body_color, params = { 0.05, 0, 0, 0.02 } } })
	end
	add_anatomical_arm("L", -1, 2)
	add_anatomical_arm("R", 1, 3)

	if loadout then
		local equip_sdfs = {}
		for k, v in pairs(loadout) do
			if equipment_lib[k] and equipment_lib[k][v] then
				equipment_lib[k][v](equip_sdfs)
			end
		end
		for _, s in ipairs(equip_sdfs) do
			add_sdfs(s.bone, { s })
		end
	end
	return grouped
end

function M.generate_dynamic_assets(loadout, bone_map)
	local particles, constraints = {}, {}
	if loadout.back == "cape" then
		local rows, cols, spacing = 12, 12, 0.1
		local width = (cols - 1) * spacing
		local start_x, start_y, start_z = -width / 2, 1.15, 0.15
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				table.insert(particles, {
					pos = { start_x + c * spacing, start_y - r * spacing, start_z },
					inv_mass = (r == 0) and 0.0 or 1.0,
					bone_index = (r == 0) and bone_map["spine"] or -1,
					id = 50,
				})
				local idx = #particles - 1
				if c > 0 then
					table.insert(constraints, { a = idx - 1, b = idx, length = spacing, compliance = 0.005 })
				end
				if r > 0 then
					table.insert(constraints, { a = idx - cols, b = idx, length = spacing, compliance = 0.005 })
				end
			end
		end
	end
	if loadout.hair == "ponytail" then
		local start_idx, count, spacing = #particles, 5, 0.08
		for i = 0, count - 1 do
			table.insert(particles, {
				pos = { 0, 1.3, -0.1 - i * spacing },
				inv_mass = (i == 0) and 0.0 or 1.0,
				bone_index = (i == 0) and bone_map["head"] or -1,
				id = 51,
			})
			if i > 0 then
				table.insert(
					constraints,
					{ a = start_idx + i - 1, b = start_idx + i, length = spacing, compliance = 0.001 }
				)
			end
		end
	end
	return particles, constraints
end

function M.update_matrices(tree, order, bone_data, bone_map, ground_y)
	local globals, min_y = {}, 1e10
	for i, name in ipairs(order) do
		local node = tree[name]
		local local_m = mc.mat4_translate(node.offset[1], node.offset[2], node.offset[3])
		local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_x(node.rot[1]))
		local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_y(node.rot[2]))
		local_m = mc.mat4_multiply(local_m, mc.mat4_rotate_z(node.rot[3]))
		local parent_global = node.parent and globals[node.parent] or mc.mat4_identity()
		local global_m = mc.mat4_multiply(parent_global, local_m)
		globals[name] = global_m
		if name == "foot_L" or name == "foot_R" then
			local y = global_m.m[13] - 0.05
			if y < min_y then
				min_y = y
			end
		end
	end
	local shift_y = (ground_y or -0.5) - min_y
	for i, name in ipairs(order) do
		local global_m = globals[name]
		global_m.m[13] = global_m.m[13] + shift_y
		local b_idx = bone_map[name]
		if b_idx then
			local inv_m = mc.mat4_inverse(global_m)
			for j = 0, 15 do
				bone_data[b_idx].world_matrix[j], bone_data[b_idx].inv_world_matrix[j] = global_m.m[j], inv_m.m[j]
			end
		end
	end
end

return M
