-- apps/starter/controllers/users.lua
local Template = require("namtar.utils.template")
local crypto = require("namtar.utils.crypto")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = "users"
    return Template.layout(
        cfg.views_dir .. "/dashboard/" .. view .. ".html",
        cfg.views_dir .. "/dashboard/layout.html",
        vars
    )
end

function M.index(ctx)
    local User = ctx.app.manager:model("User")
    local users = User:query():order_by("id", "DESC"):get() or {}
    return ctx.res:html(render(ctx, "users", {users = users}))
end

function M.create(ctx)
    local data = ctx.req:form()
    local User = ctx.app.manager:model("User")

    local salt = crypto.random_hex(16)
    local hash = crypto.sha256(salt .. data.password .. salt)

    User:insert({
        username = data.username,
        email = data.email,
        password_hash = hash,
        salt = salt,
        full_name = data.full_name or data.username,
        role = data.role or "user",
        active = 1,
    })

    return ctx.res:redirect(cfg.admin_path .. "/users", 302)
end

function M.delete(ctx)
    local id = tonumber(ctx.params.id)
    if not id then
        return ctx.res:json({error = "Invalid id"}, 400)
    end
    if ctx.user and ctx.user.id == id then
        return ctx.res:json({error = "Cannot delete yourself"}, 400)
    end
    local User = ctx.app.manager:model("User")
    User:delete(id)
    return ctx.res:redirect(cfg.admin_path .. "/users", 302)
end

function M.toggle(ctx)
    local id = tonumber(ctx.params.id)
    local User = ctx.app.manager:model("User")
    local u = User:find(id)
    if not u then return ctx.res:json({error = "Not found"}, 404) end
    User:update(id, {active = u.active == 1 and 0 or 1})
    return ctx.res:redirect(cfg.admin_path .. "/users", 302)
end

return M
