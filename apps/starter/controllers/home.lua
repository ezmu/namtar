-- apps/starter/controllers/home.lua
local Template = require("namtar.utils.template")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = vars.user or nil
    return Template.layout(
        cfg.views_dir .. "/" .. view .. ".html",
        cfg.views_dir .. "/layout.html",
        vars
    )
end

function M.landing(ctx)
    local Article = ctx.app.manager:model("Article")
    local Page = ctx.app.manager:model("Page")

    local recent = Article:query()
        :where("status", "=", "published")
        :order_by("id", "DESC")
        :limit(6)
        :get() or {}

    local pages = Page:query()
        :where("status", "=", "published")
        :where("show_in_menu", "=", 1)
        :order_by("menu_order", "ASC")
        :get() or {}

    return ctx.res:html(render("landing", {
        recent = recent,
        pages = pages,
        user = ctx.user,
    }))
end

function M.page(ctx)
    local slug = ctx.params.slug
    local Page = ctx.app.manager:model("Page")
    local page = Page:query():where("slug", "=", slug):first()
    if not page then
        return ctx.res:html("<h1>Page not found</h1>", 404)
    end
    return ctx.res:html(render("page", {page = page, user = ctx.user}))
end

function M.article(ctx)
    local slug = ctx.params.slug
    local Article = ctx.app.manager:model("Article")
    local article = Article:query():where("slug", "=", slug):first()
    if not article or article.status ~= "published" then
        return ctx.res:html("<h1>Article not found</h1>", 404)
    end

    -- increment views
    Article:update(article.id, {views = (article.views or 0) + 1})

    local Author = ctx.app.manager:model("User")
    local author = article.author_id and Author:find(article.author_id) or nil

    return ctx.res:html(render("article", {
        article = article,
        author = author,
        user = ctx.user,
    }))
end

return M
