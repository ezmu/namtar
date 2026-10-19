-- apps/starter/controllers/settings.lua
local Template = require("namtar.utils.template")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = "settings"
    return Template.layout(
        cfg.views_dir .. "/dashboard/" .. view .. ".html",
        cfg.views_dir .. "/dashboard/layout.html",
        vars
    )
end

function M.index(ctx)
    local Setting = ctx.app.manager:model("Setting")
    local rows = Setting:query():order_by("key", "ASC"):get() or {}
    local settings = {}
    for _, r in ipairs(rows) do settings[r.key] = r.value end
    return ctx.res:html(render(ctx, "settings", {settings = settings}))
end

function M.save(ctx)
    local data = ctx.req:form()
    local Setting = ctx.app.manager:model("Setting")

    for key, value in pairs(data) do
        local existing = Setting:query():where("key", "=", key):first()
        if existing then
            Setting:update(existing.id, {value = value})
        else
            Setting:insert({key = key, value = value, group = "general"})
        end
    end

    return ctx.res:redirect(cfg.admin_path .. "/settings", 302)
end

return M
