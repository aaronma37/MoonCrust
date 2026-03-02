local json = require("mc.json")

local M = {}

local function call_gemini(prompt, file_paths)
    local safe_prompt = prompt:gsub("'", "'''")
    local files_str = ""
    if file_paths and #file_paths > 0 then
        files_str = " " .. table.concat(file_paths, " ")
    end
    
    local cmd = string.format("gemini -p '%s%s' 2>/dev/null", safe_prompt, files_str)
    local f = io.popen(cmd)
    if not f then return "Gemini CLI Error" end
    local res = f:read("*a")
    f:close()
    return res
end

local function call_ollama(model, prompt)
    local safe_prompt = prompt:gsub('"', '"'):gsub("'", "'")
    local cmd = string.format([[curl -s -X POST http://localhost:11434/api/generate -d '{"model": "%s", "prompt": "%s", "stream": false}' 2>/dev/null]], model, safe_prompt)
    local f = io.popen(cmd)
    if f then
        local res = f:read("*a")
        f:close()
        local ok, data = pcall(json.decode, res)
        if ok and data and data.response then return data.response end
    end
    return "Ollama Error / Offline"
end

function M.process(input_msg, config, context)
    local model = config.model or "gemini"
    local prompt = config.prompt or "You are a helpful agent."
    
    -- 1. Multimodal Detection
    local files = {}
    -- If input contains comma-separated paths or single paths ending in image/video extensions
    for path in input_msg:gmatch("([^,]+)") do
        local p = path:gsub("^%s*(.-)%s*$", "%1")
        if p:find("%.png$") or p:find("%.jpg$") or p:find("%.jpeg$") or p:find("%.mp4$") then
            table.insert(files, p)
        end
    end

    -- 2. Context Assembly
    local final_prompt = prompt
    if context.recalled_context then final_prompt = final_prompt .. context.recalled_context end
    if context.history_context then final_prompt = final_prompt .. context.history_context end
    
    -- If we have files but NO text message, input_msg is just the paths.
    -- If we have text AND files, the files were detected from the string.
    final_prompt = final_prompt .. " | Input: " .. input_msg

    -- 3. Provider Routing
    if model:find("gemini") == 1 then
        return call_gemini(final_prompt, files)
    else
        return call_ollama(model, final_prompt)
    end
end

return M
