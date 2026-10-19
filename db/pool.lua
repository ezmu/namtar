-- namtar/db/pool.lua
-- Simple connection pool

local Pool = {}
Pool.__index = Pool
local Database = require("namtar.db")

function Pool:new(driver, config, size)
    return setmetatable({
        driver = driver,
        config = config,
        size = size or 5,
        available = {},
        in_use = {},
    }, Pool)
end

function Pool:acquire()
    if #self.available > 0 then
        local conn = table.remove(self.available)
        table.insert(self.in_use, conn)
        return conn
    end
    -- create new (or expand)
    local db = Database:new(self.driver, self.config)
    db:connect()
    table.insert(self.in_use, db)
    return db
end

function Pool:release(db)
    for i, conn in ipairs(self.in_use) do
        if conn == db then
            table.remove(self.in_use, i)
            if #self.available < self.size then
                table.insert(self.available, db)
            else
                db:close()
            end
            return
        end
    end
end

function Pool:close_all()
    for _, db in ipairs(self.available) do db:close() end
    for _, db in ipairs(self.in_use) do db:close() end
    self.available = {}
    self.in_use = {}
end

-- Wrapper: execute inside pool
function Pool:with(fn)
    local db = self:acquire()
    local ok, result = pcall(fn, db)
    self:release(db)
    if not ok then error(result) end
    return result
end

return Pool
