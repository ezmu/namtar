-- apps/starter/controllers/api.lua
local Validator = require("namtar.utils.validator")
local String = require("namtar.utils.string")

local M = {}

-- GET /starter/api/articles
function M.articles(ctx)
    local Article = ctx.app.manager:model("Article")
    local articles = Article:query():where("status", "=", "published"):get() or {}
    return ctx.res:json({data = articles, count = #articles})
end

-- GET /starter/api/articles/:slug
function M.article(ctx)
    local Article = ctx.app.manager:model("Article")
    local a = Article:query():where("slug", "=", ctx.params.slug):first()
    if not a then return ctx.res:json({error = "Not found"}, 404) end
    return ctx.res:json({data = a})
end

-- POST /starter/api/articles
function M.create_article(ctx)
    if not ctx.user then
        return ctx.res:json({error = "Unauthorized"}, 401)
    end
    local data = ctx.req:json()
    local ok, errors = Validator.validate(data, {
        title = "required|min:3|max:200",
        body = "required|min:1",
    })
    if not ok then return ctx.res:json({errors = errors}, 422) end

    data.slug = data.slug or String.snake_case(data.title)
    data.author_id = ctx.user.id
    data.status = data.status or "draft"

    local Article = ctx.app.manager:model("Article")
    local id = Article:insert(data)
    if not id then return ctx.res:json({error = "Failed"}, 500) end

    ctx.app.events:emit("article.created", id, data)
    return ctx.res:json({status = "ok", id = id}, 201)
end

-- GET /starter/api/me
function M.me(ctx)
    if not ctx.user then return ctx.res:json({error = "Unauthorized"}, 401) end
    return ctx.res:json({
        id = ctx.user.id,
        username = ctx.user.username,
        email = ctx.user.email,
        role = ctx.user.role,
    })
end

-- GET /starter/api/health
function M.health(ctx)
    return ctx.res:json({status = "healthy", time = os.time()})
end

return M
