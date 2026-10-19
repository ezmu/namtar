-- namtar/cache/shm.lua
-- Bridge to handler.c SHM cache (if available)

local SHM = {}
SHM.__index = SHM

function SHM:new(opts)
    opts = opts or {}
    return setmetatable({
        default_ttl = opts.ttl or 300,
        _available = (shm_get ~= nil and shm_set ~= nil),
    }, SHM)
end

function SHM:get(key)
    if not self._available then return nil end
    local len = 0
    local data = shm_get(key, len, nil)
    return data
end

function SHM:set(key, value, ttl)
    if not self._available then return false end
    return shm_set(key, value, #value, ttl or self.default_ttl, nil) == 0
end

function SHM:delete(key)
    if not self._available then return false end
    return shm_delete(key) == 0
end

function SHM:available()
    return self._available
end

return SHM
