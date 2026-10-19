-- apps/starter/controllers/articles.lua
local Template = require("namtar.utils.template")
local String = require("namtar.utils.string")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = "articles"
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
    local Article = ctx.app.manager:model("Article")
    local articles = Article:query():order_by("id", "DESC"):get() or {}
    return ctx.res:html(render(ctx, "articles", {articles = articles}))
end

function M.new_form(ctx)
    return ctx.res:html(render(ctx, "article_form", {article = nil}))
end

function M.edit_form(ctx)
    local id = tonumber(ctx.params.id)
    local Article = ctx.app.manager:model("Article")
    local article = Article:find(id)
    if not article then
        return ctx.res:redirect(cfg.admin_path .. "/articles", 302)
    end
    return ctx.res:html(render(ctx, "article_form", {article = article}))
end

function M.save(ctx)
    local data = ctx.req:form()
    if not data.title or data.title == "" then
        return ctx.res:json({error = "Title required"}, 400)
    end
    data.slug = data.slug ~= "" and data.slug or make_slug(data.title)
    data.author_id = ctx.user.id

    if data.status == "published" and (not data.published_at or data.published_at == "") then
        data.published_at = os.date("%Y-%m-%d %H:%M:%S")
    end

    local Article = ctx.app.manager:model("Article")

    if data.id and data.id ~= "" then
        local id = tonumber(data.id)
        data.id = nil
        Article:update(id, data)
    else
        data.id = nil
        Article:insert(data)
    end

    return ctx.res:redirect(cfg.admin_path .. "/articles", 302)
end

function M.delete(ctx)
    local id = tonumber(ctx.params.id)
    if not id then return ctx.res:json({error = "Invalid"}, 400) end
    local Article = ctx.app.manager:model("Article")
    Article:delete(id)
    return ctx.res:redirect(cfg.admin_path .. "/articles", 302)
end

return M
