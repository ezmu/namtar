-- namtar/testing/http_client.lua
-- In-process HTTP test client (calls app handle directly)

local json = require("namtar.utils.json")

local Client = {}
Client.__index = Client

function Client:new(app)
    return setmetatable({ app = app }, Client)
end

function Client:_request(method, path, body, headers)
    headers = headers or {}
    local raw_headers = {}
    for k, v in pairs(headers) do
        table.insert(raw_headers, k .. ": " .. v)
    end
    local body_str = ""
    if body then
        if type(body) == "table" then
            body_str = json.encode(body)
            table.insert(raw_headers, "Content-Type: application/json")
        else
            body_str = tostring(body)
        end
    end

    local raw = method .. " " .. path .. " HTTP/1.1\r\n" ..
                table.concat(raw_headers, "\r\n") .. "\r\n\r\n" .. body_str

    local response_str = self.app:handle(path, method, raw)

    -- parse response
    local status, _, _ = response_str:match("^HTTP/1%.1 (%d+) ([^\r\n]+)")
    local resp_body = response_str:match("\r\n\r\n(.*)$") or ""
    local status_num = tonumber(status)

    local parsed_body = nil
    local ok, decoded = pcall(json.decode, resp_body)
    if ok then parsed_body = decoded end

    return {
        status = status_num,
        body = resp_body,
        json = parsed_body,
        raw = response_str,
    }
end

function Client:get(path, headers) return self:_request("GET", path, nil, headers) end
function Client:post(path, body, headers) return self:_request("POST", path, body, headers) end
function Client:put(path, body, headers) return self:_request("PUT", path, body, headers) end
function Client:delete(path, headers) return self:_request("DELETE", path, nil, headers) end

return Client
