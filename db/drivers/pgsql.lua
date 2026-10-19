-- namtar/db/drivers/pgsql.lua
-- PostgreSQL driver via luasql.postgres

local Driver = {}
Driver.__index = Driver

local function escape(value)
    if value == nil then return "NULL" end
    if type(value) == "number" then return tostring(value) end
    if type(value) == "boolean" then return value and "true" or "false" end
    return "'" .. tostring(value):gsub("'", "''") .. "'"
end

local function bind(sql, params)
    if not params or #params == 0 then return sql end
    local out = {}
    local idx = 1
    local p = 1
    while idx <= #sql do
        local c = sql:sub(idx, idx)
        if c == '?' then
            out[#out + 1] = escape(params[p])
            p = p + 1
        else
            out[#out + 1] = c
        end
        idx = idx + 1
    end
    return table.concat(out)
end

function Driver.connect(config)
    local luasql = require("luasql.postgres")
    local env = luasql.postgres()
    local raw = env:connect(
        config.database or "namtar",
        config.username or "postgres",
        config.password or "",
        config.host or "127.0.0.1",
        config.port or 5432
    )

    local conn = { raw = raw, env = env }

    function conn:query(sql, params)
        local final_sql = bind(sql, params)
        local cur = self.raw:execute(final_sql)
        if not cur or type(cur) ~= "userdata" then return {} end
        local result = {}
        local row = cur:fetch({}, "a")
        while row do
            table.insert(result, row)
            row = cur:fetch({}, "a")
        end
        cur:close()
        return result
    end

    function conn:execute(sql, params)
        local final_sql = bind(sql, params)
        local ok, err = self.raw:execute(final_sql)
        if not ok then return nil, err end
        return true
    end

    function conn:close()
        if self.raw then self.raw:close() self.raw = nil end
        if self.env then self.env:close() self.env = nil end
    end

    return conn
end

return Driver
