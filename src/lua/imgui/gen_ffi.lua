local ffi = require("ffi")

local M = {}

function M.generate(base_path)
    local s_e = require(base_path .. ".cimgui.generator.output.structs_and_enums")
    local defs = require(base_path .. ".cimgui.generator.output.definitions")
    
    local cdef = [[
        typedef struct ImVec2_c { float x, y; } ImVec2_c;
        typedef struct ImVec4_c { float x, y, z, w; } ImVec4_c;
        typedef struct ImColor_c { ImVec4_c Value; } ImColor_c;
        typedef struct ImRect_c { ImVec2_c Min, Max; } ImRect_c;
        typedef unsigned short ImDrawIdx;
        typedef unsigned int ImGuiID;
        typedef void* ImTextureID;
    ]]
    
    -- Forward declare structs
    for name, _ in pairs(s_e.structs) do
        cdef = cdef .. "typedef struct " .. name .. " " .. name .. ";
"
    end
    
    -- Define Enums
    for enum_name, values in pairs(s_e.enums) do
        cdef = cdef .. "typedef enum {
"
        for _, v in ipairs(values) do
            cdef = cdef .. "    " .. v.name .. " = " .. v.calc_value .. ",
"
        end
        cdef = cdef .. "} " .. enum_name .. ";
"
    end
    
    -- Define Structs (simple version)
    for name, members in pairs(s_e.structs) do
        cdef = cdef .. "struct " .. name .. " {
"
        for _, m in ipairs(members) do
            local m_type = m.type:gsub("const ", "")
            -- Simple type mapping
            if m_type == "ImVec2" then m_type = "ImVec2_c" end
            if m_type == "ImVec4" then m_type = "ImVec4_c" end
            cdef = cdef .. "    " .. m_type .. " " .. m.name .. ";
"
        end
        cdef = cdef .. "};
"
    end
    
    -- Define Functions
    for func_name, overloads in pairs(defs) do
        for _, ov in ipairs(overloads) do
            if not ov.templated then
                local ret = ov.ret or "void"
                if ret == "ImVec2" then ret = "ImVec2_c" end
                if ret == "ImVec4" then ret = "ImVec4_c" end
                
                local args = ov.args:gsub("const ", "")
                args = args:gsub("ImVec2", "ImVec2_c"):gsub("ImVec4", "ImVec4_c")
                
                cdef = cdef .. ret .. " " .. ov.cimguiname .. args .. ";
"
            end
        end
    end
    
    return cdef
end

return M
