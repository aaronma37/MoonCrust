local M = {}

function M.process(input_msg, config, context)
    local path = config.file_path or "/tmp/mc_output.txt"
    local af = io.open(path, "w")
    if af then
        af:write(input_msg)
        af:close()
        return "SUCCESS: Wrote to " .. path
    end
    return "FAILURE: Could not open " .. path
end

return M
