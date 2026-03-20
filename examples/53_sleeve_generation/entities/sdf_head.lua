local ffi = require("ffi")
local mc = require("mc")
local vk = require("vulkan.ffi")
local pipeline = require("vulkan.pipeline")
local shader = require("vulkan.shader")
local descriptors = require("vulkan.descriptors")
local bit = require("bit")

local SDFHead = {}
SDFHead.__index = SDFHead

function SDFHead.new(device, ds_pool, char_entity)
    local self = setmetatable({}, SDFHead)
    self.device = device
    self.char = char_entity
    self.grid_size = {32, 32, 32} -- Starting small to ensure performance
    
    local total_cells = self.grid_size[1] * self.grid_size[2] * self.grid_size[3]
    
    -- Buffers
    self.grid_buffer = mc.gpu.buffer(total_cells * 48, "storage", nil, false)
    self.cell_buffer = mc.gpu.buffer(total_cells * 4, "storage", nil, false)
    self.vbuf = mc.gpu.buffer(ffi.sizeof("MeshVertex") * 20000, "vertex_storage", nil, false)
    self.ibuf = mc.gpu.buffer(4 * 60000, "index", nil, false)
    self.indirect_buf = mc.gpu.buffer(20, "storage_indirect", nil, true)
    self.counter_buf = mc.gpu.buffer(64, "storage", nil, true) -- [0] = indexCount, [6] = vertexCount

    -- Descriptor Layout
    local c_bindings = {
        { binding = 0, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, -- grid
        { binding = 1, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, -- vbuf
        { binding = 2, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, -- ibuf
        { binding = 3, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, -- cell
        { binding = 4, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }, -- counter
        { binding = 5, type = vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, stages = vk.VK_SHADER_STAGE_COMPUTE_BIT }  -- indirect
    }
    self.ds_layout = descriptors.create_layout(device, c_bindings)
    self.ds = descriptors.allocate_sets(device, ds_pool, {self.ds_layout})[1]
    
    descriptors.update_buffer_set(device, self.ds, 0, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.grid_buffer.handle, 0, self.grid_buffer.size)
    descriptors.update_buffer_set(device, self.ds, 1, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.vbuf.handle, 0, self.vbuf.size)
    descriptors.update_buffer_set(device, self.ds, 2, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.ibuf.handle, 0, self.ibuf.size)
    descriptors.update_buffer_set(device, self.ds, 3, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.cell_buffer.handle, 0, self.cell_buffer.size)
    descriptors.update_buffer_set(device, self.ds, 4, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.counter_buf.handle, 0, self.counter_buf.size)
    descriptors.update_buffer_set(device, self.ds, 5, vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, self.indirect_buf.handle, 0, 20)

    -- Pipelines
    self.pipe_layout = pipeline.create_layout(device, {self.ds_layout}, { { stageFlags = vk.VK_SHADER_STAGE_COMPUTE_BIT, offset = 0, size = 64 } })
    
    local function load_comp(name)
        local base = io.open("examples/53_sleeve_generation/head_"..name..".comp"):read("*all")
        local sdf_lib = io.open("examples/52_csg_dual_contouring/sdf.glsl"):read("*all")
        local face_sdf = io.open("examples/53_sleeve_generation/head_sdf.glsl"):read("*all")
        
        -- Injected SDF definition
        local full_src = base:gsub("// SDF_INSERT_POINT", sdf_lib .. "\n" .. face_sdf .. "\nfloat sdScene(vec3 p) { return sdFace(p); }")
        return pipeline.create_compute_pipeline(device, self.pipe_layout, shader.create_module(device, shader.compile_glsl(full_src, vk.VK_SHADER_STAGE_COMPUTE_BIT)))
    end

    -- We need to ensure the copied base shaders have the // SDF_INSERT_POINT tag.
    -- I'll handle that via a replace turn later if needed.
    self.field_pipe = load_comp("field")
    self.vertex_pipe = load_comp("vertex")
    self.index_pipe = load_comp("index")
    self.reset_pipe = load_comp("reset")

    self.is_baked = false
    return self
end

function SDFHead:update(dt, time, state)
    -- Fetch head matrix from character
    self.world_mat = self.char:get_head_matrix()
end

function SDFHead:record_compute(cb, state)
    -- Allow per-frame baking for now to debug transforms/SDF
    -- if self.is_baked then return end 

    vk.vkCmdBindDescriptorSets(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.pipe_layout, 0, 1, ffi.new("VkDescriptorSet[1]", {self.ds}), 0, nil)
    
    -- Find head bone ID
    local head_id = 0
    for _, b in ipairs(self.char.bones) do if b.name:find("Head") then head_id = b.id - 1; break end end

    vk.vkCmdPushConstants(cb, self.pipe_layout, vk.VK_SHADER_STAGE_COMPUTE_BIT, 0, 4, ffi.new("uint32_t[1]", {head_id}))

    -- 1. Reset
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.reset_pipe)
    vk.vkCmdDispatch(cb, 1, 1, 1)
    
    local barrier = ffi.new("VkMemoryBarrier[1]", {{ sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT }})
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- 2. Field
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.field_pipe)
    vk.vkCmdDispatch(cb, self.grid_size[1]/8, self.grid_size[2]/8, self.grid_size[3]/8)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- 3. Vertex
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.vertex_pipe)
    vk.vkCmdDispatch(cb, self.grid_size[1]/8, self.grid_size[2]/8, self.grid_size[3]/8)
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, barrier, 0, nil, 0, nil)

    -- 4. Index
    vk.vkCmdBindPipeline(cb, vk.VK_PIPELINE_BIND_POINT_COMPUTE, self.index_pipe)
    vk.vkCmdDispatch(cb, self.grid_size[1]/8, self.grid_size[2]/8, self.grid_size[3]/8)

    local v_barriers = ffi.new("VkBufferMemoryBarrier[3]", {
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT, buffer = self.vbuf.handle, offset = 0, size = self.vbuf.size },
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_INDEX_READ_BIT, buffer = self.ibuf.handle, offset = 0, size = self.ibuf.size },
        { sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, srcAccessMask = vk.VK_ACCESS_SHADER_WRITE_BIT, dstAccessMask = vk.VK_ACCESS_INDIRECT_COMMAND_READ_BIT, buffer = self.indirect_buf.handle, offset = 0, size = 20 }
    })
    vk.vkCmdPipelineBarrier(cb, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, bit.bor(vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT, vk.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT), 0, 0, nil, 3, v_barriers, 0, nil)


    self.is_baked = true
end

function SDFHead:record_draw(cb, pipe_layout, is_wireframe)
    if not self.world_mat then return end
    
    local mat = ffi.new("float[16]")
    for i=0,15 do mat[i] = self.world_mat.m[i] end

    -- Mixamo Head is at base of skull. Move UP along Y-axis
    -- 1.0 units is 10cm. 
    local offset_up = 1.0
    mat[12] = mat[12] + mat[4] * offset_up
    mat[13] = mat[13] + mat[5] * offset_up
    mat[14] = mat[14] + mat[6] * offset_up

    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 64, 64, mat)
    
    vk.vkCmdBindVertexBuffers(cb, 0, 1, ffi.new("VkBuffer[1]", {self.vbuf.handle}), ffi.new("VkDeviceSize[1]", {0}))
    vk.vkCmdBindIndexBuffer(cb, self.ibuf.handle, 0, vk.VK_INDEX_TYPE_UINT32)
    
    -- DIRECT DRAW: Use the count we see in logs (around 13000)
    -- We can fetch the actual count from the mapped counter buffer if needed
    local ptr = ffi.cast("uint32_t*", self.counter_buf.allocation.ptr)
    local count = ptr[0]
    if count > 0 then
        vk.vkCmdDrawIndexed(cb, count, 1, 0, 0, 0)
    end

    -- Restore identity matrix
    local identity = mc.mat4_identity()
    vk.vkCmdPushConstants(cb, pipe_layout, bit.bor(vk.VK_SHADER_STAGE_VERTEX_BIT, vk.VK_SHADER_STAGE_FRAGMENT_BIT), 64, 64, identity.m)
end

return SDFHead
