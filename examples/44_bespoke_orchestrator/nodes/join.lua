local M = {}
local join_buffer = {}

function M.process(input_msg, config, context)
    table.insert(join_buffer, input_msg)
    if #join_buffer >= (config.wait_count or 2) then
        local res = table.concat(join_buffer, " + ")
        join_buffer = {}
        return res
    end
    return nil -- Wait for more
end

return M
