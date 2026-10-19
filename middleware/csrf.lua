-- namtar/middleware/csrf.lua

local crypto = require("namtar.utils.crypto")

local CSRF = {}

function CSRF.make(opts)
    opts = opts or {}
    local cookie_name = opts.cookie_name or "csrf_token"
    local header_name = opts.header_name or "x-csrf-token"
    local safe_methods = {GET = true, HEAD = true, OPTIONS = true}

    return function(ctx, next)
        local token = ctx.req:cookie(cookie_name)
        if not token then
            token = crypto.random_hex(32)
            ctx.res:set_cookie(cookie_name, token, {
                path = "/", samesite = "Strict", httponly = true,
            })
        end
        ctx.csrf_token = token

        if not safe_methods[ctx.req.method] then
            local submitted = ctx.req:header(header_name)
            if not submitted or submitted ~= token then
                return ctx.res:json({
                    error = "CSRF token mismatch",
                }, 403)
            end
        end
        return next()
    end
end

return CSRF
