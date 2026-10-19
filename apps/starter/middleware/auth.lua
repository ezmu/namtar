-- apps/starter/middleware/auth.lua
-- Loads current user from session cookie. Redirects if not logged in.

local M = {}

-- Paths (match config.lua)
local BASE_PATH  = ""                       -- base_path
local ADMIN_PATH = "/lua/starter/admin"     -- admin_path
local LOGIN_PATH = "/login"

local function load_user(ctx)
    local token = ctx.req:cookie("session_token")
    if not token then return nil end

    local Session = ctx.app.manager:model("Session")
    if not Session then return nil end

    local session = Session:query():where("token", "=", token):first()
    if not session then return nil end

    -- expired?
    local exp = tonumber(session.expires_at)
    if exp and exp < os.time() then
        Session:delete(session.id)
        return nil
    end

    local User = ctx.app.manager:model("User")
    local user = User:find(session.user_id)
    if not user or user.active == 0 then return nil end

    return user
end

function M.load(ctx, next)
    ctx.user = load_user(ctx)
    return next()
end

function M.require(ctx, next)
    if not ctx.user then
        if ctx.req.path:find("/api/") then
            return ctx.res:json({error = "Unauthorized"}, 401)
        end
        return ctx.res:redirect(LOGIN_PATH, 302)
    end
    return next()
end


function M.admin(ctx, next)
    if not ctx.user then
        if ctx.req.path:find("/api/") then
            return ctx.res:json({error = "Unauthorized"}, 401)
        end
        return ctx.res:redirect(LOGIN_PATH, 302)
    end
    if ctx.user.role ~= "admin" then
        if ctx.req.path:find("/api/") then
            return ctx.res:json({error = "Forbidden", message = "Admin only"}, 403)
        end
        return ctx.res:redirect(ADMIN_PATH, 302)
    end
    return next()
end

function M.guest(ctx, next)
    if ctx.user then
        return ctx.res:redirect(ADMIN_PATH, 302)
    end
    return next()
end

return M
