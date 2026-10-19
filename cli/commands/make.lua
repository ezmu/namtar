-- namtar/cli/commands/make.lua

local fs = require("namtar.utils.fs")

local TEMPLATES = {
    doctype = [[
return {
    name = "%s",
    fields = {
        {fieldname = "name", label = "Name", fieldtype = "Data", required = true},
    }
}
]],
    controller = [[
local M = {}

function M.index(req, res)
    return res:json({status = "ok"})
end

return M
]],
    route = [[
return function(router, app)
    -- define routes here
end
]],
}

return {
    name = "make",
    description = "make:doctype <Name> | make:controller <Name> | make:route <app>",
    run = function(app, args)
        local kind = args[1]
        local name = args[2]
        if not kind or not name then
            print("Usage: namtar make:<doctype|controller|route> <Name>")
            return
        end

        local kind_name = kind:match("^make:(%w+)$") or kind
        if not TEMPLATES[kind_name] then
            print("Unknown: " .. kind_name)
            return
        end

        local apps_path = app.config:get("apps_path")
        local path, content

        if kind_name == "doctype" then
            path = apps_path .. "/doctypes/" .. name:lower() .. ".lua"
            content = string.format(TEMPLATES.doctype, name)
        elseif kind_name == "controller" then
            path = apps_path .. "/controllers/" .. name:lower() .. "_controller.lua"
            content = TEMPLATES.controller
        elseif kind_name == "route" then
            path = apps_path .. "/" .. name .. "/routes.lua"
            content = TEMPLATES.route
        end

        if fs.exists(path) then
            print("File exists: " .. path)
            return
        end

        fs.write(path, content)
        print("Created: " .. path)
    end
}
