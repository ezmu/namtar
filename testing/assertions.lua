-- namtar/testing/assertions.lua

local A = {}

function A.assert_equal(a, b, msg)
    if a ~= b then
        error((msg or "assert_equal failed") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
    end
end

function A.assert_not_equal(a, b, msg)
    if a == b then
        error((msg or "assert_not_equal failed") .. ": both are " .. tostring(a))
    end
end

function A.assert_true(v, msg)
    if not v then error((msg or "assert_true failed") .. ": got " .. tostring(v)) end
end

function A.assert_false(v, msg)
    if v then error((msg or "assert_false failed") .. ": got " .. tostring(v)) end
end

function A.assert_nil(v, msg)
    if v ~= nil then error((msg or "assert_nil failed") .. ": got " .. tostring(v)) end
end

function A.assert_not_nil(v, msg)
    if v == nil then error((msg or "assert_not_nil failed")) end
end

function A.assert_type(v, t, msg)
    if type(v) ~= t then
        error((msg or "assert_type failed") .. ": expected " .. t .. ", got " .. type(v))
    end
end

function A.assert_contains(haystack, needle, msg)
    if type(haystack) == "string" then
        if not haystack:find(needle, 1, true) then
            error((msg or "assert_contains failed") .. ": not found")
        end
    elseif type(haystack) == "table" then
        local found = false
        for _, v in ipairs(haystack) do
            if v == needle then found = true break end
        end
        if not found then error((msg or "assert_contains failed")) end
    end
end

function A.assert_error(fn, msg)
    local ok = pcall(fn)
    if ok then error((msg or "assert_error failed") .. ": no error thrown") end
end

function A.assert_no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then error((msg or "assert_no_error failed") .. ": " .. tostring(err)) end
end

return A
