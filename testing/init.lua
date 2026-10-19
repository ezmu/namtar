-- namtar/testing/init.lua
-- Simple test runner

local Assertions = require("namtar.testing.assertions")
local fs = require("namtar.utils.fs")

local Testing = {}
Testing.__index = Testing

local current_suite = nil
local results = {passed = 0, failed = 0, errors = {}}

function Testing.describe(name, fn)
    current_suite = name
    print("\n📦 " .. name)
    fn()
    current_suite = nil
end

function Testing.it(name, fn)
    local ok, err = pcall(fn)
    if ok then
        results.passed = results.passed + 1
        print("  ✅ " .. name)
    else
        results.failed = results.failed + 1
        table.insert(results.errors, {suite = current_suite, test = name, error = err})
        print("  ❌ " .. name)
        print("     " .. tostring(err))
    end
end

function Testing.run_dir(path)
    results = {passed = 0, failed = 0, errors = {}}
    local files = fs.scan(path, "%.lua$")
    for _, file in ipairs(files) do
        local module_path = file:gsub("%.lua$", ""):gsub("/", ".")
        pcall(require, module_path)
    end
    print(string.format("\n📊 Results: %d passed, %d failed", results.passed, results.failed))
    return results
end

-- expose assertions globally for tests
for k, v in pairs(Assertions) do
    _G[k] = v
end

_G.describe = Testing.describe
_G.it = Testing.it

return Testing
