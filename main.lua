-- namtar/main.lua
local Namtar = require("namtar")

Namtar.setup({
    name = "Namtar Framework",
    version = "1.0.0",
    debug = true,
    apps_path = "./namtar/apps",
    auto_migrate = true,
    db = { driver = "sqlite", database = "database.db" },
    logging = { level = "info", console = true },
})

Namtar.boot()


local app = Namtar.app()
local fs = require("namtar.utils.fs")
local apps_dir = app.config:get("apps_path")
local apps = fs.directories(apps_dir)

for _, app_name in ipairs(apps) do
    local bootstrap_file = apps_dir .. "/" .. app_name .. "/bootstrap.lua"
    if fs.exists(bootstrap_file) then
        local module_path = "namtar.apps." .. app_name .. ".bootstrap"
        local ok, bootstrap = pcall(require, module_path)
        if ok and type(bootstrap) == "function" then
            local ok2, err = pcall(bootstrap, app)
            if ok2 then
                print(" Bootstrap: " .. app_name)
            else
                print(" Bootstrap failed for " .. app_name .. ": " .. tostring(err))
            end
        else
            print(" Failed to load bootstrap: " .. module_path)
        end
    end
end

function handle_request(path, method, request)
    return Namtar.handle(path, method, request)
end

function luazen_handle_request(path, method, request)
    return Namtar.handle(path, method, request)
end

return {
    handle_request = handle_request,
    luazen_handle_request = luazen_handle_request,
}
