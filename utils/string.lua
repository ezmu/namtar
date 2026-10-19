-- namtar/utils/string.lua

local String = {}

function String.starts_with(s, prefix) return s:sub(1, #prefix) == prefix end
function String.ends_with(s, suffix) return s:sub(-#suffix) == suffix end
function String.trim(s) return s:match("^%s*(.-)%s*$") end

function String.split(s, sep)
    local parts = {}
    for part in s:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

function String.join(parts, sep) return table.concat(parts, sep) end

function String.camel_case(s)
    return (s:gsub("_(%w)", function(c) return c:upper() end):gsub("^%l", string.upper))
end

function String.snake_case(s)
    return (s:gsub("(%u)", function(c) return "_" .. c:lower() end):gsub("^_", ""))
end

function String.kebab_case(s)
    return s:gsub("_", "-"):gsub("(%u)", function(c) return "-" .. c:lower() end):gsub("^%-", "")
end

function String.pascal_case(s)
    return (s:gsub("(%w+)", function(w) return w:sub(1,1):upper() .. w:sub(2):lower() end))
end

function String.random(n)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, n do
        local idx = math.random(1, #chars)
        table.insert(result, chars:sub(idx, idx))
    end
    return table.concat(result)
end

function String.uuid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return (template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end))
end

function String.url_decode(s)
    if not s then return nil end
    s = s:gsub("+", " ")
    s = s:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return s
end

function String.url_encode(s)
    if not s then return "" end
    return (s:gsub("([^%w%-%_%.~])", function(c)
        return string.format("%%%02X", c:byte())
    end))
end

return String
