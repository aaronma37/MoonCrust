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
    ["bool"]    = { ffi = "bool*", size = 1, fmt = "%s" },
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
            local t, n = line:match("^([%w_/]+)%s+([%w_]+)")
            if t and n then
                table.insert(fields, { type = t, name = n })
            end
        end
    end
    return fields
end

function M.parse_schema(schema_text)
    if not schema_text then return nil end
    
    -- 1. Build Type Library from all MSG: sections
    local type_lib = {}
    local sections = {}
    for section in schema_text:gmatch("([^=]+)") do
        local type_name = section:match("MSG:%s+([%w_/]+)")
        if type_name then
            type_lib[type_name] = parse_single_definition(section)
        else
            -- First section is the main message (usually doesn't have a MSG: header)
            table.insert(sections, section)
        end
    end
    
    local main_fields = parse_single_definition(sections[1] or "")
    local flattened = {}
    local current_offset = 4 -- Skip ROS2 CDR Header
    
    -- 2. Recursive Resolver
    local function resolve(fields, prefix, offset)
        for _, f in ipairs(fields) do
            local name = (prefix == "") and f.name or (prefix .. "." .. f.name)
            
            if PRIMITIVES[f.type] then
                local info = PRIMITIVES[f.type]
                offset = math.ceil(offset / info.size) * info.size
                table.insert(flattened, { type = f.type, name = name, info = info, offset = offset })
                offset = offset + info.size
            elseif f.type == "string" then
                offset = math.ceil(offset / 4) * 4
                offset = offset + 4 -- Skip string length, skip data for now
            elseif type_lib[f.type] or type_lib[f.type:gsub(".*/", "")] then
                -- Handle nested complex type (with or without package prefix)
                local sub_fields = type_lib[f.type] or type_lib[f.type:gsub(".*/", "")]
                offset = resolve(sub_fields, name, offset)
            else
                -- Unknown type or array, skip for now to maintain alignment
                -- (In full industrial implementation, we would handle arrays/sequences)
            end
        end
        return offset
    end
    
    resolve(main_fields, "", current_offset)
    return #flattened > 0 and flattened or nil
end

function M.decode(data_ptr, fields)
    if not data_ptr or not fields then return nil end
    local results = {}
    for _, field in ipairs(fields) do
        local ptr = ffi.cast(field.info.ffi, data_ptr + field.offset)
        local val = ptr[0]
        if field.type == "bool" then val = val and "true" or "false" end
        table.insert(results, { name = field.name, value = val, fmt = field.info.fmt })
    end
    return results
end

return M
