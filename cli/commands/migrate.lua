-- namtar/cli/commands/migrate.lua

local Migrations = require("namtar.db.migrations")

return {
    name = "migrate",
    description = "Run database migrations",
    run = function(app, args)
        local path = args[1] or "migrations"
        local m = Migrations:new(app.db, path)
        local count = m:run()
        print("Ran " .. count .. " migration(s)")
    end
}
