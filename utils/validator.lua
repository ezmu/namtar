-- namtar/utils/validator.lua

local Validator = {}

local RULES = {}

function RULES.required(v) return v ~= nil and v ~= "" end
function RULES.number(v) return type(v) == "number" or (type(v) == "string" and tonumber(v) ~= nil) end
function RULES.integer(v) local n = tonumber(v); return n ~= nil and math.floor(n) == n end
function RULES.string(v) return type(v) == "string" end
function RULES.boolean(v) return type(v) == "boolean" or v == 0 or v == 1 or v == "true" or v == "false" end
function RULES.email(v) return type(v) == "string" and v:match("^[%w%.%-_]+@[%w%.%-_]+%.%a+$") ~= nil end
function RULES.alpha(v) return type(v) == "string" and v:match("^%a+$") ~= nil end
function RULES.alphanum(v) return type(v) == "string" and v:match("^%w+$") ~= nil end

local function parse_rules(rule_string)
    local rules = {}
    for rule in rule_string:gmatch("[^|]+") do
        rule = rule:match("^%s*(.-)%s*$")
        local name, arg = rule:match("^(%w+):(.*)$")
        if name then
            table.insert(rules, {name = name, arg = arg})
        else
            table.insert(rules, {name = rule})
        end
    end
    return rules
end

local function check_rule(rule, value)
    local name = rule.name
    local arg = rule.arg

    if name == "min" then
        local n = tonumber(arg)
        if type(value) == "string" then return #value >= n end
        if type(value) == "number" then return value >= n end
        return true
    end

    if name == "max" then
        local n = tonumber(arg)
        if type(value) == "string" then return #value <= n end
        if type(value) == "number" then return value <= n end
        return true
    end

    if name == "in" then
        local allowed = {}
        for v in arg:gmatch("[^,]+") do
            allowed[v:match("^%s*(.-)%s*$")] = true
        end
        return allowed[tostring(value)] == true
    end

    if name == "between" then
        local lo, hi = arg:match("^(%d+),(%d+)$")
        if lo and hi then
            local n = tonumber(value)
            return n and n >= tonumber(lo) and n <= tonumber(hi)
        end
        return false
    end

    if name == "regex" then
        return type(value) == "string" and value:match(arg) ~= nil
    end

    local fn = RULES[name]
    if fn then return fn(value) end
    return true
end

function Validator.validate(data, schema)
    local errors = {}
    for field, rule_string in pairs(schema) do
        local rules = parse_rules(rule_string)
        local value = data[field]
        for _, rule in ipairs(rules) do
            if rule.name == "required" then
                if not RULES.required(value) then
                    errors[field] = errors[field] or {}
                    table.insert(errors[field], "required")
                end
            elseif value ~= nil and value ~= "" then
                if not check_rule(rule, value) then
                    errors[field] = errors[field] or {}
                    local msg = rule.arg and (rule.name .. ":" .. rule.arg) or rule.name
                    table.insert(errors[field], msg)
                end
            end
        end
    end
    return next(errors) == nil, errors
end

return Validator
