local json = require("mc.json")

local M = {}

local function call_gemini(prompt)
    local safe_prompt = prompt:gsub("'", "'''")
    local cmd = string.format("gemini -p '%s' 2>/dev/null", safe_prompt)
    local f = io.popen(cmd)
    if not f then return "Gemini Error" end
    local res = f:read("*a")
    f:close()
    return res
end

local function call_ollama(model, prompt)
    local safe_prompt = prompt:gsub('"', '"'):gsub("'", "'")
    local cmd = string.format([[curl -s -X POST http://localhost:11434/api/generate -d '{"model": "%s", "prompt": "%s", "stream": false}' 2>/dev/null]], model, safe_prompt)
    local f = io.popen(cmd)
    if not f then return "Ollama Error" end
    local res = f:read("*a")
    f:close()
    local ok, data = pcall(json.decode, res)
    if ok and data and data.response then return data.response end
    return "Ollama Offline"
end

function M.process(input_msg, config, context)
    local model = config.model or "gemini"
    local prompt = config.prompt or "Process"
    
    local final_prompt = prompt
    if context.recalled_context then final_prompt = final_prompt .. context.recalled_context end
    if context.history_context then final_prompt = final_prompt .. context.history_context end
    final_prompt = final_prompt .. " | Input: " .. input_msg

    if model:find("gemini") == 1 then
        return call_gemini(final_prompt)
    else
        return call_ollama(model, final_prompt)
    end
end

return M
