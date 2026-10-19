-- namtar/core/doctype_manager.lua

local Model = require("namtar.orm.model")

local DoctypeManager = {}
DoctypeManager.__index = DoctypeManager

function DoctypeManager:new(db, opts)
    opts = opts or {}
    return setmetatable({
        db = db,
        doctypes = {},
        models = {},
        auto_migrate = opts.auto_migrate or false,
    }, DoctypeManager)
end

function DoctypeManager:register(name, fields, opts)
    opts = opts or {}
    self.doctypes[name] = {name = name, fields = fields, opts = opts}
    local model = Model.new(name, self.db):set_fields(fields)
    self.models[name] = model

    -- Auto-create or sync table
    if opts.auto_migrate or self.auto_migrate then
        model:sync_schema()
    end

    return self.doctypes[name]
end

function DoctypeManager:get(name) return self.doctypes[name] end
function DoctypeManager:get_fields(name)
    local dt = self.doctypes[name]
    return dt and dt.fields or {}
end

function DoctypeManager:list()
    local result = {}
    for name in pairs(self.doctypes) do table.insert(result, name) end
    return result
end

function DoctypeManager:model(name) return self.models[name] end

function DoctypeManager:migrate_all()
    local count = 0
    for name, model in pairs(self.models) do
        model:sync_schema()
        count = count + 1
    end
    return count
end

return DoctypeManager
