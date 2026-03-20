local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local descriptors = require("vulkan.descriptors")
local bit = require("bit")

local skeleton = require("examples.53_sleeve_generation.skeleton")
local mesher = require("examples.53_sleeve_generation.mesher")
local dae = require("examples.53_sleeve_generation.dae_loader")

local Character = {}
Character.__index = Character

function Character.new(device, ds_pool, g_ds_layout)
    local self = setmetatable({}, Character)
    self.device = device
    self.RINGS_PER_BONE = 16
    self.VERTS_PER_RING = 32

    self.bones = skeleton.get_bone_list()
    
    self.segments = mesher.calculate_bone_segments(self.bones)
    -- Filter out segments that connect TO the Head or virtual_Face
    local filtered = {}
    for _, s in ipairs(self.segments) do
        if not s.child_name:find("Head") and not s.child_name:find("virtual") then
            table.insert(filtered, s)
        end
    end
    self.segments = filtered

    self.idx_count = #mesher.generate_indices(#self.segments, self.RINGS_PER_BONE, self.VERTS_PER_RING)

    self.animations = {
        walking = dae.load_animations("examples/53_sleeve_generation/Walking.dae"),
        slash = dae.load_animations("examples/53_sleeve_generation/Great Sword Slash.dae")
    }

    local v_size = #self.segments * self.RINGS_PER_BONE * self.VERTS_PER_RING * ffi.sizeof("MeshVertex")
    local i_size = self.idx_count * 4
    self.vbuf = mc.gpu.buffer(v_size, "vertex_storage", nil, true)
    self.ibuf = mc.gpu.buffer(i_size, "index", ffi.new("uint32_t[?]", self.idx_count, mesher.generate_indices(#self.segments, self.RINGS_PER_BONE, self.VERTS_PER_RING)), true)
    self.bone_buf = mc.gpu.buffer(#self.segments * ffi.sizeof("MeshBone"), "storage", nil, true)
    self.param_buf = mc.gpu.buffer(#self.segments * self.RINGS_PER_BONE * ffi.sizeof("MeshRingParams"), "storage", mesher.create_params(#self.segments, self.RINGS_PER_BONE, self.segments), true)
    
    self.pick_buf = mc.gpu.buffer(4, "storage", nil, true)
    local clear_id = ffi.new("uint32_t[1]", {0xFFFFFFFF})
    self.pick_buf:upload(clear_id)

    self.indirect_buf = mc.gpu.buffer(20, "storage_indirect", nil, true) -- 5 * 4 bytes

    local c_bindings = {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT },
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }
    }
    local c_ds_layout = descriptors.create_layout(device, c_bindings)
    self.compute_layout = pipeline.create_layout(device, {c_ds_layout}, { { stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 20 } })
    local c_src = io.open("examples/53_sleeve_generation/mesher.comp"):read("*all")
    self.compute_pipe = pipeline.create_compute_pipeline(device, self.compute_layout, shader.create_module(device, shader.compile_glsl(c_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))

    self.c_ds = descriptors.allocate_sets(device, ds_pool, {c_ds_layout})[1]
    self.g_ds = descriptors.allocate_sets(device, ds_pool, {g_ds_layout})[1]
    
    descriptors.update_buffer_set(device, self.c_ds, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.vbuf.handle, 0, v_size)
    descriptors.update_buffer_set(device, self.c_ds, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.bone_buf.handle, 0, #self.segments * ffi.sizeof("MeshBone"))
    descriptors.update_buffer_set(device, self.c_ds, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.param_buf.handle, 0, #self.segments * self.RINGS_PER_BONE * ffi.sizeof("MeshRingParams"))
    descriptors.update_buffer_set(device, self.c_ds, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.indirect_buf.handle, 0, 20)
    descriptors.update_buffer_set(device, self.g_ds, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.pick_buf.handle, 0, 4)

    self.skeleton_vbuf = mc.gpu.buffer(#self.segments * 2 * 24, "vertex", nil, true)

    return self
end

local function lerp_mat(a, b, t)
    local out = {}
    for i=1,16 do out[i] = (a[i] or 0) + ((b[i] or 0) - (a[i] or 0)) * t end
    return out
end

local function get_animated_matrix(bone_name, addr, time)
    if not addr or not addr.channels[bone_name] then return nil end
    local chan = addr.channels[bone_name]
    local t = time % addr.duration
    local idx1, idx2 = 1, 1
    for i=1, #chan.times do if chan.times[i] > t then idx2 = i; idx1 = math.max(1, i-1); break end end
    local t1, t2 = chan.times[idx1], chan.times[idx2]
    local f = 0; if t2 > t1 then f = (t - t1) / (t2 - t1) end
    return lerp_mat(chan.matrices[idx1], chan.matrices[idx2], f)
end

function Character:update(dt, time, state)
    local bone_globals = {}
    local function calc_globals(bone, parent_global)
        local local_m = mc.mat4_identity()
        local vals = (self.animations[state.anim_state] and get_animated_matrix(bone.name, self.animations[state.anim_state], time)) or bone.local_matrix
        if vals then for row=0,3 do for col=0,3 do local_m.m[col*4 + row] = vals[row*4 + col + 1] end end end
        local_m.m[12], local_m.m[13], local_m.m[14] = local_m.m[12]*0.1, local_m.m[13]*0.1, local_m.m[14]*0.1
        local global_m = mc.mat4_multiply(parent_global, local_m)
        bone_globals[bone.id] = global_m
        for _, b in ipairs(self.bones) do if b.parent_id == bone.id then calc_globals(b, global_m) end end
    end
    local root = nil; for _, b in ipairs(self.bones) do if b.parent_id == 0 then root = b; break end end
    if root then calc_globals(root, mc.mat4_identity()) end
    self.bone_globals = bone_globals

    local segment_dirs = {}
    for i, s in ipairs(self.segments) do
        local m_start = bone_globals[s.start_pos[4] + 1]
        local m_end = bone_globals[s.end_pos[4] + 1]
        local dx, dy, dz = m_end.m[12]-m_start.m[12], m_end.m[13]-m_start.m[13], m_end.m[14]-m_start.m[14]
        local l = math.sqrt(dx*dx+dy*dy+dz*dz)
        if l > 0 then dx,dy,dz = dx/l, dy/l, dz/l end
        segment_dirs[i] = {dx, dy, dz}
    end

    local bone_data = ffi.new("MeshBone[?]", #self.segments)
    for i, s in ipairs(self.segments) do
        local m_start, m_end = bone_globals[s.start_pos[4] + 1], bone_globals[s.end_pos[4] + 1]
        local dir = segment_dirs[i]
        local incoming = dir
        for j, ps in ipairs(self.segments) do if ps.end_pos[4] == s.start_pos[4] then incoming = segment_dirs[j]; break end end
        local outgoing = dir
        for j, cs in ipairs(self.segments) do if cs.start_pos[4] == s.end_pos[4] then outgoing = segment_dirs[j]; break end end
        
        local dot_in = dir[1]*incoming[1] + dir[2]*incoming[2] + dir[3]*incoming[3]
        local is_sharp_bend = dot_in < 0.0
        
        local ps = {incoming[1] + dir[1], incoming[2] + dir[2], incoming[3] + dir[3]}
        local psl = math.sqrt(ps[1]^2 + ps[2]^2 + ps[3]^2)
        if psl > 0 and not is_sharp_bend then ps = {ps[1]/psl, ps[2]/psl, ps[3]/psl} else ps = dir end
        if s.parent_name:find("Hips") then ps = {0, 1, 0} end
        
        local pe = {dir[1] + outgoing[1], dir[2] + outgoing[2], dir[3] + outgoing[3]}
        local pel = math.sqrt(pe[1]^2 + pe[2]^2 + pe[3]^2)
        if pel > 0 then pe = {pe[1]/pel, pe[2]/pel, pe[3]/pel} else pe = dir end
        
        local dot_out = dir[1]*outgoing[1] + dir[2]*outgoing[2] + dir[3]*outgoing[3]
        local flex = math.max(0, 1.0 - dot_out) * 0.5
        local side = (s.name:find("Right") and -1 or 1)
        if not s.name:find("Left") and not s.name:find("Right") then side = 0.0 end
        
        bone_data[i-1].start_pos = {m_start.m[12], m_start.m[13], m_start.m[14], s.start_pos[4]}
        bone_data[i-1].end_pos = {m_end.m[12], m_end.m[13], m_end.m[14], s.end_pos[4]}
        bone_data[i-1].plane_start = {ps[1], ps[2], ps[3], flex}
        bone_data[i-1].plane_end = {pe[1], pe[2], pe[3], side}
    end
    self.bone_buf:upload(bone_data)
end

function Character:record_compute(cb, state)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.compute_pipe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.compute_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {self.c_ds}), 0, nil)
    vk.vkCmdPushConstants(cb, self.compute_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 16, ffi.new("uint32_t[4]", { #self.segments, self.RINGS_PER_BONE, self.VERTS_PER_RING, state.diagnostic and 1 or 0 }))
    vk.vkCmdDispatch(cb, math.ceil(self.VERTS_PER_RING / 16), math.ceil(self.RINGS_PER_BONE / 8), #self.segments)
    
    local v_barriers = ffi.new("VkBufferMemoryBarrier[2]", {
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT, buffer = self.vbuf.handle, offset = 0, size = self.vbuf.size },
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, buffer = self.indirect_buf.handle, offset = 0, size = 20 }
    })
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT), 0, 0, nil, 2, v_barriers, 0, nil)
end

function Character:record_draw(cb, pipe_layout, is_wireframe)
    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {self.g_ds}), 0, nil)
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {self.vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, self.ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    vk.vkCmdDrawIndexedIndirect(cb, self.indirect_buf.handle, 0, 1, 0)
end

function Character:record_debug_draw(cb, debug_pipe, debug_layout)
    if not self.bone_globals then return end
    local skel_data = ffi.new("float[?]", #self.segments * 2 * 6)
    for i, s in ipairs(self.segments) do
        local m_start, m_end = self.bone_globals[s.start_pos[4] + 1], self.bone_globals[s.end_pos[4] + 1]
        local is_v = s.name:find("virtual"); local r,g,b = (is_v and 0 or 1), 1, (is_v and 1 or 1)
        skel_data[(i-1)*12 + 0], skel_data[(i-1)*12 + 1], skel_data[(i-1)*12 + 2] = m_start.m[12], m_start.m[13], m_start.m[14]
        skel_data[(i-1)*12 + 3], skel_data[(i-1)*12 + 4], skel_data[(i-1)*12 + 5] = r,g,b
        skel_data[(i-1)*12 + 6], skel_data[(i-1)*12 + 7], skel_data[(i-1)*12 + 8] = m_end.m[12], m_end.m[13], m_end.m[14]
        skel_data[(i-1)*12 + 9], skel_data[(i-1)*12 + 10], skel_data[(i-1)*12 + 11] = r,g,b
    end
    self.skeleton_vbuf:upload(skel_data)
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_GRAPHICS, debug_pipe)
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {self.skeleton_vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdDraw(cb, #self.segments * 2, 1, 0, 0)
end

function Character:check_picking()
    local pick_id = ffi.new("uint32_t[1]"); ffi.copy(pick_id, self.pick_buf.allocation.ptr, 4)
    if pick_id[0] ~= 0xFFFFFFFF then 
        local s = self.segments[pick_id[0]+1]
        if s then print("Mouse over: " .. s.name) end 
    end
    local clear_id = ffi.new("uint32_t[1]", {0xFFFFFFFF})
    self.pick_buf:upload(clear_id)
end

function Character:get_head_matrix()
    local target_id = nil
    -- Try to find Head bone first, then fallback to Neck
    for _, b in ipairs(self.bones) do if b.name:find("Head") then target_id = b.id; break end end
    if not target_id then
        for _, b in ipairs(self.bones) do if b.name:find("Neck") then target_id = b.id; break end end
    end
    
    if target_id and self.bone_globals and self.bone_globals[target_id] then
        return self.bone_globals[target_id]
    end
    return nil
end

return Character
