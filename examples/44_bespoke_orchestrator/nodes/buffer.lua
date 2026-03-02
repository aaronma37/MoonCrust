local M = {}
local sliding_buffer = {}

function M.process(input_msg, config, context)
    table.insert(sliding_buffer, input_msg)
    while #sliding_buffer > (config.wait_count or 5) do
        table.remove(sliding_buffer, 1)
    end
    return table.concat(sliding_buffer, ",")
end

return M
