-- apps/starter/controllers/auth.lua
local Template = require("namtar.utils.template")
local Validator = require("namtar.utils.validator")
local crypto = require("namtar.utils.crypto")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(view, vars)
    vars = vars or {}
    vars.app = cfg
    return Template.layout(
        cfg.views_dir .. "/" .. view .. ".html",
        cfg.views_dir .. "/layout.html",
        vars
    )
end

local function hash_password(password, salt)
    return crypto.sha256(salt .. password .. salt)
end

function M.login_form(ctx)
    return ctx.res:html(render("auth/login", {error = nil, user = ctx.user}))
end

function M.login(ctx)
    print("Login")
    local data = ctx.req:is_json() and ctx.req:json() or ctx.req:form()
    print("Login"..data.username.." "..data.password)
    local User = ctx.app.manager:model("User")
    local user = User:query():where("username", "=", data.username or ""):first()

    if not user then
        if ctx.req:is_json() then
            return ctx.res:json({error = "Invalid credentials"}, 401)
        end
        return ctx.res:html(render("auth/login", {error = "Invalid credentials", user = nil}))
    end

    local hash = hash_password(data.password or "", user.salt or "")
    if hash ~= user.password_hash then
        if ctx.req:is_json() then
            return ctx.res:json({error = "Invalid credentials"}, 401)
        end
        return ctx.res:html(render("auth/login", {error = "Invalid credentials", user = nil}))
    end

    -- create session
    local Session = ctx.app.manager:model("Session")
    local token = crypto.random_hex(32)
    local expires = os.time() + cfg.session_ttl
    Session:insert({
        token = token,
        user_id = user.id,
        expires_at = tostring(expires),
        ip = ctx.req.ip or "",
        user_agent = ctx.req:header("user-agent") or "",
    })

    -- update last_login
    User:update(user.id, {last_login = os.date("%Y-%m-%d %H:%M:%S")})

    if ctx.req:is_json() then
        return ctx.res:json({status = "ok", token = token, user = {
            id = user.id, username = user.username, role = user.role,
        }})
    end

    ctx.res:set_cookie("session_token", token, {
        path = "/", max_age = cfg.session_ttl, httponly = true, samesite = "Lax",
    })
    return ctx.res:redirect(cfg.admin_path, 302)
end

function M.register_form(ctx)
    return ctx.res:html(render("auth/register", {error = nil, user = ctx.user}))
end

function M.register(ctx)
    local data = ctx.req:is_json() and ctx.req:json() or ctx.req:form()

    local ok, errors = Validator.validate(data, {
        username = "required|min:3|max:32|alphanum",
        email = "required|email",
        password = "required|min:6",
    })

    if not ok then
        if ctx.req:is_json() then
            return ctx.res:json({errors = errors}, 422)
        end
        return ctx.res:html(render("auth/register", {error = "Invalid input: " .. require("namtar.utils.json").encode(errors), user = nil}))
    end

    local User = ctx.app.manager:model("User")

    if User:query():where("username", "=", data.username):first() then
        return ctx.res:json({error = "Username taken"}, 409)
    end
    if User:query():where("email", "=", data.email):first() then
        return ctx.res:json({error = "Email taken"}, 409)
    end

    -- first user = admin
    local user_count = User:count()
    local role = user_count == 0 and "admin" or "user"

    local salt = crypto.random_hex(16)
    local hash = hash_password(data.password, salt)

    local id = User:insert({
        username = data.username,
        email = data.email,
        password_hash = hash,
        salt = salt,
        full_name = data.full_name or data.username,
        role = role,
        active = 1,
    })

    if not id then
        return ctx.res:json({error = "Failed to create user"}, 500)
    end

    if ctx.req:is_json() then
        return ctx.res:json({status = "ok", id = id}, 201)
    end
    return ctx.res:redirect("/starter/login", 302)
end

function M.logout(ctx)
    local token = ctx.req:cookie("session_token")
    if token then
        local Session = ctx.app.manager:model("Session")
        local s = Session:query():where("token", "=", token):first()
        if s then Session:delete(s.id) end
    end
    ctx.res:set_cookie("session_token", "", {path = "/", max_age = 0})
    return ctx.res:redirect("/starter/", 302)
end

return M
