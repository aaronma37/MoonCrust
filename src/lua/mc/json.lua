-- Simple JSON parser for MoonCrust (LuaJIT)
-- Based on rxi/json.lua but simplified for our needs.

local json = {}

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v then res[v] = true end
  end
  return res
end

local space_chars   = create_set(" ", string.char(9), string.char(13), string.char(10))
local delim_chars   = create_set(" ", string.char(9), string.char(13), string.char(10), ",", "]", "}")
local escape_chars  = create_set(string.char(92), "/", string.char(34), "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  ["true"]  = true,
  ["false"] = false,
  ["null"]  = nil,
}

local function next_char(str, idx)
  while idx <= #str and space_chars[str:sub(idx, idx)] do
    idx = idx + 1
  end
  return idx, str:sub(idx, idx)
end

local function parse_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == string.char(10) then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error(string.format("%s at line %d, column %d", msg, line_count, col_count))
end

local function parse_string(str, idx)
  local res = ""
  local j = idx + 1
  while j <= #str do
    local c = str:sub(j, j)
    if c == string.char(34) then
      return j + 1, res
    elseif c == string.char(92) then
      local next_c = str:sub(j + 1, j + 1)
      if next_c == "u" then
        -- Hex escape (minimal implementation for now)
        res = res .. "?"
        j = j + 6
      else
        local esc = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
        res = res .. (esc[next_c] or next_c)
        j = j + 2
      end
    else
      res = res .. c
      j = j + 1
    end
  end
  parse_error(str, idx, "expected closing quote for string")
end

local function parse_number(str, idx)
  local j = idx
  while j <= #str and not delim_chars[str:sub(j, j)] do
    j = j + 1
  end
  local s = str:sub(idx, j - 1)
  local n = tonumber(s)
  if not n then
    parse_error(str, idx, "invalid number '" .. s .. "'")
  end
  return j, n
end

local function parse_literal(str, idx)
  local j = idx
  while j <= #str and not delim_chars[str:sub(j, j)] do
    j = j + 1
  end
  local s = str:sub(idx, j - 1)
  if not literals[s] then
    parse_error(str, idx, "invalid literal '" .. s .. "'")
  end
  return j, literal_map[s]
end

local function parse_value(str, idx)
  local char
  idx, char = next_char(str, idx)
  if char == "{" then
    return json.parse_object(str, idx)
  elseif char == "[" then
    return json.parse_array(str, idx)
  elseif char == string.char(34) then
    return parse_string(str, idx)
  elseif char:match("[%d%-]") then
    return parse_number(str, idx)
  else
    return parse_literal(str, idx)
  end
end

function json.parse_array(str, idx)
  local res = {}
  idx = idx + 1
  local char
  idx, char = next_char(str, idx)
  if char == "]" then
    return idx + 1, res
  end
  while true do
    local val
    idx, val = parse_value(str, idx)
    table.insert(res, val)
    idx, char = next_char(str, idx)
    if char == "]" then
      return idx + 1, res
    elseif char == "," then
      idx = idx + 1
    else
      parse_error(str, idx, "expected ']' or ','")
    end
  end
end

function json.parse_object(str, idx)
  local res = {}
  idx = idx + 1
  local char
  idx, char = next_char(str, idx)
  if char == "}" then
    return idx + 1, res
  end
  while true do
    local key, val
    if char ~= string.char(34) then
      parse_error(str, idx, "expected string for key")
    end
    idx, key = parse_string(str, idx)
    idx, char = next_char(str, idx)
    if char ~= ":" then
      parse_error(str, idx, "expected ':'")
    end
    idx, val = parse_value(str, idx + 1)
    res[key] = val
    idx, char = next_char(str, idx)
    if char == "}" then
      return idx + 1, res
    elseif char == "," then
      idx = idx + 1
      idx, char = next_char(str, idx)
    else
      parse_error(str, idx, "expected '}' or ','")
    end
  end
end

function json.decode(str)
  local _, res = parse_value(str, 1)
  return res
end

return json
