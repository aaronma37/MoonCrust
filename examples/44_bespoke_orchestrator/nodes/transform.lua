local M = {}

function M.process(input_msg, config, context)
    local chunk = load("local input = ...; " .. (config.expression or "return input"))
    if chunk then
        local ok, res = pcall(chunk, input_msg)
        return ok and tostring(res) or "Transform Error"
    end
    return "Invalid Expression"
end

return M
