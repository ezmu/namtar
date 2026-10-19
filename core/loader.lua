-- namtar/core/loader.lua
-- تم تعديله ليتوافق مع هيكلية: apps_path/apps/<app_name>/

local Loader = {}
Loader.__index = Loader
local fs = require("namtar.utils.fs")

function Loader:new(app)
    return setmetatable({ app = app }, Loader)
end

function Loader:_load_module(path)
    local module_path = path:gsub("%.lua$", ""):gsub("/", ".")
    local ok, result = pcall(require, module_path)
    if not ok then
        self.app.logger:error("Failed to load %s: %s", path, tostring(result))
        return nil
    end
    return result
end

function Loader:load_doctypes_from(dir)
    local files = fs.scan(dir, "%.lua$")
    local count = 0
    for _, file in ipairs(files) do
        local doctype = self:_load_module(file)
        if doctype and doctype.name and doctype.fields then
            self.app.manager:register(doctype.name, doctype.fields, doctype.opts)
            self.app.logger:info("Loaded doctype: %s", doctype.name)
            count = count + 1
        end
    end
    return count
end

function Loader:load_app(app_name, apps_dir)
    -- apps_dir = "namtar/apps"
    -- app_path = "namtar/apps/exam"
    local app_path = apps_dir .. "/" .. app_name

    -- doctypes
    self:load_doctypes_from(app_path .. "/doctypes")

    -- routes
    local routes_file = app_path .. "/routes.lua"
    local routes = self:_load_module(routes_file)
    if routes and type(routes) == "function" then
        routes(self.app.router, self.app)
        self.app.logger:info("[%s] Routes loaded", app_name)
    elseif routes and type(routes) == "table" and type(routes.register) == "function" then
        routes.register(self.app.router, self.app)
        self.app.logger:info("[%s] Routes loaded (table.register)", app_name)
    end

    self.app.events:emit("app.loaded", app_name)
end

function Loader:load_apps()
    -- apps_path = "namtar"  (المجلد الأب)
    -- apps_dir  = "namtar/apps"  (مجلد التطبيقات)
    local apps_path = self.app.config:get("apps_path")   -- "namtar"
    local apps_dir = apps_path 
    local apps = fs.directories(apps_dir)
    for _, app_name in ipairs(apps) do
        self:load_app(app_name, apps_dir)
    end
    return #apps
end

return Loader
