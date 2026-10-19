-- namtar/http/middleware.lua
-- Middleware chain: global, named, groups

local Middleware = {}
Middleware.__index = Middleware

function Middleware:new()
    return setmetatable({
        global = {},
        groups = {},
        named = {},
    }, Middleware)
end

function Middleware:use(fn, priority)
    table.insert(self.global, {fn = fn, priority = priority or 0})
    table.sort(self.global, function(a, b) return a.priority > b.priority end)
    return self
end

function Middleware:register(name, fn)
    self.named[name] = fn
    return self
end

function Middleware:group(name, middlewares)
    self.groups[name] = middlewares
    return self
end

function Middleware:resolve(names)
    local result = {}
    for _, name in ipairs(names or {}) do
        if self.named[name] then
            table.insert(result, self.named[name])
        elseif self.groups[name] then
            for _, sub in ipairs(self.groups[name]) do
                if self.named[sub] then
                    table.insert(result, self.named[sub])
                end
            end
        end
    end
    return result
end

function Middleware:build_chain(route_middlewares)
    local chain = {}
    for _, mw in ipairs(self.global) do table.insert(chain, mw.fn) end
    for _, mw in ipairs(route_middlewares or {}) do table.insert(chain, mw) end
    return chain
end

function Middleware:run(chain, ctx, final_handler)
    local index = 0

    local function next_fn()
        index = index + 1
        local mw = chain[index]
        if not mw then
            return final_handler(ctx)
        end
        local ok, result = pcall(mw, ctx, next_fn)
        if not ok then
            if ctx.logger then
                ctx.logger:error("Middleware error: %s", tostring(result))
            end
            return ctx.res:json({error = "Internal Server Error"}, 500)
        end
        return result
    end

    return next_fn()
end

return Middleware
