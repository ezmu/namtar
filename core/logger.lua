-- namtar/core/logger.lua
-- Robust logger — instance + static methods

local Logger = {}
Logger.__index = Logger

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4, fatal = 5 }
local COLORS = {
    debug = "\27[36m", info = "\27[32m", warn = "\27[33m",
    error = "\27[31m", fatal = "\27[35m", reset = "\27[0m",
}

local function _format_line(self, level, msg, ...)
    local lvl_num = LEVELS[level] or 2
    local threshold = (type(self) == "table" and self.level) or 2
    if lvl_num < threshold then return nil end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, msg, ...)
        if ok then msg = formatted end
    end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local fmt = (type(self) == "table" and self.format) or "[%s] [%s] %s"
    local line = string.format(fmt, timestamp, level:upper(), tostring(msg))

    local console = (type(self) == "table" and self.console) ~= false
    if console then
        local color = COLORS[level] or ""
        print(color .. line .. COLORS.reset)
    end

    if type(self) == "table" and self._file_handle then
        self._file_handle:write(line .. "\n")
        self._file_handle:flush()
    end

    return line
end

function Logger:new(opts)
    opts = opts or {}
    local obj = {
        level = LEVELS[opts.level or "info"] or 2,
        file = opts.file,
        console = opts.console ~= false,
        format = opts.format or "[%s] [%s] %s",
        _file_handle = nil,
    }
    setmetatable(obj, Logger)
    if obj.file then obj._file_handle = io.open(obj.file, "a") end
    return obj
end

-- Instance methods
function Logger:debug(msg, ...) return _format_line(self, "debug", msg, ...) end
function Logger:info(msg, ...)  return _format_line(self, "info",  msg, ...) end
function Logger:warn(msg, ...)  return _format_line(self, "warn",  msg, ...) end
function Logger:error(msg, ...) return _format_line(self, "error", msg, ...) end
function Logger:fatal(msg, ...) return _format_line(self, "fatal", msg, ...) end

-- Static-safe wrappers (override instance method names on the table)
Logger.debug = function(self_or_msg, ...)
    if type(self_or_msg) == "table" and getmetatable(self_or_msg) == Logger then
        return _format_line(self_or_msg, "debug", ...)
    end
    return _format_line(nil, "debug", self_or_msg, ...)
end

Logger.info = function(self_or_msg, ...)
    if type(self_or_msg) == "table" and getmetatable(self_or_msg) == Logger then
        return _format_line(self_or_msg, "info", ...)
    end
    return _format_line(nil, "info", self_or_msg, ...)
end

Logger.warn = function(self_or_msg, ...)
    if type(self_or_msg) == "table" and getmetatable(self_or_msg) == Logger then
        return _format_line(self_or_msg, "warn", ...)
    end
    return _format_line(nil, "warn", self_or_msg, ...)
end

Logger.error = function(self_or_msg, ...)
    if type(self_or_msg) == "table" and getmetatable(self_or_msg) == Logger then
        return _format_line(self_or_msg, "error", ...)
    end
    return _format_line(nil, "error", self_or_msg, ...)
end

Logger.fatal = function(self_or_msg, ...)
    if type(self_or_msg) == "table" and getmetatable(self_or_msg) == Logger then
        return _format_line(self_or_msg, "fatal", ...)
    end
    return _format_line(nil, "fatal", self_or_msg, ...)
end

function Logger:close()
    if self._file_handle then
        self._file_handle:close()
        self._file_handle = nil
    end
end

return Logger
