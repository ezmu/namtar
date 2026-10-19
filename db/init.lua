-- namtar/db/init.lua
-- Database abstraction with driver registry

local Database = {}
Database.__index = Database

local DRIVERS = {
    sqlite = "namtar.db.drivers.sqlite",
    mysql  = "namtar.db.drivers.mysql",
    pgsql  = "namtar.db.drivers.pgsql",
    postgres = "namtar.db.drivers.pgsql",
}

function Database:new(driver, config)
    local obj = {
        driver_name = driver,
        config = config or {},
        conn = nil,
    }
    setmetatable(obj, Database)
    return obj
end

function Database:connect()
    local module_name = DRIVERS[self.driver_name]
    if not module_name then
        error("Unknown database driver: " .. tostring(self.driver_name))
    end
    local module = require(module_name)
    self.conn = module.connect(self.config)
    return self.conn
end

function Database:_ensure()
    if not self.conn then self:connect() end
end

function Database:query(sql, params)
    self:_ensure()
    return self.conn:query(sql, params)
end

function Database:execute(sql, params)
    self:_ensure()
    return self.conn:execute(sql, params)
end

function Database:close()
    if self.conn then self.conn:close() self.conn = nil end
end

-- transaction
function Database:transaction(fn)
    self:_ensure()
    self.conn:execute("BEGIN")
    local ok, err = pcall(fn, self)
    if ok then
        self.conn:execute("COMMIT")
        return true
    else
        self.conn:execute("ROLLBACK")
        return false, err
    end
end

return Database
