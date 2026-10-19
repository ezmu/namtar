-- namtar/apps/starter/bootstrap.lua
-- Migration + Seeds bootstrap

local Migrations = require("namtar.db.migrations")
local Namtar = require("namtar")
local fs = require("namtar.utils.fs")

return function(app)
    app = app or Namtar.app()

    local base = "namtar/apps/starter"

    -- Run migrations
    local migrations_dir = base .. "/migrations"
    if fs.exists(migrations_dir) then
        local migrator = Migrations:new(app.db, migrations_dir)
        local ran = migrator:run()
        print(string.format("✅ Starter: ran %d migration(s)", ran))
    else
        print("⚠️  Starter: migrations dir not found: " .. migrations_dir)
    end

    -- Run seeds
    local seed_file = base .. "/seeds/initial.lua"
    if fs.exists(seed_file) then
        local seeder = require("namtar.apps.starter.seeds.initial")
        seeder(app)
    else
        print(" Starter: seeds file not found: " .. seed_file)
    end
end
