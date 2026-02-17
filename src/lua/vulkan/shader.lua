local ffi = require("ffi")
local vk = require("vulkan.ffi")

local M = {}

local function command_ok(result)
    -- LuaJIT/Lua variants return either boolean or numeric status from os.execute.
    return result == true or result == 0
end

function M.compile_glsl(source, stage)
    -- Map Vulkan stage to glslc flag
    local stage_map = {
        [vk.VK_SHADER_STAGE_VERTEX_BIT] = "vert",
        [vk.VK_SHADER_STAGE_FRAGMENT_BIT] = "frag",
        [vk.VK_SHADER_STAGE_COMPUTE_BIT] = "comp"
    }
    local ext = stage_map[stage] or "glsl"
    
    local tmp_in = os.tmpname() .. "." .. ext
    local tmp_out = os.tmpname() .. ".spv"
    
    local f = io.open(tmp_in, "w")
    if not f then
        error("Failed to create temporary shader source: " .. tostring(tmp_in))
    end
    f:write(source)
    f:close()
    
    local have_glslc = os.execute("command -v glslc >/dev/null 2>&1")
    if not command_ok(have_glslc) then
        error("glslc not found in PATH. Install shaderc (e.g. package 'glslc').")
    end

    local cmd = string.format("glslc %q -o %q", tmp_in, tmp_out)
    local success = os.execute(cmd)
    
    if not command_ok(success) then
        error("Shader compilation failed for stage: " .. tostring(stage) .. " using command: " .. cmd)
    end
    
    local f_out = io.open(tmp_out, "rb")
    if not f_out then
        error("glslc did not produce output SPIR-V: " .. tostring(tmp_out))
    end
    local data = f_out:read("*all")
    f_out:close()
    
    -- Cleanup
    os.remove(tmp_in)
    os.remove(tmp_out)
    
    return data
end

function M.create_module(device, spirv_data)
    local size = #spirv_data
    local pCode = ffi.new("uint8_t[?]", size)
    ffi.copy(pCode, spirv_data, size)
    
    local info = ffi.new("VkShaderModuleCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        codeSize = size,
        pCode = ffi.cast("uint32_t*", pCode)
    })
    
    local pModule = ffi.new("VkShaderModule[1]")
    local result = vk.vkCreateShaderModule(device, info, nil, pModule)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create VkShaderModule: " .. tostring(result))
    end
    
    return pModule[0]
end

return M
