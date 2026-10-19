-- namtar/utils/json.lua
-- JSON encoder/decoder with unicode, depth limit, circular detection

local json = {}

local MAX_DEPTH = 100

local escape_map = {
    ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b',
    ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r',
    ['\t'] = '\\t',
}

local function escape_string(s)
    return s:gsub('[%z\1-\31\\"]', function(c)
        return escape_map[c] or string.format('\\u%04x', c:byte())
    end)
end

local function encode_value(v, stack, depth)
    if depth > MAX_DEPTH then error("JSON encode: max depth exceeded") end
    local t = type(v)

    if v == nil then return "null" end
    if t == "boolean" then return v and "true" or "false" end

    if t == "number" then
        if v ~= v then return "null" end
        if v == math.huge or v == -math.huge then return "null" end
        if math.floor(v) == v and math.abs(v) < 1e15 then
            return string.format("%d", v)
        end
        return string.format("%.14g", v)
    end

    if t == "string" then
        return '"' .. escape_string(v) .. '"'
    end

    if t == "table" then
        if stack[v] then error("Circular reference") end
        stack[v] = true

        local max_n = 0
        local count = 0
        local is_array = true
        for k, _ in pairs(v) do
            count = count + 1
            if type(k) ~= "number" then
                is_array = false
            elseif k > max_n then
                max_n = k
            end
        end
        if count ~= max_n then is_array = false end

        local parts = {}
        if is_array then
            for i = 1, max_n do
                parts[i] = encode_value(v[i], stack, depth + 1)
            end
            stack[v] = nil
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, val in pairs(v) do
                local key = type(k) == "string" and k or tostring(k)
                table.insert(parts, '"' .. escape_string(key) .. '":' .. encode_value(val, stack, depth + 1))
            end
            stack[v] = nil
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end

    return "null"
end

function json.encode(v)
    return encode_value(v, {}, 0)
end

-- ============================================================
-- Decoder
-- ============================================================

local function decode_value(str, pos, len)
    while pos <= len do
        local c = str:sub(pos, pos)
        if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then break end
        pos = pos + 1
    end

    if pos > len then return nil, pos end
    local c = str:sub(pos, pos)

    -- string
    if c == '"' then
        pos = pos + 1
        local buf = {}
        while pos <= len do
            local ch = str:sub(pos, pos)
            if ch == '\\' then
                local nc = str:sub(pos + 1, pos + 1)
                if nc == 'u' then
                    local hex = str:sub(pos + 2, pos + 5)
                    local code = tonumber(hex, 16)
                    if code then
                        if code < 0x80 then
                            table.insert(buf, string.char(code))
                        elseif code < 0x800 then
                            table.insert(buf, string.char(
                                0xC0 + math.floor(code / 0x40),
                                0x80 + (code % 0x40)
                            ))
                        else
                            table.insert(buf, string.char(
                                0xE0 + math.floor(code / 0x1000),
                                0x80 + (math.floor(code / 0x40) % 0x40),
                                0x80 + (code % 0x40)
                            ))
                        end
                    end
                    pos = pos + 6
                else
                    local map = {n="\n", t="\t", r="\r", b="\b", f="\f", ['"']='"', ['\\']="\\", ['/']="/"}
                    table.insert(buf, map[nc] or nc)
                    pos = pos + 2
                end
            elseif ch == '"' then
                pos = pos + 1
                return table.concat(buf), pos
            else
                table.insert(buf, ch)
                pos = pos + 1
            end
        end
        error("Unterminated string")
    end

    -- object
    if c == '{' then
        pos = pos + 1
        local obj = {}
        while pos <= len do
            while pos <= len and str:sub(pos, pos):match("%s") do pos = pos + 1 end
            if str:sub(pos, pos) == '}' then
                pos = pos + 1
                return obj, pos
            end
            local key, new_pos = decode_value(str, pos, len)
            pos = new_pos
            while pos <= len and str:sub(pos, pos):match("%s") do pos = pos + 1 end
            if str:sub(pos, pos) == ':' then pos = pos + 1 end
            local value, new_pos2 = decode_value(str, pos, len)
            pos = new_pos2
            obj[key] = value
            while pos <= len and str:sub(pos, pos):match("%s") do pos = pos + 1 end
            if str:sub(pos, pos) == ',' then pos = pos + 1 end
        end
        return obj, pos
    end

    -- array
    if c == '[' then
        pos = pos + 1
        local arr = {}
        while pos <= len do
            while pos <= len and str:sub(pos, pos):match("%s") do pos = pos + 1 end
            if str:sub(pos, pos) == ']' then
                pos = pos + 1
                return arr, pos
            end
            local value, new_pos = decode_value(str, pos, len)
            pos = new_pos
            table.insert(arr, value)
            while pos <= len and str:sub(pos, pos):match("%s") do pos = pos + 1 end
            if str:sub(pos, pos) == ',' then pos = pos + 1 end
        end
        return arr, pos
    end

    if str:sub(pos, pos + 3) == "true" then return true, pos + 4 end
    if str:sub(pos, pos + 4) == "false" then return false, pos + 5 end
    if str:sub(pos, pos + 3) == "null" then return nil, pos + 4 end

    if c:match("[%d%-]") then
        local start = pos
        pos = pos + 1
        while pos <= len and str:sub(pos, pos):match("[%d%.eE%+%-]") do
            pos = pos + 1
        end
        local num = tonumber(str:sub(start, pos - 1))
        return num, pos
    end

    error("Unexpected character at position " .. pos .. ": '" .. c .. "'")
end

function json.decode(str)
    if not str or str == "" then return nil end
    local ok, result = pcall(decode_value, str, 1, #str)
    if not ok then return nil end
    return result
end

return json
