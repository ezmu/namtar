-- namtar/orm/model.lua
-- Unified Model (BaseModel v5)

local Sanitize = require("namtar.utils.sanitize")
local Query = require("namtar.orm.query")
local Schema = require("namtar.orm.schema")

local Model = {}
Model.__index = Model

-- table cache: {table_name = {col = true}}
local table_cache = {}

function Model.new(doctype, db)
    if not db then error("Database connection required") end
    local safe = Sanitize.identifier(doctype)
    if safe == "" then error("Invalid doctype: " .. tostring(doctype)) end
    if safe ~= doctype then error("Doctype contains invalid chars: " .. doctype) end

    return setmetatable({
        doctype = safe,
        db = db,
        table_name = safe:lower() .. "s",
        fields = {},
        field_names = {},
        column_cache = nil,
        placeholder_cache = nil,
        _id_cache = {},
    }, Model)
end

function Model:set_fields(fields)
    if type(fields) ~= "table" then error("Fields must be table") end
    local safe_fields = {}
    local names = {}
    local seen = {}
    for _, f in ipairs(fields) do
        if type(f) ~= "table" then error("Each field must be table") end
        local n = f.fieldname
        if not Sanitize.is_safe(n) then error("Invalid field: " .. tostring(n)) end
        if Sanitize.is_reserved(n) then error("Reserved keyword: " .. n) end
        if seen[n] then error("Duplicate field: " .. n) end
        seen[n] = true
        local copy = {}
        for k, v in pairs(f) do copy[k] = v end
        copy.fieldname = Sanitize.identifier(n)
        table.insert(safe_fields, copy)
        table.insert(names, copy.fieldname)
    end
    self.fields = safe_fields
    self.field_names = names
    if #safe_fields > 0 then
        local cols, ph = {}, {}
        for i, f in ipairs(safe_fields) do
            cols[i] = Sanitize.escape_field(f.fieldname)
            ph[i] = "?"
        end
        self.column_cache = table.concat(cols, ", ")
        self.placeholder_cache = table.concat(ph, ", ")
    end
    return self
end

function Model:create_table()
    return self.db:execute(Schema.create_table_sql(self.table_name, self.fields))
end

function Model:sync_schema()
    return Schema.sync(self.db, self.table_name, self.fields)
end

function Model:query()
    return Query:new(self.table_name, self.db)
end

function Model:insert(data)
    if type(data) ~= "table" then return nil, "Invalid data" end
    if #self.fields == 0 then return nil, "No fields defined" end
    local cols, ph, vals, idx = {}, {}, {}, 1
    for _, f in ipairs(self.fields) do
        local v = data[f.fieldname]
        if v ~= nil then
            cols[idx] = Sanitize.escape_field(f.fieldname)
            ph[idx] = "?"
            vals[idx] = v
            idx = idx + 1
        end
    end
    if #cols == 0 then return nil, "No data" end
    local sql = "INSERT INTO " .. Sanitize.escape_field(self.table_name) ..
                " (" .. table.concat(cols, ", ") .. ") VALUES (" .. table.concat(ph, ", ") .. ")"
    return self.db:execute(sql, vals)
end

function Model:insert_batch(data_list)
    if type(data_list) ~= "table" or #data_list == 0 then
        return nil, "No data"
    end
    if #self.fields == 0 then return nil, "No fields defined" end

    local results = {}
    -- Check if we can do multi-row (all same fields)
    -- Simplified: batch each row
    for _, data in ipairs(data_list) do
        local id, err = self:insert(data)
        table.insert(results, {id = id, error = err})
    end
    return results
end

function Model:find(id)
    if not id then return nil end
    if self._id_cache[id] then return self._id_cache[id] end
    local sql = "SELECT * FROM " .. Sanitize.escape_field(self.table_name) .. " WHERE id = ?"
    local r = self.db:query(sql, {id})
    local row = r and r[1] or nil
    if row then self._id_cache[id] = row end
    return row
end

function Model:all()
    return self.db:query("SELECT * FROM " .. Sanitize.escape_field(self.table_name)) or {}
end

function Model:update(id, data)
    if not id then return nil, "No id" end
    if type(data) ~= "table" then return nil, "Invalid data" end
    local set_parts, vals, idx = {}, {}, 1
    for _, f in ipairs(self.fields) do
        local v = data[f.fieldname]
        if v ~= nil then
            set_parts[idx] = Sanitize.escape_field(f.fieldname) .. " = ?"
            vals[idx] = v
            idx = idx + 1
        end
    end
    if #set_parts == 0 then return nil, "No data" end
    vals[idx] = id
    local sql = "UPDATE " .. Sanitize.escape_field(self.table_name) ..
                " SET " .. table.concat(set_parts, ", ") ..
                ", updated_at = CURRENT_TIMESTAMP WHERE id = ?"
    local result = self.db:execute(sql, vals)
    self._id_cache[id] = nil
    return result
end

function Model:delete(id)
    if not id then return nil, "No id" end
    local r = self.db:execute(
        "DELETE FROM " .. Sanitize.escape_field(self.table_name) .. " WHERE id = ?",
        {id}
    )
    self._id_cache[id] = nil
    return r
end

function Model:count()
    local r = self.db:query("SELECT COUNT(*) as cnt FROM " .. Sanitize.escape_field(self.table_name))
    return r and r[1] and r[1].cnt or 0
end

function Model:exists(id)
    if not id then return false end
    local r = self.db:query(
        "SELECT 1 FROM " .. Sanitize.escape_field(self.table_name) .. " WHERE id = ? LIMIT 1",
        {id}
    )
    return r and #r > 0
end

function Model:where(column, op, value)
    return self:query():where(column, op, value):get()
end

function Model:clear_cache()
    self._id_cache = {}
end

return Model
