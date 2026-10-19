-- apps/starter/controllers/dashboard.lua
local Template = require("namtar.utils.template")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = vars.active or ""
    vars.flash = vars.flash or nil
    return Template.layout(
        cfg.views_dir .. "/dashboard/" .. view .. ".html",
        cfg.views_dir .. "/dashboard/layout.html",
        vars
    )
end

function M.index(ctx)
    local Article = ctx.app.manager:model("Article")
    local User    = ctx.app.manager:model("User")
    local Page    = ctx.app.manager:model("Page")

    local stats = {
        articles = Article:count(),
        published = #Article:query():where("status", "=", "published"):get(),
        users = User:count(),
        pages = Page:count(),
    }

    local recent_articles = Article:query():order_by("id", "DESC"):limit(5):get() or {}

    return ctx.res:html(render(ctx, "index", {
        stats = stats,
        recent_articles = recent_articles,
        active = "dashboard",
    }))
end


-- ============================================================
-- Ereshkigal System Monitor - Full Dashboard
-- ============================================================

local json = require("namtar.utils.json")

-- Helper: read body as JSON
local function read_body(ctx)
    if not ctx.req or not ctx.req.body then return {} end
    if type(ctx.req.body) == "table" then return ctx.req.body end
    return json.decode(ctx.req.body) or {}
end

-- ══════════════════════════════════════════════════
-- MAIN PAGE
-- ══════════════════════════════════════════════════

function M.system(ctx)
    return ctx.res:html(render(ctx, "system", {
        title = "System Monitor",
        active = "system"
    }))
end

-- ══════════════════════════════════════════════════
-- API: OVERVIEW
-- ══════════════════════════════════════════════════

function M.system_api_overview(ctx)
    local e = require("ereshkigal")
    
    local stats = e.stats.all()
    local prof_state = e.profiler.state()
    local prof_recs = e.profiler.recommendations()
    local analytics = e.analytics.stats()
    local license = e.license.status()
    local security = e.security.stats()
    local top = e.analytics.top_routes(5, 7)
    
    return ctx.res:json({
        stats = stats,
        profiler = {
            state = prof_state,
            recommendations = prof_recs
        },
        analytics = analytics,
        license = license,
        security = security,
        top_routes = top
    })
end

-- ══════════════════════════════════════════════════
-- API: CACHE
-- ══════════════════════════════════════════════════

function M.system_api_cache(ctx)
    local e = require("ereshkigal")
    
    local report = e.cache.report()
    local status = e.cache.status()
    local expiration = e.cache.expiration()
    
    return ctx.res:json({
        report = report,
        status = status,
        expiration = expiration,
        count = e.cache.count()
    })
end

function M.system_api_cache_del(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    local key = body.key
    
    if not key or key == "" then
        return ctx.res:json({ ok = false, error = "missing key" })
    end
    
    local ok = e.cache.del(key)
    return ctx.res:json({ ok = ok, key = key })
end

function M.system_api_cache_cleanup(ctx)
    local e = require("ereshkigal")
    local cleaned = e.cache.cleanup()
    return ctx.res:json({ ok = true, cleaned = cleaned })
end

function M.system_api_cache_clear(ctx)
    local e = require("ereshkigal")
    e.cache.clear_all()
    return ctx.res:json({ ok = true })
end

-- ══════════════════════════════════════════════════
-- API: FULL-TEXT
-- ══════════════════════════════════════════════════

function M.system_api_ft(ctx)
    local e = require("ereshkigal")
    
    local indexes = e.ft.list_indexes()
    return ctx.res:json({ indexes = indexes })
end

function M.system_api_ft_create(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    local name = body.name
    if not name or name == "" then
        return ctx.res:json({ ok = false, error = "missing name" })
    end
    
    local ok = e.ft.create_index(name, body.lang or "en", body.size_mb or 64)
    return ctx.res:json({ ok = ok, name = name })
end

function M.system_api_ft_search(ctx)
    local e = require("ereshkigal")
    local query = ctx.req.query or {}
    local index = query.index
    local q = query.q
    
    if not index or not q then
        return ctx.res:json({ ok = false, error = "missing index or q" })
    end
    
    local results = e.ft.search(index, q)
    return ctx.res:json({ ok = true, results = results })
end

-- ══════════════════════════════════════════════════
-- API: GRAPH
-- ══════════════════════════════════════════════════

function M.system_api_graph(ctx)
    local e = require("ereshkigal")
    
    local stats = e.graph.stats()
    return ctx.res:json({ stats = stats })
end

function M.system_api_graph_node_add(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    if not body.id then
        return ctx.res:json({ ok = false, error = "missing id" })
    end
    
    local props = body.properties and json.encode(body.properties) or "{}"
    local ok = e.graph.add_node(body.id, props)
    return ctx.res:json({ ok = ok, id = body.id })
end

function M.system_api_graph_edge_add(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    if not body.from or not body.to or not body.relation then
        return ctx.res:json({ ok = false, error = "missing from/to/relation" })
    end
    
    local props = body.properties and json.encode(body.properties) or "{}"
    local ok = e.graph.add_edge(body.from, body.to, body.relation, props)
    return ctx.res:json({ ok = ok })
end

function M.system_api_graph_clear(ctx)
    local e = require("ereshkigal")
    e.graph.clear()
    return ctx.res:json({ ok = true })
end

-- ══════════════════════════════════════════════════
-- API: SECURITY
-- ══════════════════════════════════════════════════

function M.system_api_security(ctx)
    local e = require("ereshkigal")
    local stats = e.security.stats()
    return ctx.res:json({ stats = stats })
end

function M.system_api_security_blacklist(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    if not body.ip then
        return ctx.res:json({ ok = false, error = "missing ip" })
    end
    
    e.security.blacklist(body.ip, body.reason or "manual", body.duration or 3600)
    return ctx.res:json({ ok = true, ip = body.ip })
end

function M.system_api_security_whitelist(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    if not body.ip then
        return ctx.res:json({ ok = false, error = "missing ip" })
    end
    
    e.security.whitelist(body.ip)
    return ctx.res:json({ ok = true, ip = body.ip })
end

-- ══════════════════════════════════════════════════
-- API: PERSISTENCE
-- ══════════════════════════════════════════════════

function M.system_api_persistence(ctx)
    local e = require("ereshkigal")
    local list = e.persistence.list()
    return ctx.res:json({ snapshots = list })
end

function M.system_api_persistence_save(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    local name = body.name or ("snapshot_" .. os.time())
    local ok = e.persistence.save(name)
    return ctx.res:json({ ok = ok, name = name })
end

function M.system_api_persistence_load(ctx)
    local e = require("ereshkigal")
    local body = read_body(ctx)
    
    if not body.name then
        return ctx.res:json({ ok = false, error = "missing name" })
    end
    
    local ok = e.persistence.load(body.name)
    return ctx.res:json({ ok = ok, name = body.name })
end

-- ══════════════════════════════════════════════════
-- API: QUANTUM
-- ══════════════════════════════════════════════════

function M.system_api_quantum(ctx)
    local e = require("ereshkigal")
    local stats = e.quantum.stats()
    return ctx.res:json({ stats = stats })
end

function M.system_api_quantum_search(ctx)
    local e = require("ereshkigal")
    local query = ctx.req.query or {}
    
    if not query.q then
        return ctx.res:json({ ok = false, error = "missing q" })
    end
    
    local results = e.quantum.search(query.q, 1, 20)
    return ctx.res:json({ ok = true, results = results })
end

-- ══════════════════════════════════════════════════
-- API: CONFIG
-- ══════════════════════════════════════════════════

function M.system_api_config(ctx)
    local e = require("ereshkigal")
    local cfg = e.config.get()
    local license = e.license.status()
    return ctx.res:json({ config = cfg, license = license })
end
return M
