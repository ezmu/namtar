-- namtar/cache/memory.lua

local Memory = {}
Memory.__index = Memory

function Memory:new(opts)
    opts = opts or {}
    return setmetatable({
        data = {},
        order = {},  -- LRU
        max_size = opts.size or 1000,
        default_ttl = opts.ttl or 300,
    }, Memory)
end

function Memory:get(key)
    local entry = self.data[key]
    if not entry then return nil end
    if entry.expires and entry.expires < os.time() then
        self.data[key] = nil
        return nil
    end
    -- LRU update
    for i, k in ipairs(self.order) do
        if k == key then table.remove(self.order, i) break end
    end
    table.insert(self.order, key)
    return entry.value
end

function Memory:set(key, value, ttl)
    ttl = ttl or self.default_ttl
    if not self.data[key] and #self.order >= self.max_size then
        -- evict LRU
        local oldest = table.remove(self.order, 1)
        self.data[oldest] = nil
    end
    self.data[key] = {
        value = value,
        expires = ttl > 0 and (os.time() + ttl) or nil,
    }
    table.insert(self.order, key)
    return true
end

function Memory:delete(key)
    self.data[key] = nil
    for i, k in ipairs(self.order) do
        if k == key then table.remove(self.order, i) break end
    end
    return true
end

function Memory:clear()
    self.data = {}
    self.order = {}
end

function Memory:has(key)
    local v = self:get(key)
    return v ~= nil
end

function Memory:size()
    return #self.order
end

return Memory
