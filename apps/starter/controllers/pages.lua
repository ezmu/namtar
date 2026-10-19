-- apps/starter/controllers/pages.lua
local Template = require("namtar.utils.template")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = "pages"
    return Template.layout(
        cfg.views_dir .. "/dashboard/" .. view .. ".html",
        cfg.views_dir .. "/dashboard/layout.html",
        vars
    )
end

local function make_slug(title)
    local s = title:lower()
    s = s:gsub("%s+", "-")
    s = s:gsub("[^%w%-]", "")
    return s
end

function M.index(ctx)
    local Page = ctx.app.manager:model("Page")
    local pages = Page:query():order_by("id", "DESC"):get() or {}
    return ctx.res:html(render(ctx, "pages", {pages = pages}))
end

function M.new_form(ctx)
    return ctx.res:html(render(ctx, "page_form", {page = nil}))
end

function M.edit_form(ctx)
    local id = tonumber(ctx.params.id)
    local Page = ctx.app.manager:model("Page")
    local page = Page:find(id)
    if not page then return ctx.res:redirect(cfg.admin_path .. "/pages", 302) end
    return ctx.res:html(render(ctx, "page_form", {page = page}))
end

function M.save(ctx)
    local data = ctx.req:form()
    if not data.title or data.title == "" then
        return ctx.res:json({error = "Title required"}, 400)
    end
    data.slug = data.slug ~= "" and data.slug or make_slug(data.title)

    local Page = ctx.app.manager:model("Page")
    if data.id and data.id ~= "" then
        local id = tonumber(data.id)
        data.id = nil
        Page:update(id, data)
    else
        data.id = nil
        Page:insert(data)
    end
    return ctx.res:redirect(cfg.admin_path .. "/pages", 302)
end

function M.delete(ctx)
    local id = tonumber(ctx.params.id)
    if not id then return ctx.res:json({error = "Invalid"}, 400) end
    local Page = ctx.app.manager:model("Page")
    Page:delete(id)
    return ctx.res:redirect(cfg.admin_path .. "/pages", 302)
end

return M
