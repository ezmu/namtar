-- namtar/core/application.lua

local Config = require("namtar.core.config")
local Logger = require("namtar.core.logger")
local Events = require("namtar.core.events")
local Container = require("namtar.core.container")
local Loader = require("namtar.core.loader")
local DoctypeManager = require("namtar.core.doctype_manager")
local Database = require("namtar.db")

local Middleware = require("namtar.http.middleware")
local Router = require("namtar.http.router")
local Request = require("namtar.http.request")
local Response = require("namtar.http.response")

local Application = {}
Application.__index = Application

function Application:new(opts)
    local config = Config:new(opts or {})
    local obj = {
        config = config,
        logger = Logger:new({
            level = config:get("logging.level"),
            file = config:get("logging.file"),
            console = config:get("logging.console"),
        }),
        events = Events:new(),
        container = Container:new(),
        db = nil,
        manager = nil,
        middleware = Middleware:new(),
        router = nil,
        loader = nil,
        booted = false,
    }
    setmetatable(obj, Application)
    return obj
end

function Application:_init_db()
    local driver = self.config:get("db.driver")
    local db_config = self.config:get("db")
    self.db = Database:new(driver, db_config)
    self.db:connect()
    self.logger:info("Database connected: %s", driver)

    self.manager = DoctypeManager:new(self.db, {
        auto_migrate = self.config:get("auto_migrate"),
    })
end

function Application:_init_http()
    self.router = Router:new(self.middleware)
    self:_register_middlewares()
end

function Application:_register_middlewares()
    local mw = self.middleware

    mw:use(require("namtar.middleware.error_handler").make({
        debug = self.config:get("debug"),
    }), 100)

    mw:use(require("namtar.middleware.cors").make({
        origins = self.config:get("security.cors_origins", {"*"}),
    }), 90)

    mw:use(require("namtar.middleware.logger").make({
        skip = {"/health", "/favicon.ico"},
    }), 80)

    -- named
    local Auth = require("namtar.middleware.auth")
    mw:register("auth", Auth.require)
    mw:register("auth_optional", Auth.optional)
    mw:register("api_key", Auth.api_key)
    mw:register("role:admin", Auth.require_role("admin"))
    mw:register("role:user", Auth.require_role({"user", "admin"}))

    local RateLimit = require("namtar.middleware.rate_limit")
    mw:register("rate_limit", RateLimit.make({max = 100, window = 60}))
    mw:register("rate_limit:submit", RateLimit.make({
        max = 20, window = 60,
        key_fn = function(ctx)
            if ctx.auth and ctx.auth.user then
                return "user:" .. (ctx.auth.user.sub or ctx.req.ip)
            end
            return "ip:" .. ctx.req.ip
        end,
    }))

    if self.config:get("security.csrf") then
        mw:register("csrf", require("namtar.middleware.csrf").make())
    end

    mw:group("auth", {"auth"})
    mw:group("admin", {"auth", "role:admin"})
    mw:group("api", {"auth", "rate_limit"})
end

function Application:boot()
    if self.booted then return self end
    self.logger:info("Booting %s v%s", self.config:get("name"), self.config:get("version"))

    self:_init_db()
    self:_init_http()

    self.loader = Loader:new(self)
    self.loader:load_apps()

    self.booted = true
    self.logger:info("Boot complete")
    self.events:emit("app.booted", self)
    return self
end

-- نقطة الدخول الموحدة (تستخدمها handler.c)
function Application:handle(path, method, raw_request)
    -- استخراج IP من env أو argument (نمرر من C إن أمكن لاحقاً)
    local ip = os.getenv("REMOTE_ADDR") or ""

    local req = Request:new(raw_request or "", method, path, ip)
    local res = Response:new()

    local ctx = {
        app = self,
        req = req,
        res = res,
        logger = self.logger,
        db = self.db,
        manager = self.manager,
        params = {},
        auth = nil,
        csrf_token = nil,
    }

    -- dispatch
    self.router:dispatch(method, req.path, ctx)

    return res:send()
end

return Application
