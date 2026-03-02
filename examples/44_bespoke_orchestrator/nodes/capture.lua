local M = {}

function M.process(input_msg, config, context)
    local out_path = string.format("/tmp/mc_capture_%d.png", context.node_id)
    os.execute(string.format("scrot -o %s", out_path))
    return out_path
end

return M
