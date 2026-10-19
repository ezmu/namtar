-- namtar/middleware/auth.lua

local crypto = require("namtar.utils.crypto")

local Auth = {}

local function b64url_encode(data)
    return crypto.base64_encode(data):gsub("+", "-"):gsub("/", "_"):gsub("=", "")
end

local function b64url_decode(data)
    data = data:gsub("-", "+"):gsub("_", "/")
    local pad = #data % 4
    if pad > 0 then data = data .. string.rep("=", 4 - pad) end
    return crypto.base64_decode(data)
end

function Auth.jwt_encode(payload, secret)
    local header = {alg = "HS256", typ = "JWT"}
    local h = b64url_encode(crypto.json_encode(header))
    local p = b64url_encode(crypto.json_encode(payload))
    local signing_input = h .. "." .. p
    local sig = crypto.hmac_sha256(signing_input, secret)
    local s = b64url_encode(sig)
    return signing_input .. "." .. s
end

function Auth.jwt_decode(token, secret)
    local h, p, s = token:match("^([^%.]+)%.([^%.]+)%.([^%.]+)$")
    if not h then return nil, "Invalid token format" end
    local signing_input = h .. "." .. p
    local expected_sig = b64url_encode(crypto.hmac_sha256(signing_input, secret))
    if expected_sig ~= s then return nil, "Invalid signature" end
    local ok, payload = pcall(function()
        return crypto.json_decode(b64url_decode(p))
    end)
    if not ok or not payload then return nil, "Invalid payload" end
    if payload.exp and payload.exp < os.time() then return nil, "Token expired" end
    return payload
end

function Auth.require(ctx, next)
    local token = ctx.req:bearer_token()
    if not token then
        return ctx.res:json({error = "Unauthorized", message = "Missing token"}, 401)
    end
    local secret = ctx.app.config:get("security.secret")
    local payload, err = Auth.jwt_decode(token, secret)
    if not payload then
        return ctx.res:json({error = "Unauthorized", message = err}, 401)
    end
    ctx.auth = {user = payload, authenticated = true}
    ctx.app.events:emit("auth.success", payload, ctx)
    return next()
end

function Auth.optional(ctx, next)
    local token = ctx.req:bearer_token()
    if token then
        local secret = ctx.app.config:get("security.secret")
        local payload = Auth.jwt_decode(token, secret)
        if payload then
            ctx.auth = {user = payload, authenticated = true}
        end
    end
    return next()
end

function Auth.api_key(ctx, next)
    local key = ctx.req:header("x-api-key")
    if not key then
        return ctx.res:json({error = "Unauthorized", message = "Missing API key"}, 401)
    end
    local valid_keys = ctx.app.config:get("security.api_keys", {})
    if not valid_keys[key] then
        return ctx.res:json({error = "Unauthorized", message = "Invalid API key"}, 401)
    end
    ctx.auth = {api_key = key, authenticated = true}
    return next()
end

function Auth.require_role(role)
    return function(ctx, next)
        if not ctx.auth or not ctx.auth.user then
            return ctx.res:json({error = "Unauthorized"}, 401)
        end
        local user_role = ctx.auth.user.role
        local allowed = false
        if type(role) == "string" then
            allowed = (user_role == role)
        elseif type(role) == "table" then
            for _, r in ipairs(role) do
                if user_role == r then allowed = true break end
            end
        end
        if not allowed then
            return ctx.res:json({error = "Forbidden"}, 403)
        end
        return next()
    end
end

return Auth
