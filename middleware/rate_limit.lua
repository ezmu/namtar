-- namtar/middleware/rate_limit.lua

local RateLimit = {}
local buckets = {}

function RateLimit.make(opts)
    opts = opts or {}
    local max = opts.max or 100
    local window = opts.window or 60
    local key_fn = opts.key_fn or function(ctx)
        return ctx.req.ip or "unknown"
    end
    local on_limit = opts.on_limit or function(ctx)
        ctx.res:header("Retry-After", tostring(window))
        ctx.res.status = 429
        return ctx.res:json({error = "Too Many Requests"}, 429)
    end

    return function(ctx, next)
        local key = key_fn(ctx)
        local now = os.time()
        local cutoff = now - window

        if not buckets[key] then buckets[key] = {timestamps = {}} end

        local fresh = {}
        for _, ts in ipairs(buckets[key].timestamps) do
            if ts > cutoff then table.insert(fresh, ts) end
        end
        buckets[key].timestamps = fresh

        if #buckets[key].timestamps >= max then
            local oldest = buckets[key].timestamps[1]
            local retry_after = window - (now - oldest)
            ctx.res:header("X-RateLimit-Limit", tostring(max))
            ctx.res:header("X-RateLimit-Remaining", "0")
            ctx.res:header("X-RateLimit-Reset", tostring(now + retry_after))
            ctx.res:header("Retry-After", tostring(retry_after))
            return on_limit(ctx)
        end

        table.insert(buckets[key].timestamps, now)
        ctx.res:header("X-RateLimit-Limit", tostring(max))
        ctx.res:header("X-RateLimit-Remaining", tostring(max - #buckets[key].timestamps))
        ctx.res:header("X-RateLimit-Reset", tostring(now + window))
        return next()
    end
end

function RateLimit.cleanup()
    local now = os.time()
    for key, bucket in pairs(buckets) do
        local fresh = {}
        for _, ts in ipairs(bucket.timestamps) do
            if ts > now - 3600 then table.insert(fresh, ts) end
        end
        if #fresh == 0 then buckets[key] = nil
        else bucket.timestamps = fresh end
    end
end

return RateLimit
