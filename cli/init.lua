-- namtar/cli/init.lua
-- Namtar CLI

local Namtar = require("namtar")

local CLI = {}

local COMMANDS = {
    ["serve"]       = "namtar.cli.commands.serve",
    ["migrate"]     = "namtar.cli.commands.migrate",
    ["db:seed"]     = "namtar.cli.commands.seed",
    ["test"]        = "namtar.cli.commands.test",
}

local MAKE_PREFIX = "make:"

function CLI.run(argv)
    argv = argv or arg
    local cmd = argv[1]
    if not cmd then
        print("Namtar CLI")
        print("Commands: serve, migrate, db:seed, test")
        print("         make:doctype <Name>, make:controller <Name>, make:route <app>")
        return
    end


    local app = Namtar.setup({
        apps_path = "apps",
        auto_migrate = true,
    })
    app:boot()


    local args = {}
    for i = 2, #argv do table.insert(args, argv[i]) end

    -- make:*
    if cmd:sub(1, #MAKE_PREFIX) == MAKE_PREFIX then
        local make = require("namtar.cli.commands.make")
        make.run(app, {cmd, args[1]})
        return
    end


    local module_name = COMMANDS[cmd]
    if module_name then
        local command = require(module_name)
        command.run(app, args)
        return
    end

    print("Unknown command: " .. cmd)
end

return CLI
