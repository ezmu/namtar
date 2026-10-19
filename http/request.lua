-- namtar/http/request.lua
-- Request object unifying all parsing

local json = require("namtar.utils.json")
local String = require("namtar.utils.string")

local Request = {}
Request.__index = Request

local function parse_headers(block)
    local headers = {}
    if not block then return headers end
    for line in block:gmatch("[^\r\n]+") do
        -- skip request line
        if not line:match("^%u+ /") and not line:match("^%u+ %S+ HTTP") then
            local key, value = line:match("^([^:]+):%s*(.*)$")
            if key then headers[key:lower()] = value end
        end
    end
    return headers
end

local function parse_query(q)
    local query = {}
    if not q or q == "" then return query end
    for pair in q:gmatch("([^&]+)") do
        local k, v = pair:match("^([^=]+)=?(.*)$")
        if k then
            query[String.url_decode(k)] = String.url_decode(v or "")
        end
    end
    return query
end

local function parse_cookies(cookie_header)
    local cookies = {}
    if not cookie_header then return cookies end
    for pair in cookie_header:gmatch("[^;]+") do
        pair = pair:match("^%s*(.-)%s*$")
        local k, v = pair:match("^([^=]+)=?(.*)$")
        if k then cookies[k] = v or "" end
    end
    return cookies
end

function Request:new(raw, method, path, ip)
    local obj = {
        raw = raw or "",
        method = (method or "GET"):upper(),
        path = path or "/",
        query = {},
        headers = {},
        body = "",
        params = {},
        cookies = {},
        files = {},
        ip = ip or "",
        _json_cache = nil,
        _form_cache = nil,
    }
    setmetatable(obj, Request)
    obj:_parse()
    return obj
end

function Request:_parse()
    if not self.raw or self.raw == "" then return end

    -- Body split
    local body_start = self.raw:find("\r\n\r\n")
    if body_start then
        self.body = self.raw:sub(body_start + 4)
    end

    -- Headers block
    local header_block = self.raw:match("^(.-)\r\n\r\n")
    if header_block then
        self.headers = parse_headers(header_block)
    end

    -- Path & query (فصل)
    local path_only = self.path
    local qmark = path_only:find("?")
    if qmark then
        local q = path_only:sub(qmark + 1)
        path_only = path_only:sub(1, qmark - 1)
        self.query = parse_query(q)
    end
    self.path = path_only

    -- Cookies
    self.cookies = parse_cookies(self.headers["cookie"])
end

function Request:json()
    if not self._json_cache then
        if self.body and self.body ~= "" then
            self._json_cache = json.decode(self.body) or {}
        else
            self._json_cache = {}
        end
    end
    return self._json_cache
end

function Request:form()
    if not self._form_cache then
        self._form_cache = {}
        if self.body and self.body ~= "" then
            for pair in self.body:gmatch("([^&]+)") do
                local k, v = pair:match("^([^=]+)=?(.*)$")
                if k then
                    self._form_cache[String.url_decode(k)] = String.url_decode(v or "")
                end
            end
        end
    end
    return self._form_cache
end

function Request:header(name)
    if not name then return nil end
    return self.headers[name:lower()]
end

function Request:query_param(name)
    return self.query[name]
end

function Request:cookie(name)
    return self.cookies[name]
end

function Request:bearer_token()
    local auth = self.headers["authorization"]
    if not auth then return nil end
    local token = auth:match("^[Bb]earer%s+(.+)$")
    return token
end

function Request:is_json()
    local ct = self.headers["content-type"] or ""
    return ct:find("application/json", 1, true) ~= nil
end

function Request:is_form()
    local ct = self.headers["content-type"] or ""
    return ct:find("application/x-www-form-urlencoded", 1, true) ~= nil
end

return Request
