-- namtar/cache/init.lua

local Cache = {}
Cache.__index = Cache

function Cache:new(driver, opts)
    local module_name
    if driver == "shm" then module_name = "namtar.cache.shm"
    else module_name = "namtar.cache.memory" end
    local module = require(module_name)
    return setmetatable({ backend = module:new(opts), driver = driver }, Cache)
end

function Cache:get(key) return self.backend:get(key) end
function Cache:set(key, value, ttl) return self.backend:set(key, value, ttl) end
function Cache:delete(key) return self.backend:delete(key) end
function Cache:has(key) return self.backend:has and self.backend:has(key) or self.backend:get(key) ~= nil end

function Cache:remember(key, ttl, fn)
    local v = self:get(key)
    if v ~= nil then return v end
    v = fn()
    if v ~= nil then self:set(key, v, ttl) end
    return v
end

return Cache
