local ffi = require("ffi")

local M = {
    pool = {},
    pool_idx = 1,
    name_cache = {}, -- Cache for concatenated field names
    name_cache_count = 0,
}

local function get_cached_name(prefix, field_name)
    local key = prefix .. field_name
    local cached = M.name_cache[key]
    if not cached then
        if M.name_cache_count > 10000 then 
            M.name_cache = {}; M.name_cache_count = 0 
        end
        cached = (prefix == "") and field_name or (prefix .. "." .. field_name)
        M.name_cache[key] = cached
        M.name_cache_count = M.name_cache_count + 1
    end
    return cached
end

-- Initialize pool with 10,000 result objects
for i=1, 10000 do
    M.pool[i] = { name = "", value = 0, fmt = "" }
end

local function get_pool_obj()
    local obj = M.pool[M.pool_idx]
    M.pool_idx = (M.pool_idx % 10000) + 1
    return obj
end

local PRIMITIVES = {
    ["float32"] = { ffi = "float*", size = 4, fmt = "%.4f" },
    ["float64"] = { ffi = "double*", size = 8, fmt = "%.6f" },
    ["double"]  = { ffi = "double*", size = 8, fmt = "%.6f" },
    ["float"]   = { ffi = "float*", size = 4, fmt = "%.4f" },
    ["int32"]   = { ffi = "int32_t*", size = 4, fmt = "%d" },
    ["uint32"]  = { ffi = "uint32_t*", size = 4, fmt = "%u" },
    ["int16"]   = { ffi = "int16_t*", size = 2, fmt = "%d" },
    ["uint16"]  = { ffi = "uint16_t*", size = 2, fmt = "%u" },
    ["int64"]   = { ffi = "int64_t*", size = 8, fmt = "%lld" },
    ["uint64"]  = { ffi = "uint64_t*", size = 8, fmt = "%llu" },
    ["bool"]    = { ffi = "uint8_t*", size = 1, fmt = "%s" },
    ["uint8"]   = { ffi = "uint8_t*", size = 1, fmt = "%u" },
    ["int8"]    = { ffi = "int8_t*", size = 1, fmt = "%d" },
    ["char"]    = { ffi = "uint8_t*", size = 1, fmt = "%u" },
    ["byte"]    = { ffi = "uint8_t*", size = 1, fmt = "%u" },
}

local function align(offset, size)
    return math.ceil(offset / size) * size
end

local function parse_single_definition(text)
    local fields = {}
    for line in text:gmatch("([^\r\n]+)") do
        line = line:gsub("#.*", ""):match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("=") then
            local t, array_spec, n = line:match("^([%w_/]+)(%[?%d*%]?)%s+([%w_]+)")
            if t and n then
                local is_array = (array_spec ~= "")
                local array_size = tonumber(array_spec:match("%d+"))
                table.insert(fields, { type = t, name = n, is_array = is_array, array_size = array_size })
            end
        end
    end
    return fields
end

function M.parse_schema(schema_text)
    if not schema_text then return nil end
    local type_lib = {}
    local parts = {}
    for part in schema_text:gmatch("[^=]+") do table.insert(parts, part) end
    local first_def = nil
    for _, part in ipairs(parts) do
        local type_name = part:match("MSG:%s+([%w_/]+)")
        local def = parse_single_definition(part)
        if #def > 0 then
            if not first_def then first_def = def end
            if type_name then type_lib[type_name] = def; type_lib[type_name:gsub(".*/", "")] = def end
        end
    end
    return { main = first_def or {}, lib = type_lib }
end

local function calculate_static_size(schema, fields)
    local size = 0
    for _, f in ipairs(fields) do
        if f.is_array and not f.array_size then return nil end
        if f.type == "string" then return nil end
        local item_size = 0
        if PRIMITIVES[f.type] then item_size = PRIMITIVES[f.type].size
        else
            local sub = schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")]
            if not sub then return nil end
            item_size = calculate_static_size(schema, sub); if not item_size then return nil end
        end
        if f.is_array then size = align(size, 4) + item_size * f.array_size
        else size = align(size, item_size < 8 and item_size or 8) + item_size end
    end
    return size
end

function M.decode(data_ptr, data_size, schema, results_pool)
    if not data_ptr or not schema then return nil end
    local results = results_pool or {}
    for k in pairs(results) do results[k] = nil end
    
    local current_offset = 4
    if data_size > 500000 then 
        table.insert(results, { name = "Message too large", value = "SKIPPED", fmt = "%s" })
        return results
    end

    local function resolve(fields, prefix, offset)
        for _, f in ipairs(fields) do
            local name = get_cached_name(prefix, f.name)
            if offset >= data_size then break end
            if f.is_array then
                local count = 0
                if not f.array_size then
                    offset = align(offset, 4); if offset + 4 > data_size then break end
                    count = ffi.cast("uint32_t*", data_ptr + offset)[0]
                    local obj = get_pool_obj()
                    obj.name, obj.value, obj.fmt = get_cached_name(name, ".count"), count, "%u"
                    table.insert(results, obj)
                    offset = offset + 4
                else count = f.array_size end
                local sub = PRIMITIVES[f.type] and { { type = f.type, name = "", is_array = false } } or (schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")])
                if sub then
                    local limit = math.min(count, 5)
                    for i=0, limit-1 do 
                        if offset >= data_size then break end
                        local sub_prefix = get_cached_name(name, "[" .. i .. "]")
                        offset = resolve(sub, sub_prefix, offset) 
                    end
                    if count > limit then local ss = calculate_static_size(schema, sub); if ss then offset = offset + (count - limit) * ss else return offset end end
                end
            elseif PRIMITIVES[f.type] then
                local info = PRIMITIVES[f.type]; offset = align(offset, info.size); if offset + info.size > data_size then break end
                local val = ffi.cast(info.ffi, data_ptr + offset)[0]
                if f.type == "bool" then val = val ~= 0 and "true" or "false" end
                local obj = get_pool_obj()
                obj.name, obj.value, obj.fmt = name, val, info.fmt
                table.insert(results, obj)
                offset = offset + info.size
            elseif f.type == "string" then
                offset = align(offset, 4); if offset + 4 > data_size then break end
                local len = ffi.cast("uint32_t*", data_ptr + offset)[0]; offset = offset + 4
                if len > 0 and len < 2048 and offset + len <= data_size then 
                    local obj = get_pool_obj()
                    obj.name, obj.value, obj.fmt = name, ffi.string(data_ptr + offset, len-1), "%s"
                    table.insert(results, obj)
                else
                    local obj = get_pool_obj()
                    obj.name, obj.value, obj.fmt = name, "", "%s"
                    table.insert(results, obj)
                end
                offset = offset + len
            else
                local sub = schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")]
                if sub then offset = resolve(sub, name, offset) else offset = align(offset, 4) end
            end
        end
        return offset
    end
    resolve(schema.main, "", current_offset)
    return results
end

-- Disable JIT for the high-churn decoder to prevent "trace" and "table overflow" compiler errors
if jit then
    jit.off(M.decode)
end

local TYPE_MAP = {
    ["float32"] = 0, ["float"] = 0,
    ["int32"] = 1, ["int"] = 1,
    ["uint32"] = 2,
    ["float64"] = 3, ["double"] = 3,
    ["int64"] = 4, ["uint64"] = 5,
}

function M.get_gpu_instructions(schema)
    local flattened = M.get_flattened_fields(schema)
    local count = #flattened
    local buf = ffi.new("uint32_t[?]", count * 4) -- 16 bytes per instruction
    
    for i=1, count do
        local f = flattened[i]
        local base = (i-1) * 4
        buf[base + 0] = f.offset
        buf[base + 1] = i - 1 -- Destination slot in results buffer
        buf[base + 2] = TYPE_MAP[f.type] or 0
        buf[base + 3] = 0 -- Padding
    end
    
    return buf, count
end

function M.get_flattened_fields(schema)
    if not schema then return {} end
    local flattened = {}
    local function resolve(fields, prefix, offset)
        for _, f in ipairs(fields) do
            local name = (prefix == "") and f.name or (prefix .. "." .. f.name)
            if f.is_array and not f.array_size then offset = align(offset, 4) + 4
            elseif f.is_array and f.array_size then
                local sub = PRIMITIVES[f.type] and { { type = f.type, name = "", is_array = false } } or (schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")])
                if sub then for i=0, f.array_size-1 do offset = resolve(sub, name .. "[" .. i .. "]", offset) end end
            elseif PRIMITIVES[f.type] then
                local info = PRIMITIVES[f.type]; offset = align(offset, info.size); table.insert(flattened, { name = name, offset = offset, type = f.type, is_double = (f.type:find("64") or f.type == "double") }); offset = offset + info.size
            elseif f.type == "string" then offset = align(offset, 4) + 4
            else
                local sub = schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")]
                if sub then offset = resolve(sub, name, offset) end
            end
        end
        return offset
    end
    resolve(schema.main, "", 4)
    return flattened
end

return M
