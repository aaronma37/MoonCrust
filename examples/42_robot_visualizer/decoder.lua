local ffi = require("ffi")

local M = {}

-- Map schema types to FFI types and sizes
local TYPE_MAP = {
    ["float32"] = { ffi = "float*", size = 4, fmt = "%.4f" },
    ["float64"] = { ffi = "double*", size = 8, fmt = "%.6f" },
    ["double"]  = { ffi = "double*", size = 8, fmt = "%.6f" },
    ["float"]   = { ffi = "float*", size = 4, fmt = "%.4f" },
    ["int32"]   = { ffi = "int32_t*", size = 4, fmt = "%d" },
    ["uint32"]  = { ffi = "uint32_t*", size = 4, fmt = "%u" },
    ["int64"]   = { ffi = "int64_t*", size = 8, fmt = "%lld" },
    ["uint64"]  = { ffi = "uint64_t*", size = 8, fmt = "%llu" },
    ["bool"]    = { ffi = "bool*", size = 1, fmt = "%s" },
    ["uint8"]   = { ffi = "uint8_t*", size = 1, fmt = "%u" },
}

-- Simple schema parser (Handles "type name" lines)
function M.parse_schema(schema_text)
    if not schema_text then return nil end
    local fields = {}
    local offset = 0
    
    for line in schema_text:gmatch("([^\r\n]+)") do
        line = line:gsub("#.*", ""):match("^%s*(.-)%s*$")
        if line ~= "" then
            local t, n = line:match("^([%w_]+)%s+([%w_]+)")
            if t and n and TYPE_MAP[t] then
                local info = TYPE_MAP[t]
                -- Apply alignment
                offset = math.ceil(offset / info.size) * info.size
                table.insert(fields, { type = t, name = n, info = info, offset = offset })
                offset = offset + info.size
            end
        end
    end
    return #fields > 0 and fields or nil
end

-- Dynamic Decoder: Extracts values based on parsed fields
function M.decode(data_ptr, fields)
    if not data_ptr or not fields then return nil end
    local results = {}
    
    for _, field in ipairs(fields) do
        local ptr = ffi.cast(field.info.ffi, data_ptr + field.offset)
        local val = ptr[0]
        
        if field.type == "bool" then
            val = val and "true" or "false"
        end
        
        table.insert(results, { name = field.name, value = val, fmt = field.info.fmt })
    end
    
    return results
end

return M
