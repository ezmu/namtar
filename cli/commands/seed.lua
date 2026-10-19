-- namtar/cli/commands/seed.lua

return {
    name = "db:seed",
    description = "Run seeders from seeds/ directory",
    run = function(app, args)
        local path = args[1] or "seeds"
        local fs = require("namtar.utils.fs")
        local files = fs.scan(path, "%.lua$")
        for _, file in ipairs(files) do
            local module_path = file:gsub("%.lua$", ""):gsub("/", ".")
            local ok, seeder = pcall(require, module_path)
            if ok and type(seeder) == "function" then
                seeder(app)
                print("Seeded: " .. file)
            elseif ok and type(seeder) == "table" and type(seeder.run) == "function" then
                seeder.run(app)
                print("Seeded: " .. file)
            end
        end
    end
}
