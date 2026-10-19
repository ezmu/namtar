-- namtar/orm/relations.lua
-- has_many, belongs_to, has_one

local Relations = {}

-- has_many: exam has many questions (foreign_key in questions table)
function Relations.has_many(source_model, target_model, foreign_key)
    local fk_value = source_model.id
    if not fk_value then return {} end
    return target_model:query():where(foreign_key, "=", fk_value):get()
end

-- belongs_to: question belongs to exam (foreign_key in questions table pointing to exams.id)
function Relations.belongs_to(source_row, target_model, foreign_key)
    local fk_value = source_row[foreign_key]
    if not fk_value then return nil end
    return target_model:find(fk_value)
end

-- has_one: user has one profile
function Relations.has_one(source_model, target_model, foreign_key)
    local fk_value = source_model.id
    if not fk_value then return nil end
    return target_model:query():where(foreign_key, "=", fk_value):first()
end

-- many_to_many via pivot table
function Relations.many_to_many(source_model, target_model, pivot_table, source_key, target_key)
    local fk_value = source_model.id
    if not fk_value then return {} end
    local db = source_model.db
    local sql = "SELECT t.* FROM " .. target_model.table_name .. " t " ..
                "INNER JOIN " .. pivot_table .. " p ON p." .. target_key .. " = t.id " ..
                "WHERE p." .. source_key .. " = ?"
    return db:query(sql, {fk_value}) or {}
end

return Relations
