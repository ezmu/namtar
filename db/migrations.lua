-- namtar/db/migrations.lua
-- Simple migration runner

local Migrations = {}
Migrations.__index = Migrations
local fs = require("namtar.utils.fs")

function Migrations:new(db, path)
    return setmetatable({
        db = db,
        path = path or "migrations",
        table = "_namtar_migrations",
    }, Migrations)
end

function Migrations:ensure_table()
    self.db:execute([[
        CREATE TABLE IF NOT EXISTS ]] .. self.table .. [[ (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            batch INTEGER DEFAULT 1,
            ran_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end

function Migrations:ran()
    self:ensure_table()
    local rows = self.db:query("SELECT name FROM " .. self.table)
    local set = {}
    for _, row in ipairs(rows) do set[row.name] = true end
    return set
end

function Migrations:run()
    self:ensure_table()
    local ran = self:ran()
    local files = fs.scan(self.path, "%.lua$")
    local count = 0

    for _, file in ipairs(files) do
        local name = file:match("([^/]+)%.lua$")
        if not ran[name] then
            local module_path = file:gsub("%.lua$", ""):gsub("/", ".")
            local ok, migration = pcall(require, module_path)
            if ok and migration then
                local up = migration.up or migration
                if type(up) == "function" then
                    up(self.db)
                    self.db:execute(
                        "INSERT INTO " .. self.table .. " (name) VALUES (?)",
                        {name}
                    )
                    print("✅ Migration: " .. name)
                    count = count + 1
                end
            else
                print("❌ Failed: " .. name .. " - " .. tostring(migration))
            end
        end
    end
    return count
end

function Migrations:rollback(steps)
    steps = steps or 1
    self:ensure_table()
    local rows = self.db:query(
        "SELECT name FROM " .. self.table .. " ORDER BY id DESC LIMIT " .. steps
    )
    for _, row in ipairs(rows) do
        local name = row.name
        local file = self.path .. "/" .. name
        local module_path = file:gsub("%.lua$", ""):gsub("/", ".")
        local ok, migration = pcall(require, module_path)
        if ok and migration and type(migration.down) == "function" then
            migration.down(self.db)
            self.db:execute("DELETE FROM " .. self.table .. " WHERE name = ?", {name})
            print("⏪ Rolled back: " .. name)
        end
    end
end

return Migrations
