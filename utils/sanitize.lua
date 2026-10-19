-- namtar/utils/sanitize.lua

local Sanitize = {}

local RESERVED = {
    select = true, insert = true, update = true, delete = true,
    drop = true, create = true, alter = true, table = true,
    database = true, where = true, join = true,
    order = true, limit = true, from = true, into = true,
    values = true, set = true, union = true, distinct = true,
    count = true, sum = true, avg = true, max = true, min = true,
}

function Sanitize.identifier(name)
    if not name then return "" end
    return tostring(name):gsub("[^%w_]", "")
end

function Sanitize.is_safe(name)
    if not name or name == "" then return false end
    return tostring(name):match("^[%w_]+$") ~= nil
end

function Sanitize.escape_field(name)
    return "`" .. Sanitize.identifier(name) .. "`"
end

function Sanitize.is_reserved(name)
    return RESERVED[tostring(name):lower()] == true
end

function Sanitize.value(v)
    if v == nil then return "NULL" end
    if type(v) == "number" then return tostring(v) end
    if type(v) == "boolean" then return v and "1" or "0" end
    return "'" .. tostring(v):gsub("'", "''") .. "'"
end

return Sanitize
