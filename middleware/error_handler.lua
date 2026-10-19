-- namtar/middleware/error_handler.lua

local ErrorHandler = {}

function ErrorHandler.make(opts)
    opts = opts or {}
    local debug = opts.debug or false

    return function(ctx, next)
        local ok, result = pcall(next)
        if not ok then
            local err = tostring(result)
            if ctx.logger then ctx.logger:error("Handler exception: %s", err) end
            ctx.app.events:emit("error.unhandled", err, ctx)
            if debug then
                return ctx.res:json({
                    error = "Internal Server Error",
                    message = err,
                }, 500)
            end
            return ctx.res:json({error = "Internal Server Error"}, 500)
        end
        return result
    end
end

return ErrorHandler
