-- namtar/middleware/cors.lua

local CORS = {}

function CORS.make(opts)
    opts = opts or {}
    local origins = opts.origins or {"*"}
    local methods = opts.methods or "GET, POST, PUT, DELETE, PATCH, OPTIONS"
    local headers = opts.headers or "Content-Type, Authorization, X-API-Key, X-Requested-With, X-CSRF-Token"
    local credentials = opts.credentials or false
    local max_age = opts.max_age or 86400

    return function(ctx, next)
        local origin = ctx.req:header("origin")
        local allowed_origin = nil
        for _, o in ipairs(origins) do
            if o == "*" then allowed_origin = "*" break
            elseif o == origin then allowed_origin = origin break end
        end
        if allowed_origin then
            ctx.res:header("Access-Control-Allow-Origin", allowed_origin)
            ctx.res:header("Access-Control-Allow-Methods", methods)
            ctx.res:header("Access-Control-Allow-Headers", headers)
            ctx.res:header("Access-Control-Max-Age", tostring(max_age))
            if credentials then
                ctx.res:header("Access-Control-Allow-Credentials", "true")
            end
        end
        if ctx.req.method == "OPTIONS" then
            ctx.res.status = 204
            ctx.res.body = ""
            return ctx.res
        end
        return next()
    end
end

return CORS
