local M = {}

function M.process(input_msg, config, context)
    local chunk = load("local input = ...; return " .. (config.condition or "true"))
    if chunk then
        local ok, res = pcall(chunk, input_msg)
        if ok and res then return input_msg end
    end
    return nil -- Dropped
end

return M
