-- apps/starter/routes.lua
-- All routes for the Namtar Starter App.

local cfg = require("namtar.apps.starter.config")
local Home = require("namtar.apps.starter.controllers.home")
local Auth = require("namtar.apps.starter.controllers.auth")
local Dash = require("namtar.apps.starter.controllers.dashboard")
local Users = require("namtar.apps.starter.controllers.users")
local Articles = require("namtar.apps.starter.controllers.articles")
local Pages = require("namtar.apps.starter.controllers.pages")
local Settings = require("namtar.apps.starter.controllers.settings")
local API = require("namtar.apps.starter.controllers.api")
local MW = require("namtar.apps.starter.middleware.auth")

return function(router, app)
    local base = cfg.base_path
    local admin = cfg.admin_path

    -- ============================================================
    -- ✅ 1. Register middleware FIRST (before routes!)
    --    This is required because Router:_register() resolves
    --    middleware names at registration time. If middleware
    --    is not registered yet, routes will silently get no
    --    middleware — a serious security hole.
    -- ============================================================
    app.middleware:register("starter_auth", MW.require)
    app.middleware:register("starter_admin", MW.admin)
    app.middleware:register("starter_guest", MW.guest)
    app.middleware:use(MW.load, 5)

    -- ============================================================
    -- ✅ 2. Now define routes (middleware is ready)
    -- ============================================================

    -- ============================================================
    -- Static files (public/)
    -- ============================================================
    router:get(base .. "/public/css/:file", function(ctx)
        local fs = require("namtar.utils.fs")
        local content = fs.read(cfg.public_dir .. "/css/" .. ctx.params.file)
        if not content then return ctx.res:text("CSS not found", 404) end
        ctx.res:header("Content-Type", "text/css; charset=utf-8")
        ctx.res.body = content
        return ctx.res
    end)

    router:get(base .. "/public/js/:file", function(ctx)
        local fs = require("namtar.utils.fs")
        local content = fs.read(cfg.public_dir .. "/js/" .. ctx.params.file)
        if not content then return ctx.res:text("JS not found", 404) end
        ctx.res:header("Content-Type", "application/javascript; charset=utf-8")
        ctx.res.body = content
        return ctx.res
    end)

    router:get(base .. "/public/:dir/:file", function(ctx)
        local fs = require("namtar.utils.fs")
        local content = fs.read(cfg.public_dir .. "/" .. ctx.params.dir .. "/" .. ctx.params.file)
        if not content then return ctx.res:text("Not found", 404) end
        local ext = ctx.params.file:match("%.([^%.]+)$")
        local ct = "text/plain"
        if ext == "css" then ct = "text/css"
        elseif ext == "js" then ct = "application/javascript"
        elseif ext == "png" then ct = "image/png"
        elseif ext == "jpg" or ext == "jpeg" then ct = "image/jpeg"
        elseif ext == "svg" then ct = "image/svg+xml"
        elseif ext == "woff2" then ct = "font/woff2"
        end
        ctx.res:header("Content-Type", ct .. "; charset=utf-8")
        ctx.res.body = content
        return ctx.res
    end)

    -- ============================================================
    -- Public pages
    -- ============================================================
    router:get(base .. "/",          Home.landing, {middleware = {}})
    router:get(base .. "/p/:slug",   Home.page)
    router:get(base .. "/a/:slug",   Home.article)

    -- ============================================================
    -- Auth (guest only)
    -- ============================================================
    router:get(base .. "/login",     Auth.login_form,    {middleware = {"starter_guest"}})
    router:post(base .. "/login",    Auth.login)
    router:get(base .. "/register",  Auth.register_form, {middleware = {"starter_guest"}})
    router:post(base .. "/register", Auth.register)
    router:get(base .. "/logout",    Auth.logout)

    -- ============================================================
    -- Admin — Dashboard
    -- ============================================================
    router:get(admin,                        Dash.index,  {middleware = {"starter_auth"}})
    router:get(admin .. "/",                 Dash.index,  {middleware = {"starter_auth"}})

    -- ============================================================
    -- Admin — Users (admin only)
    -- ============================================================
    router:get(admin .. "/users",            Users.index,  {middleware = {"starter_admin"}})
    router:post(admin .. "/users",           Users.create, {middleware = {"starter_admin"}})
    router:get(admin .. "/users/:id/delete", Users.delete, {middleware = {"starter_admin"}})
    router:get(admin .. "/users/:id/toggle", Users.toggle, {middleware = {"starter_admin"}})

    -- ============================================================
    -- Admin — Articles
    -- ============================================================
    router:get(admin .. "/articles",                 Articles.index,     {middleware = {"starter_auth"}})
    router:get(admin .. "/articles/new",             Articles.new_form,  {middleware = {"starter_auth"}})
    router:get(admin .. "/articles/:id/edit",        Articles.edit_form, {middleware = {"starter_auth"}})
    router:post(admin .. "/articles",                Articles.save,      {middleware = {"starter_auth"}})
    router:get(admin .. "/articles/:id/delete",      Articles.delete,    {middleware = {"starter_auth"}})

    -- ============================================================
    -- Admin — Pages
    -- ============================================================
    router:get(admin .. "/pages",                 Pages.index,     {middleware = {"starter_auth"}})
    router:get(admin .. "/pages/new",             Pages.new_form,  {middleware = {"starter_auth"}})
    router:get(admin .. "/pages/:id/edit",        Pages.edit_form, {middleware = {"starter_auth"}})
    router:post(admin .. "/pages",                Pages.save,      {middleware = {"starter_auth"}})
    router:get(admin .. "/pages/:id/delete",      Pages.delete,    {middleware = {"starter_auth"}})

    -- ============================================================
    -- Admin — Settings
    -- ============================================================
    router:get(admin .. "/settings",         Settings.index, {middleware = {"starter_auth"}})
    router:post(admin .. "/settings",        Settings.save,  {middleware = {"starter_auth"}})

    -- ============================================================
    -- Admin — System Monitor (Ereshkigal Control Center)
    -- ============================================================
    router:get (admin .. "/system",                    Dash.system,                        {middleware = {"starter_auth"}})

    -- Overview
    router:get (admin .. "/system/api/overview",       Dash.system_api_overview,           {middleware = {"starter_auth"}})

    -- Cache
    router:get (admin .. "/system/api/cache",          Dash.system_api_cache,              {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/cache/del",      Dash.system_api_cache_del,          {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/cache/cleanup",  Dash.system_api_cache_cleanup,      {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/cache/clear",    Dash.system_api_cache_clear,        {middleware = {"starter_auth"}})

    -- Full-Text
    router:get (admin .. "/system/api/ft",             Dash.system_api_ft,                 {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/ft/create",      Dash.system_api_ft_create,          {middleware = {"starter_auth"}})
    router:get (admin .. "/system/api/ft/search",      Dash.system_api_ft_search,          {middleware = {"starter_auth"}})

    -- Graph
    router:get (admin .. "/system/api/graph",          Dash.system_api_graph,              {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/graph/node",     Dash.system_api_graph_node_add,     {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/graph/edge",     Dash.system_api_graph_edge_add,     {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/graph/clear",    Dash.system_api_graph_clear,        {middleware = {"starter_auth"}})

    -- Security
    router:get (admin .. "/system/api/security",       Dash.system_api_security,           {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/security/blacklist", Dash.system_api_security_blacklist, {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/security/whitelist", Dash.system_api_security_whitelist, {middleware = {"starter_auth"}})

    -- Persistence
    router:get (admin .. "/system/api/persistence",    Dash.system_api_persistence,        {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/persistence/save", Dash.system_api_persistence_save, {middleware = {"starter_auth"}})
    router:post(admin .. "/system/api/persistence/load", Dash.system_api_persistence_load, {middleware = {"starter_auth"}})

    -- Quantum
    router:get (admin .. "/system/api/quantum",        Dash.system_api_quantum,            {middleware = {"starter_auth"}})
    router:get (admin .. "/system/api/quantum/search", Dash.system_api_quantum_search,     {middleware = {"starter_auth"}})

    -- Config
    router:get (admin .. "/system/api/config",         Dash.system_api_config,             {middleware = {"starter_auth"}})

    -- ============================================================
    -- REST API
    -- ============================================================
    router:get(base .. "/api/health",         API.health)
    router:get(base .. "/api/articles",       API.articles)
    router:get(base .. "/api/articles/:slug", API.article)
    router:post(base .. "/api/articles",      API.create_article)
    router:get(base .. "/api/me",             API.me)

end
