local ffi = require("ffi")
local json = require("mc.json")
local vk = require("vulkan.ffi")

-- Load the image loader library
ffi.cdef[[
    unsigned char* mc_load_image(const char* filename, int* width, int* height, int* channels, int desired_channels);
    void mc_free_image(unsigned char* pixels);
]]

local libimg = ffi.load("src/lua/mc/libimage_loader.so")

local M = {}

local TYPE_UNSIGNED_SHORT = 5123
local TYPE_UNSIGNED_INT   = 5125

local COMPONENT_SIZES = {
    [5120] = 1, [5121] = 1, [5122] = 2, [5123] = 2, [5125] = 4, [5126] = 4,
}

local TYPE_COUNTS = {
    SCALAR = 1, VEC2 = 2, VEC3 = 3, VEC4 = 4, MAT2 = 4, MAT3 = 9, MAT4 = 16
}

function M.load(path)
    print("GLTF Loader: Loading " .. path)
    local base_dir = path:match("(.*[/\\])") or ""
    local f = io.open(path, "r")
    if not f then error("Could not open file: " .. path) end
    local content = f:read("*all")
    f:close()

    local data = json.decode(content)
    local buffers = {}
    for i, buf_info in ipairs(data.buffers) do
        local buf_f = io.open(base_dir .. buf_info.uri, "rb")
        if not buf_f then error("Could not open buffer: " .. buf_info.uri) end
        local buf_data = buf_f:read("*all")
        buf_f:close()
        local c_data = ffi.new("uint8_t[?]", #buf_data)
        ffi.copy(c_data, buf_data, #buf_data)
        buffers[i] = c_data
    end

    local function get_accessor_info(accessor_idx)
        if accessor_idx == nil then return nil end
        local acc = data.accessors[accessor_idx + 1]
        local view = data.bufferViews[acc.bufferView + 1]
        local buf_ptr = buffers[view.buffer + 1]
        local offset = (acc.byteOffset or 0) + (view.byteOffset or 0)
        local count = acc.count
        local component_size = COMPONENT_SIZES[acc.componentType]
        local stride = view.byteStride or (component_size * (TYPE_COUNTS[acc.type] or 1))
        return buf_ptr + offset, count, acc.componentType, stride
    end

    local min_p = {1e10, 1e10, 1e10}
    local max_p = {-1e10, -1e10, -1e10}
    local total_verts = 0
    local total_indices = 0

    for _, mesh in ipairs(data.meshes) do
        for _, prim in ipairs(mesh.primitives) do
            local pos_info = prim.attributes.POSITION
            if pos_info then
                local pos_ptr, count, _, pos_stride = get_accessor_info(pos_info)
                total_verts = total_verts + count
                for j=0, count-1 do
                    local p = ffi.cast("float*", pos_ptr + j * pos_stride)
                    if p[0] < min_p[1] then min_p[1] = p[0] end
                    if p[1] < min_p[2] then min_p[2] = p[1] end
                    if p[2] < min_p[3] then min_p[3] = p[2] end
                    if p[0] > max_p[1] then max_p[1] = p[0] end
                    if p[1] > max_p[2] then max_p[2] = p[1] end
                    if p[2] > max_p[3] then max_p[3] = p[2] end
                end
                if prim.indices then
                    local _, i_count = get_accessor_info(prim.indices)
                    total_indices = total_indices + i_count
                else
                    total_indices = total_indices + count
                end
            end
        end
    end

    local center = { (min_p[1] + max_p[1])/2, min_p[2], (min_p[3] + max_p[3])/2 }
    local scale = 0.01

    local v_data = ffi.new("float[?]", total_verts * 8)
    local i_data = ffi.new("uint32_t[?]", total_indices)
    local draw_calls = {}
    local v_ptr, i_ptr, v_offset_accum = 0, 0, 0

    for _, mesh in ipairs(data.meshes) do
        for _, prim in ipairs(mesh.primitives) do
            local pos_ptr, count, _, pos_stride = get_accessor_info(prim.attributes.POSITION)
            local norm_ptr, _, _, norm_stride = get_accessor_info(prim.attributes.NORMAL)
            local uv_ptr, _, _, uv_stride = get_accessor_info(prim.attributes.TEXCOORD_0)
            
            for j=0, count-1 do
                local p = ffi.cast("float*", pos_ptr + j * pos_stride)
                v_data[v_ptr+0] = (p[0] - center[1]) * scale
                v_data[v_ptr+1] = (p[1] - center[2]) * scale
                v_data[v_ptr+2] = (p[2] - center[3]) * scale
                
                if norm_ptr then
                    local n = ffi.cast("float*", norm_ptr + j * norm_stride)
                    v_data[v_ptr+3], v_data[v_ptr+4], v_data[v_ptr+5] = n[0], n[1], n[2]
                else
                    v_data[v_ptr+3], v_data[v_ptr+4], v_data[v_ptr+5] = 0, 1, 0
                end
                if uv_ptr then
                    local u = ffi.cast("float*", uv_ptr + j * uv_stride)
                    v_data[v_ptr+6], v_data[v_ptr+7] = u[0], u[1]
                else
                    v_data[v_ptr+6], v_data[v_ptr+7] = 0, 0
                end
                v_ptr = v_ptr + 8
            end

            local index_start = i_ptr
            if prim.indices then
                local idx_ptr, i_count, i_type = get_accessor_info(prim.indices)
                if i_type == TYPE_UNSIGNED_SHORT then
                    local ptr = ffi.cast("uint16_t*", idx_ptr)
                    for j=0, i_count-1 do i_data[i_ptr+j] = ptr[j] + v_offset_accum end
                else
                    local ptr = ffi.cast("uint32_t*", idx_ptr)
                    for j=0, i_count-1 do i_data[i_ptr+j] = ptr[j] + v_offset_accum end
                end
                i_ptr = i_ptr + i_count
            else
                for j=0, count-1 do i_data[i_ptr+j] = j + v_offset_accum end
                i_ptr = i_ptr + count
            end

            table.insert(draw_calls, { index_offset = index_start, index_count = i_ptr - index_start, material_idx = prim.material or 0 })
            v_offset_accum = v_offset_accum + count
        end
    end

    return {
        vertices = v_data, vertex_count = total_verts,
        indices = i_data, index_count = total_indices,
        draw_calls = draw_calls,
        materials = data.materials, images = data.images, textures = data.textures, base_dir = base_dir
    }
end

function M.load_image(path)
    local w = ffi.new("int[1]")
    local h = ffi.new("int[1]")
    local c = ffi.new("int[1]")
    local pixels = libimg.mc_load_image(path, w, h, c, 4) -- Always ask for 4 channels (RGBA)
    if pixels == nil then return nil end
    
    local width, height = w[0], h[0]
    local size = width * height * 4
    local lua_pixels = ffi.new("uint8_t[?]", size)
    ffi.copy(lua_pixels, pixels, size)
    libimg.mc_free_image(pixels)
    
    return lua_pixels, width, height
end

-- FALLBACK LOADER: Pure Lua TGA (since stb_image is missing)
function M.load_tga(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local header = f:read(18)
    if not header or #header < 18 then f:close(); return nil end
    local h_ptr = ffi.cast("uint8_t*", header)
    local w, h = h_ptr[12] + h_ptr[13] * 256, h_ptr[14] + h_ptr[15] * 256
    local bpp, img_type = h_ptr[16], h_ptr[2]
    if img_type ~= 2 then f:close(); return nil end
    local data = f:read("*all")
    f:close()
    local pixels = ffi.new("uint8_t[?]", w * h * 4)
    local src_ptr = ffi.cast("uint8_t*", data)
    for i = 0, w * h - 1 do
        local x, y = i % w, h - 1 - math.floor(i / w)
        local target_idx = (y * w + x) * 4
        if bpp == 32 then
            pixels[target_idx+0], pixels[target_idx+1], pixels[target_idx+2], pixels[target_idx+3] = src_ptr[i*4+2], src_ptr[i*4+1], src_ptr[i*4+0], src_ptr[i*4+3]
        elseif bpp == 24 then
            pixels[target_idx+0], pixels[target_idx+1], pixels[target_idx+2], pixels[target_idx+3] = src_ptr[i*3+2], src_ptr[i*3+1], src_ptr[i*3+0], 255
        end
    end
    return pixels, w, h
end

return M
