-- namtar/utils/table.lua

local Table = {}

function Table.keys(t)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    return keys
end

function Table.values(t)
    local values = {}
    for _, v in pairs(t) do table.insert(values, v) end
    return values
end

function Table.merge(a, b)
    local result = {}
    for k, v in pairs(a) do result[k] = v end
    for k, v in pairs(b) do result[k] = v end
    return result
end

function Table.deep_merge(a, b)
    local result = {}
    for k, v in pairs(a) do
        if type(v) == "table" and type(b[k]) == "table" then
            result[k] = Table.deep_merge(v, b[k])
        else
            result[k] = v
        end
    end
    for k, v in pairs(b) do
        if result[k] == nil then result[k] = v end
    end
    return result
end

function Table.map(t, fn)
    local result = {}
    for i, v in ipairs(t) do result[i] = fn(v, i) end
    return result
end

function Table.filter(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        if fn(v, i) then table.insert(result, v) end
    end
    return result
end

function Table.reduce(t, fn, init)
    local acc = init
    for i, v in ipairs(t) do acc = fn(acc, v, i) end
    return acc
end

function Table.find(t, fn)
    for i, v in ipairs(t) do
        if fn(v, i) then return v, i end
    end
    return nil
end

function Table.contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

function Table.slice(t, start, finish)
    finish = finish or #t
    local result = {}
    for i = start, finish do table.insert(result, t[i]) end
    return result
end

return Table
