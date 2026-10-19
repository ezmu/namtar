-- namtar/orm/query.lua
-- Unified Query Builder (fixed: order_col instead of order_by field)

local Sanitize = require("namtar.utils.sanitize")

local Query = {}
Query.__index = Query

function Query:new(table_name, db)
    if not Sanitize.is_safe(table_name) then
        error("Invalid table name: " .. tostring(table_name))
    end
    return setmetatable({
        table = table_name,
        db = db,
        selects = {"*"},
        wheres = {},
        joins = {},
        order_col = nil,
        order_dir = "ASC",
        limit_val = nil,
        offset_val = nil,
        group_cols = nil,
        having = nil,
        bindings = {},
    }, Query)
end

function Query:select(...)
    local args = {...}
    if #args == 1 and type(args[1]) == "table" then
        self.selects = args[1]
    else
        self.selects = args
    end
    return self
end

function Query:where(column, operator, value)
    if not Sanitize.is_safe(column) then
        error("Invalid column: " .. tostring(column))
    end
    if value == nil then
        value = operator
        operator = "="
    end
    local valid = {["="]=true, [">"]=true, ["<"]=true, [">="]=true, ["<="]=true,
                   ["!="]=true, ["LIKE"]=true, ["NOT LIKE"]=true}
    operator = operator:upper()
    if not valid[operator] then
        error("Invalid operator: " .. tostring(operator))
    end
    table.insert(self.wheres, {
        type = "basic",
        column = Sanitize.escape_field(column),
        operator = operator,
        value = value,
    })
    table.insert(self.bindings, value)
    return self
end

function Query:where_in(column, values)
    if not Sanitize.is_safe(column) then error("Invalid column: " .. column) end
    if type(values) ~= "table" or #values == 0 then
        error("WHERE IN requires non-empty table")
    end
    table.insert(self.wheres, {
        type = "in",
        column = Sanitize.escape_field(column),
        values = values,
    })
    for _, v in ipairs(values) do table.insert(self.bindings, v) end
    return self
end

function Query:where_null(column)
    if not Sanitize.is_safe(column) then error("Invalid column: " .. column) end
    table.insert(self.wheres, {type = "null", column = Sanitize.escape_field(column), is_null = true})
    return self
end

function Query:where_not_null(column)
    if not Sanitize.is_safe(column) then error("Invalid column: " .. column) end
    table.insert(self.wheres, {type = "null", column = Sanitize.escape_field(column), is_null = false})
    return self
end

function Query:order_by(column, direction)
    if not Sanitize.is_safe(column) then error("Invalid column: " .. column) end
    self.order_col = Sanitize.escape_field(column)
    self.order_dir = (direction or "ASC"):upper()
    if self.order_dir ~= "ASC" and self.order_dir ~= "DESC" then
        error("Invalid direction: " .. direction)
    end
    return self
end

function Query:limit(n)
    if type(n) ~= "number" or n < 0 then error("Invalid limit") end
    self.limit_val = n
    return self
end

function Query:offset(n)
    if type(n) ~= "number" or n < 0 then error("Invalid offset") end
    self.offset_val = n
    return self
end

function Query:group_by(...)
    local args = {...}
    local cols = {}
    for _, c in ipairs(args) do
        if not Sanitize.is_safe(c) then error("Invalid column: " .. c) end
        table.insert(cols, Sanitize.escape_field(c))
    end
    self.group_cols = cols
    return self
end

function Query:join(table_name, col1, op, col2, kind)
    if not Sanitize.is_safe(table_name) then error("Invalid join table") end
    if not Sanitize.is_safe(col1) or not Sanitize.is_safe(col2) then
        error("Invalid join column")
    end
    table.insert(self.joins, {
        type = kind or "INNER",
        table = table_name,
        column1 = Sanitize.escape_field(col1),
        operator = op,
        column2 = Sanitize.escape_field(col2),
    })
    return self
end

function Query:left_join(table_name, col1, op, col2)
    return self:join(table_name, col1, op, col2, "LEFT")
end

function Query:build_sql()
    local parts = {}
    table.insert(parts, "SELECT " .. table.concat(self.selects, ", "))
    table.insert(parts, "FROM " .. Sanitize.escape_field(self.table))

    for _, j in ipairs(self.joins) do
        table.insert(parts, string.format("%s JOIN %s ON %s %s %s",
            j.type, Sanitize.escape_field(j.table), j.column1, j.operator, j.column2))
    end

    if #self.wheres > 0 then
        local where_parts = {}
        for _, w in ipairs(self.wheres) do
            if w.type == "basic" then
                table.insert(where_parts, w.column .. " " .. w.operator .. " ?")
            elseif w.type == "in" then
                local ph = {}
                for i = 1, #w.values do ph[i] = "?" end
                table.insert(where_parts, w.column .. " IN (" .. table.concat(ph, ", ") .. ")")
            elseif w.type == "null" then
                local op = w.is_null and "IS NULL" or "IS NOT NULL"
                table.insert(where_parts, w.column .. " " .. op)
            end
        end
        table.insert(parts, "WHERE " .. table.concat(where_parts, " AND "))
    end

    if self.group_cols and type(self.group_cols) == "table" and #self.group_cols > 0 then
        table.insert(parts, "GROUP BY " .. table.concat(self.group_cols, ", "))
    end

    if self.order_col then
        table.insert(parts, "ORDER BY " .. self.order_col .. " " .. self.order_dir)
    end

    if self.limit_val then
        table.insert(parts, "LIMIT " .. self.limit_val)
    end
    if self.offset_val then
        table.insert(parts, "OFFSET " .. self.offset_val)
    end

    return table.concat(parts, " ")
end

function Query:get()
    local sql = self:build_sql()
    return self.db:query(sql, self.bindings) or {}
end

function Query:first()
    self:limit(1)
    local r = self:get()
    return r and r[1] or nil
end

function Query:count()
    local old = self.selects
    self.selects = {"COUNT(*) as count"}
    local r = self:first()
    self.selects = old
    return r and r.count or 0
end

function Query:exists()
    return self:count() > 0
end

function Query:pluck(column)
    if not Sanitize.is_safe(column) then error("Invalid column") end
    local rows = self:get()
    local out = {}
    for _, row in ipairs(rows) do table.insert(out, row[column]) end
    return out
end

function Query:insert(data)
    if type(data) ~= "table" then return nil, "Invalid data" end
    local cols, ph, vals = {}, {}, {}
    for k, v in pairs(data) do
        if not Sanitize.is_safe(k) then return nil, "Invalid column: " .. k end
        table.insert(cols, Sanitize.escape_field(k))
        table.insert(ph, "?")
        table.insert(vals, v)
    end
    if #cols == 0 then return nil, "No data" end
    local sql = "INSERT INTO " .. Sanitize.escape_field(self.table) ..
                " (" .. table.concat(cols, ", ") .. ") VALUES (" .. table.concat(ph, ", ") .. ")"
    return self.db:execute(sql, vals)
end

function Query:update(data)
    if type(data) ~= "table" then return nil, "Invalid data" end
    local set_parts, vals = {}, {}
    for k, v in pairs(data) do
        if not Sanitize.is_safe(k) then return nil, "Invalid column: " .. k end
        table.insert(set_parts, Sanitize.escape_field(k) .. " = ?")
        table.insert(vals, v)
    end
    if #set_parts == 0 then return nil, "No data" end
    for _, b in ipairs(self.bindings) do table.insert(vals, b) end
    local sql = "UPDATE " .. Sanitize.escape_field(self.table) ..
                " SET " .. table.concat(set_parts, ", ")
    if #self.wheres > 0 then
        local wp = {}
        for _, w in ipairs(self.wheres) do
            if w.type == "basic" then
                table.insert(wp, w.column .. " " .. w.operator .. " ?")
            elseif w.type == "in" then
                local ph = {}
                for i = 1, #w.values do ph[i] = "?" end
                table.insert(wp, w.column .. " IN (" .. table.concat(ph, ", ") .. ")")
            elseif w.type == "null" then
                local op = w.is_null and "IS NULL" or "IS NOT NULL"
                table.insert(wp, w.column .. " " .. op)
            end
        end
        sql = sql .. " WHERE " .. table.concat(wp, " AND ")
    end
    return self.db:execute(sql, vals)
end

function Query:delete()
    if #self.wheres == 0 then
        return nil, "DELETE without WHERE not allowed"
    end
    local wp = {}
    for _, w in ipairs(self.wheres) do
        if w.type == "basic" then
            table.insert(wp, w.column .. " " .. w.operator .. " ?")
        elseif w.type == "in" then
            local ph = {}
            for i = 1, #w.values do ph[i] = "?" end
            table.insert(wp, w.column .. " IN (" .. table.concat(ph, ", ") .. ")")
        elseif w.type == "null" then
            local op = w.is_null and "IS NULL" or "IS NOT NULL"
            table.insert(wp, w.column .. " " .. op)
        end
    end
    local sql = "DELETE FROM " .. Sanitize.escape_field(self.table) ..
                " WHERE " .. table.concat(wp, " AND ")
    return self.db:execute(sql, self.bindings)
end

function Query:to_sql() return self:build_sql() end

return Query
