-- namtar/http/response.lua

local json = require("namtar.utils.json")
local STATUS = require("namtar.http.status")

local Response = {}
Response.__index = Response

function Response:new()
    return setmetatable({
        status = 200,
        headers = {},
        body = "",
        _sent = false,
    }, Response)
end

function Response:header(name, value)
    if not name then return self end
    -- normalize header name
    self.headers[name] = value
    return self
end

function Response:status_code(code)
    self.status = code
    return self
end

-- Alias for convenience
Response.status = function(self, code)
    if code then
        self.status = code
        return self
    end
    return self.status
end

function Response:json(data)
    self.headers["Content-Type"] = "application/json; charset=utf-8"
    self.body = json.encode(data)
    return self
end

function Response:html(content)
    self.headers["Content-Type"] = "text/html; charset=utf-8"
    self.body = content
    return self
end

function Response:text(content)
    self.headers["Content-Type"] = "text/plain; charset=utf-8"
    self.body = content
    return self
end

function Response:redirect(url, code)
    self.status = code or 302
    self.headers["Location"] = url
    self.body = ""
    return self
end

function Response:set_cookie(name, value, opts)
    opts = opts or {}
    local cookie = name .. "=" .. tostring(value)
    if opts.path then cookie = cookie .. "; Path=" .. opts.path end
    if opts.domain then cookie = cookie .. "; Domain=" .. opts.domain end
    if opts.max_age then cookie = cookie .. "; Max-Age=" .. opts.max_age end
    if opts.secure then cookie = cookie .. "; Secure" end
    if opts.httponly then cookie = cookie .. "; HttpOnly" end
    if opts.samesite then cookie = cookie .. "; SameSite=" .. opts.samesite end

    local existing = self.headers["Set-Cookie"]
    if existing then
        if type(existing) == "table" then
            table.insert(existing, cookie)
        else
            self.headers["Set-Cookie"] = {existing, cookie}
        end
    else
        self.headers["Set-Cookie"] = cookie
    end
    return self
end

function Response:send()
    if self._sent then return "" end
    self._sent = true

    local status_text = STATUS[self.status] or "OK"
    local lines = {"HTTP/1.1 " .. self.status .. " " .. status_text}

    for k, v in pairs(self.headers) do
        if type(v) == "table" then
            for _, item in ipairs(v) do
                table.insert(lines, k .. ": " .. item)
            end
        else
            table.insert(lines, k .. ": " .. v)
        end
    end

    table.insert(lines, "Content-Length: " .. #self.body)
    table.insert(lines, "Connection: close")
    table.insert(lines, "")
    table.insert(lines, self.body)

    return table.concat(lines, "\r\n")
end

return Response
