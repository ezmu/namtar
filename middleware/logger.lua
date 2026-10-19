-- namtar/middleware/logger.lua

local Logger = {}

function Logger.make(opts)
    opts = opts or {}
    local skip_paths = opts.skip or {}

    return function(ctx, next)
        for _, p in ipairs(skip_paths) do
            if ctx.req.path == p then return next() end
        end
        local start = os.clock()
        local result = next()
        local duration = (os.clock() - start) * 1000
        local status = ctx.res.status or 200
        local level = "info"
        if status >= 500 then level = "error"
        elseif status >= 400 then level = "warn" end
        if ctx.logger and ctx.logger[level] then
            ctx.logger[level]("%s %s → %d (%.2fms)",
                ctx.req.method, ctx.req.path, status, duration)
        end
        ctx.app.events:emit("request.completed", {
            method = ctx.req.method,
            path = ctx.req.path,
            status = status,
            duration = duration,
            ip = ctx.req.ip,
        })
        return result
    end
end

return Logger
