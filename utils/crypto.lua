-- namtar/utils/crypto.lua
-- Lua 5.1/5.4 compatible — no bitwise operators
local crypto = {}

local function band(a, b)
    if not a or not b then return 0 end
    local r, bit = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then r = r + bit end
        a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
    end
    return r
end
local function bor(a, b)
    a = a or 0; b = b or 0
    local r, bit = 0, 1
    while a > 0 or b > 0 do
        if a % 2 == 1 or b % 2 == 1 then r = r + bit end
        a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
    end
    return r
end
local function bxor(a, b)
    a = a or 0; b = b or 0
    local r, bit = 0, 1
    while a > 0 or b > 0 do
        if (a % 2) ~= (b % 2) then r = r + bit end
        a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
    end
    return r
end
local function lshift(a, n)
    a = a or 0; n = n or 0
    return (a * 2^n) % 0x100000000
end
local function rshift(a, n)
    a = a or 0; n = n or 0
    return math.floor((a % 0x100000000) / 2^n)
end
local function rrotate(a, n)
    a = a or 0; n = n or 0
    return bor(rshift(a, n), lshift(a, 32 - n)) % 0x100000000
end
local function rotr(x, n) return rrotate(x, n) end

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local function preprocess(msg)
    local len = #msg
    local bit_len = len * 8
    msg = msg .. "\128"
    while (#msg % 64) ~= 56 do msg = msg .. "\0" end
    msg = msg .. string.char(
        rshift(bit_len, 56) % 256, rshift(bit_len, 48) % 256,
        rshift(bit_len, 40) % 256, rshift(bit_len, 32) % 256,
        rshift(bit_len, 24) % 256, rshift(bit_len, 16) % 256,
        rshift(bit_len, 8) % 256, bit_len % 256
    )
    return msg
end
function crypto.sha256(message)
    local h = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    }
    local msg = preprocess(message)
    for chunk_start = 1, #msg, 64 do
        local w = {}
        for i = 0, 15 do
            local offset = chunk_start + i * 4 - 1
            local b1, b2, b3, b4 = msg:byte(offset, offset + 3)
            w[i] = bor(bor(lshift(b1, 24), lshift(b2 or 0, 16)), bor(lshift(b3 or 0, 8), b4 or 0))
        end
        for i = 16, 63 do
            local s0 = bxor(bxor(rotr(w[i-15], 7), rotr(w[i-15], 18)), rshift(w[i-15], 3))
            local s1 = bxor(bxor(rotr(w[i-2], 17), rotr(w[i-2], 19)), rshift(w[i-2], 10))
            w[i] = (w[i-16] + s0 + w[i-7] + s1) % 0x100000000
        end
        local a, b, c, d, e, f, g, hh = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
        for i = 0, 63 do
            local S1 = bxor(bxor(rotr(e, 6), rotr(e, 11)), rotr(e, 25))
            local ch = bxor(band(e, f), band(bxor(e, 0xffffffff), g))
            local temp1 = (hh + S1 + ch + K[i+1] + w[i]) % 0x100000000
            local S0 = bxor(bxor(rotr(a, 2), rotr(a, 13)), rotr(a, 22))
            local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
            local temp2 = (S0 + maj) % 0x100000000
            hh = g; g = f; f = e
            e = (d + temp1) % 0x100000000
            d = c; c = b; b = a
            a = (temp1 + temp2) % 0x100000000
        end
        h[1] = (h[1] + a) % 0x100000000
        h[2] = (h[2] + b) % 0x100000000
        h[3] = (h[3] + c) % 0x100000000
        h[4] = (h[4] + d) % 0x100000000
        h[5] = (h[5] + e) % 0x100000000
        h[6] = (h[6] + f) % 0x100000000
        h[7] = (h[7] + g) % 0x100000000
        h[8] = (h[8] + hh) % 0x100000000
    end
    local result = {}
    for i = 1, 8 do table.insert(result, string.format("%08x", h[i])) end
    return table.concat(result)
end
local function hex_to_bytes(hex)
    local bytes = {}
    for i = 1, #hex, 2 do
        table.insert(bytes, string.char(tonumber(hex:sub(i, i+1), 16)))
    end
    return table.concat(bytes)
end
function crypto.hmac_sha256(message, key)
    local block_size = 64
    if #key > block_size then
        key = hex_to_bytes(crypto.sha256(key))
    end
    key = key .. string.rep("\0", block_size - #key)
    local o_key_pad, i_key_pad = {}, {}
    for i = 1, block_size do
        local b = key:byte(i)
        o_key_pad[i] = string.char(bxor(b, 0x5c))
        i_key_pad[i] = string.char(bxor(b, 0x36))
    end
    local inner = crypto.sha256(table.concat(i_key_pad) .. message)
    local outer = crypto.sha256(table.concat(o_key_pad) .. hex_to_bytes(inner))
    return hex_to_bytes(outer)
end
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function crypto.base64_encode(data)
    local result = {}
    for i = 1, #data, 3 do
        local b1, b2, b3 = data:byte(i, i + 2)
        local n = bor(bor(lshift(b1, 16), lshift(b2 or 0, 8)), b3 or 0)
        table.insert(result, B64_CHARS:sub(rshift(n, 18) % 64 + 1, rshift(n, 18) % 64 + 1))
        table.insert(result, B64_CHARS:sub(rshift(n, 12) % 64 + 1, rshift(n, 12) % 64 + 1))
        if b2 then table.insert(result, B64_CHARS:sub(rshift(n, 6) % 64 + 1, rshift(n, 6) % 64 + 1))
        else table.insert(result, "=") end
        if b3 then table.insert(result, B64_CHARS:sub(n % 64 + 1, n % 64 + 1))
        else table.insert(result, "=") end
    end
    return table.concat(result)
end
function crypto.base64_decode(data)
    data = data:gsub("[^" .. B64_CHARS .. "=]", "")
    local result = {}
    local buffer = 0
    local bits = 0
    for i = 1, #data do
        local c = data:sub(i, i)
        if c == "=" then break end
        local idx = B64_CHARS:find(c, 1, true)
        if idx then
            buffer = bor(lshift(buffer, 6), idx - 1)
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                table.insert(result, string.char(rshift(buffer, bits) % 256))
            end
        end
    end
    return table.concat(result)
end
function crypto.random_hex(n)
    local bytes = {}
    for i = 1, n do bytes[i] = string.format("%02x", math.random(0, 255)) end
    return table.concat(bytes)
end
function crypto.random_bytes(n)
    local bytes = {}
    for i = 1, n do bytes[i] = string.char(math.random(0, 255)) end
    return table.concat(bytes)
end
function crypto.json_encode(t) return require("namtar.utils.json").encode(t) end
function crypto.json_decode(s) return require("namtar.utils.json").decode(s) end
return crypto
