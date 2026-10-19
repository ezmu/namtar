-- namtar/http/router.lua
-- Router with compiled patterns + priority + middleware support

local Router = {}
Router.__index = Router

function Router:new(middleware_manager)
    return setmetatable({
        routes = {},
        middleware = middleware_manager,
    }, Router)
end

function Router:_register(method, path, handler, opts)
    opts = opts or {}

    local keys = {}
    -- Escape pattern chars first, then compile :param
    local pattern = path:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    pattern = pattern:gsub(":([%w_]+)", function(key)
        table.insert(keys, key)
        return "([^/]+)"
    end)
    pattern = "^" .. pattern .. "$"

    local priority = 3
    if path:find(":") then priority = 2 end
    if path:find("*") then priority = 1 end

    table.insert(self.routes, {
        method = method:upper(),
        path = path,
        pattern = pattern,
        keys = keys,
        handler = handler,
        priority = priority,
        middlewares = self.middleware and self.middleware:resolve(opts.middleware or opts.middlewares) or {},
    })

    table.sort(self.routes, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.path < b.path
    end)

    return self
end

function Router:get(path, handler, opts)    return self:_register("GET", path, handler, opts) end
function Router:post(path, handler, opts)   return self:_register("POST", path, handler, opts) end
function Router:put(path, handler, opts)    return self:_register("PUT", path, handler, opts) end
function Router:patch(path, handler, opts)  return self:_register("PATCH", path, handler, opts) end
function Router:delete(path, handler, opts) return self:_register("DELETE", path, handler, opts) end
function Router:any(path, handler, opts)    return self:_register("ANY", path, handler, opts) end

function Router:dispatch(method, path, ctx)
    method = method:upper()

    for _, route in ipairs(self.routes) do
        if route.method == method or route.method == "ANY" then
            local captures = {path:match(route.pattern)}
            if #captures > 0 or route.path == path then
                local params = {}
                for i, key in ipairs(route.keys) do
                    params[key] = captures[i]
                end
                ctx.params = params
                ctx.route = route

                local chain = self.middleware:build_chain(route.middlewares)
                return self.middleware:run(chain, ctx, route.handler)
            end
        end
    end

    return ctx.res:json({error = "Not Found", path = path}, 404)
end

return Router
