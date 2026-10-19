-- namtar/orm/schema.lua
-- Table creation + auto-sync

local Sanitize = require("namtar.utils.sanitize")

local Schema = {}

local TYPE_MAP = {
    Data = "TEXT", Text = "TEXT", Int = "INTEGER", Float = "REAL",
    Date = "TEXT", Link = "INTEGER", Select = "TEXT", Check = "INTEGER",
    JSON = "TEXT", Boolean = "INTEGER", Datetime = "TEXT",
}

function Schema.field_to_sql(field)
    local name = Sanitize.escape_field(field.fieldname)
    local sql_type = TYPE_MAP[field.fieldtype] or "TEXT"
    local parts = {name, sql_type}

    if field.unique then table.insert(parts, "UNIQUE") end
    if field.required then table.insert(parts, "NOT NULL") end
    if field.default ~= nil then
        local v = field.default
        if type(v) == "string" then
            table.insert(parts, "DEFAULT '" .. v:gsub("'", "''") .. "'")
        elseif type(v) == "boolean" then
            table.insert(parts, "DEFAULT " .. (v and "1" or "0"))
        else
            table.insert(parts, "DEFAULT " .. tostring(v))
        end
    end

    return table.concat(parts, " ")
end

function Schema.create_table_sql(table_name, fields)
    local parts = {
        "CREATE TABLE IF NOT EXISTS " .. Sanitize.escape_field(table_name),
        " (id INTEGER PRIMARY KEY AUTOINCREMENT",
    }
    for _, field in ipairs(fields) do
        table.insert(parts, ", " .. Schema.field_to_sql(field))
    end
    table.insert(parts, ", created_at DATETIME DEFAULT CURRENT_TIMESTAMP")
    table.insert(parts, ", updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)")
    return table.concat(parts, "")
end

function Schema.existing_columns(db, table_name)
    local rows = db:query("PRAGMA table_info(" .. Sanitize.escape_field(table_name) .. ")")
    local cols = {}
    for _, row in ipairs(rows) do
        cols[row.name] = true
    end
    return cols
end

function Schema.sync(db, table_name, fields)
    -- أنشئ إن لم يوجد
    db:execute(Schema.create_table_sql(table_name, fields))

    -- فحص الأعمدة الناقصة
    local existing = Schema.existing_columns(db, table_name)
    local added = 0
    for _, field in ipairs(fields) do
        if not existing[field.fieldname] then
            local sql = "ALTER TABLE " .. Sanitize.escape_field(table_name) ..
                        " ADD COLUMN " .. Schema.field_to_sql(field)
            db:execute(sql)
            added = added + 1
        end
    end
    return added
end

return Schema
