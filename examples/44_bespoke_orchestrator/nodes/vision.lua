local M = {}

function M.process(input_msg, config, context)
    local prompt = config.prompt or "Analyze visuals"
    local file_paths = input_msg
    
    local paths = {}
    for p in file_paths:gmatch("([^,]+)") do
        table.insert(paths, p:gsub("^%s*(.-)%s*$", "%1"))
    end
    
    local files_str = table.concat(paths, " ")
    local final_prompt = prompt
    if context.recalled_context then final_prompt = final_prompt .. context.recalled_context end
    if context.history_context then final_prompt = final_prompt .. context.history_context end

    local safe_prompt = final_prompt:gsub("'", "'''")
    local cmd = string.format("gemini -p '%s %s' 2>/dev/null", safe_prompt, files_str)
    local f = io.popen(cmd)
    if not f then return "Vision Error" end
    local res = f:read("*a")
    f:close()
    return res
end

return M
