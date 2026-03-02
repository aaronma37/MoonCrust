local M = {}

function M.process(input_msg, config, context)
    local base_cmd = config.shell_cmd or "ls"
    local final_cmd = base_cmd .. " " .. input_msg
    local f = io.popen(final_cmd .. " 2>&1")
    if f then
        local res = f:read("*a")
        f:close()
        return res
    end
    return "Terminal Execution Error"
end

return M
