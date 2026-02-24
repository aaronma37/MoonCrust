local ffi = require("ffi")

local M = {}

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
    local sections = {}
    local first_def = nil

    for section in schema_text:gmatch("([^=]+)") do
        local type_name = section:match("MSG:%s+([%w_/]+)")
        local def = parse_single_definition(section)
        if #def > 0 then
            if not first_def then first_def = def end
            if type_name then
                type_lib[type_name] = def
                type_lib[type_name:gsub(".*/", "")] = def
            else
                table.insert(sections, def)
            end
        end
    end
    
    return {
        main = sections[1] or first_def or {},
        lib = type_lib
    }
end

-- Returns a flattened list of fields with static offsets (for the Plotter)
function M.get_flattened_fields(schema)
    if not schema then return {} end
    local flattened = {}
    
    local function resolve(fields, prefix, offset)
        for _, f in ipairs(fields) do
            local name = (prefix == "") and f.name or (prefix .. "." .. f.name)
            
            if f.is_array and not f.array_size then
                -- Sequences have dynamic offsets, skip flattening
                offset = math.ceil(offset / 4) * 4 + 4
            elseif f.is_array and f.array_size then
                local sub_fields = PRIMITIVES[f.type] and { { type = f.type, name = "", is_array = false } } or (schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")])
                if sub_fields then
                    for i=0, math.min(f.array_size, 16)-1 do
                        offset = resolve(sub_fields, name .. "[" .. i .. "]", offset)
                    end
                end
            elseif PRIMITIVES[f.type] then
                local info = PRIMITIVES[f.type]
                offset = math.ceil(offset / info.size) * info.size
                table.insert(flattened, { name = name, offset = offset, type = f.type, is_double = (f.type == "float64" or f.type == "double") })
                offset = offset + info.size
            elseif f.type == "string" then
                offset = math.ceil(offset / 4) * 4 + 4 
            else
                local sub_fields = schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")]
                if sub_fields then offset = resolve(sub_fields, name, offset) end
            end
        end
        return offset
    end
    
    resolve(schema.main, "", 4)
    return flattened
end

function M.decode(data_ptr, data_size, schema)
    if not data_ptr or not schema then return nil end
    local results = {}
    local current_offset = 4
    
    -- Heuristic: If message is huge, don't decode "Live Values" to avoid UI freeze
    if data_size > 100000 then
        table.insert(results, { name = "Message too large for text viewer", value = string.format("%d bytes", data_size), fmt = "%s" })
        return results
    end

    local function resolve(fields, prefix, offset)
        for _, f in ipairs(fields) do
            local name = (prefix == "") and f.name or (prefix .. "." .. f.name)
            
            -- Bounds check
            if offset >= data_size then break end

            if f.is_array then
                local count = 0
                if not f.array_size then
                    offset = math.ceil(offset / 4) * 4
                    if offset + 4 > data_size then break end
                    count = ffi.cast("uint32_t*", data_ptr + offset)[0]
                    table.insert(results, { name = name .. ".count", value = count, fmt = "%u" })
                    offset = offset + 4
                else count = f.array_size end

                local sub_fields = PRIMITIVES[f.type] and { { type = f.type, name = "", is_array = false } } or (schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")])
                if sub_fields then
                    local limit = math.min(count, 5)
                    for i=0, limit-1 do
                        if offset >= data_size then break end
                        offset = resolve(sub_fields, name .. "[" .. i .. "]", offset)
                    end
                    -- Attempt to skip remaining bytes for primitives
                    if count > limit and PRIMITIVES[f.type] then
                        offset = offset + (count - limit) * PRIMITIVES[f.type].size
                    end
                end
            elseif PRIMITIVES[f.type] then
                local info = PRIMITIVES[f.type]
                offset = math.ceil(offset / info.size) * info.size
                if offset + info.size > data_size then break end
                local val = ffi.cast(info.ffi, data_ptr + offset)[0]
                if f.type == "bool" then val = val ~= 0 and "true" or "false" end
                table.insert(results, { name = name, value = val, fmt = info.fmt })
                offset = offset + info.size
            elseif f.type == "string" then
                offset = math.ceil(offset / 4) * 4
                if offset + 4 > data_size then break end
                local len = ffi.cast("uint32_t*", data_ptr + offset)[0]
                offset = offset + 4
                if len > 0 and len < 1024 and offset + len <= data_size then
                    table.insert(results, { name = name, value = ffi.string(data_ptr + offset, len-1), fmt = "%s" })
                end
                offset = offset + len
            else
                local sub_fields = schema.lib[f.type] or schema.lib[f.type:gsub(".*/", "")]
                if sub_fields then offset = resolve(sub_fields, name, offset) end
            end
        end
        return offset
    end
    
    resolve(schema.main, "", current_offset)
    return results
end

return M
