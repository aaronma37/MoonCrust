local M = {}

function M.process(input_msg, config, context)
    return config.value or "Constant"
end

return M
