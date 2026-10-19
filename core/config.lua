-- namtar/core/config.lua

local Config = {}
Config.__index = Config

local function merge(base, override)
    local result = {}
    for k, v in pairs(base) do
        if type(v) == "table" and type(override[k]) == "table" then
            result[k] = merge(v, override[k])
        else
            result[k] = override[k] ~= nil and override[k] or v
        end
    end
    for k, v in pairs(override) do
        if result[k] == nil then result[k] = v end
    end
    return result
end

local DEFAULTS = {
    name = "Namtar App",
    version = "1.0.0",
    debug = false,
    env = "production",
    timezone = "UTC",
    db = {
        driver = "sqlite",
        database = "database.db",
        pool_size = 5,
    },
    cache = {
        driver = "memory",
        ttl = 300,
        size = 1000,
    },
    http = {
        max_request_size = 1024 * 1024,
        timeout = 30,
    },
    security = {
        secret = "change-me",
        csrf = false,
        cors_origins = {"*"},
    },
    logging = {
        level = "info",
        file = nil,
        console = true,
    },
    apps_path = "apps",
    auto_migrate = false,
}

function Config:new(overrides)
    local obj = { data = merge(DEFAULTS, overrides or {}) }
    setmetatable(obj, Config)
    obj:_apply_env()
    return obj
end

function Config:_apply_env()
    for k in pairs(self.data) do
        local env_key = "NAMTAR_" .. k:upper()
        local val = os.getenv(env_key)
        if val then
            if val == "true" then val = true
            elseif val == "false" then val = false
            elseif tonumber(val) then val = tonumber(val)
            end
            self.data[k] = val
        end
    end
end

function Config:get(key, default)
    local parts = {}
    for part in key:gmatch("[^%.]+") do table.insert(parts, part) end
    local current = self.data
    for _, part in ipairs(parts) do
        if type(current) ~= "table" or current[part] == nil then
            return default
        end
        current = current[part]
    end
    return current
end

function Config:set(key, value)
    local parts = {}
    for part in key:gmatch("[^%.]+") do table.insert(parts, part) end
    local current = self.data
    for i = 1, #parts - 1 do
        if type(current[parts[i]]) ~= "table" then current[parts[i]] = {} end
        current = current[parts[i]]
    end
    current[parts[#parts]] = value
end

function Config:load_file(path)
    local f = io.open(path, "r")
    if not f then return false end
    local content = f:read("*all")
    f:close()
    local ok, data = pcall(function() return load("return " .. content)() end)
    if ok and type(data) == "table" then
        self.data = merge(self.data, data)
        return true
    end
    return false
end

return Config
