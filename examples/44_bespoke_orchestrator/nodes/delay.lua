local M = {}

function M.process(input_msg, config, context)
    os.execute("sleep " .. (config.seconds or 1.0))
    return input_msg
end

return M
