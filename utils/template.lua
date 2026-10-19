-- namtar/utils/template.lua
-- Supports: {{var}}, {{{var}}}, {{#if x}}...{{else}}...{{/if}}, {{#each x}}...{{/each}}

local fs = require("namtar.utils.fs")

local Template = {}
local MAX_DEPTH = 50

local function lookup(vars, key)
    if not key or key == "" then return nil end
    local current = vars
    for part in key:gmatch("[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function escape_html(s)
    s = tostring(s)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    return s
end

local function is_truthy(v)
    if v == nil or v == false then return false end
    if v == "" or v == 0 then return false end
    if type(v) == "table" and next(v) == nil then return false end
    return true
end

local function process_each(tpl, vars, depth)
    while true do
        local open_start = tpl:find("{{#each ", 1, true)
        if not open_start then break end
        local open_end = tpl:find("}}", open_start, true)
        if not open_end then break end
        local key = tpl:sub(open_start + 8, open_end - 1):match("^%s*(.-)%s*$")
        local block_start = open_end + 2

        local depth_count = 0
        local pos = block_start
        local close_pos = nil
        while pos <= #tpl do
            local next_open = tpl:find("{{#each ", pos, true)
            local next_close = tpl:find("{{/each}}", pos, true)
            if not next_close then break end
            if next_open and next_open < next_close then
                depth_count = depth_count + 1
                pos = next_open + 8
            else
                if depth_count == 0 then
                    close_pos = next_close
                    break
                end
                depth_count = depth_count - 1
                pos = next_close + 9
            end
        end
        if not close_pos then break end

        local body = tpl:sub(block_start, close_pos - 1)
        local list = lookup(vars, key)
        local out = {}
        if type(list) == "table" then
            for i, item in ipairs(list) do
                local item_vars = {}
                if type(item) == "table" then
                    for k, v in pairs(item) do item_vars[k] = v end
                else
                    item_vars.this = item
                end
                item_vars.index = i
                for k, v in pairs(vars) do
                    if item_vars[k] == nil then item_vars[k] = v end
                end
                table.insert(out, process(body, item_vars, depth + 1))
            end
        end
        local close_end = close_pos + #"{{/each}}"
        tpl = tpl:sub(1, open_start - 1) .. table.concat(out) .. tpl:sub(close_end)
    end
    return tpl
end

local function process_if(tpl, vars, depth)
    while true do
        local open_start = tpl:find("{{#if ", 1, true)
        if not open_start then break end
        local open_end = tpl:find("}}", open_start, true)
        if not open_end then break end
        local expr = tpl:sub(open_start + 6, open_end - 1):match("^%s*(.-)%s*$")

        local var_name, cmp_val
        local a, b = expr:match("^(.-)%s*==%s*(.+)$")
        if a then
            var_name = a:match("^%s*(.-)%s*$")
            cmp_val = b:match("^%s*(.-)%s*$")
        else
            var_name = expr
        end

        local block_start = open_end + 2
        local depth_count = 0
        local pos = block_start
        local else_pos = nil
        local close_pos = nil
        while pos <= #tpl do
            local next_open = tpl:find("{{#if ", pos, true)
            local next_else = tpl:find("{{else}}", pos, true)
            local next_close = tpl:find("{{/if}}", pos, true)
            if not next_close then break end
            local candidates = {}
            if next_open then table.insert(candidates, {next_open, "open"}) end
            if next_else then table.insert(candidates, {next_else, "else"}) end
            table.insert(candidates, {next_close, "close"})
            table.sort(candidates, function(a, b) return a[1] < b[1] end)
            local first = candidates[1]
            if first[2] == "open" then
                depth_count = depth_count + 1
                pos = next_open + 6
            elseif first[2] == "else" then
                if depth_count == 0 and not else_pos then else_pos = next_else end
                pos = next_else + 8
            else
                if depth_count == 0 then close_pos = next_close break end
                depth_count = depth_count - 1
                pos = next_close + 7
            end
        end
        if not close_pos then break end

        local true_body, false_body
        if else_pos then
            true_body = tpl:sub(block_start, else_pos - 1)
            false_body = tpl:sub(else_pos + 8, close_pos - 1)
        else
            true_body = tpl:sub(block_start, close_pos - 1)
            false_body = ""
        end

        local value = lookup(vars, var_name)
        local cond
        if cmp_val then
            local bare = cmp_val:match("^'(.*)'$") or cmp_val:match('^"(.*)"$') or cmp_val
            cond = (tostring(value) == tostring(bare))
        else
            cond = is_truthy(value)
        end

        local chosen = cond and true_body or false_body
        local close_end = close_pos + #"{{/if}}"
        tpl = tpl:sub(1, open_start - 1) .. process(chosen, vars, depth + 1) .. tpl:sub(close_end)
    end
    return tpl
end

function process(tpl, vars, depth)
    if depth > MAX_DEPTH then return tpl end
    tpl = process_each(tpl, vars, depth)
    tpl = process_if(tpl, vars, depth)
      -- {{{var}}} 
    tpl = tpl:gsub("{{{%s*([%w_%.]+)%s*}}}", function(key)
        local v = lookup(vars, key)
        if v == nil or type(v) == "table" then return "" end
        return tostring(v)         
    end)
    tpl = tpl:gsub("{{([%w_%.]+)}}", function(key)
        local v = lookup(vars, key)
        if v == nil or type(v) == "table" then return "" end
        return tostring(v)
    end)
    return tpl
end

function Template.render_string(tpl, vars)
    return process(tpl, vars or {}, 0)
end

function Template.render(view_path, vars)
    local content = fs.read(view_path)
    if not content then
        return "<h1>View not found: " .. tostring(view_path) .. "</h1>"
    end
    return Template.render_string(content, vars)
end

function Template.layout(view_path, layout_path, vars)
    vars = vars or {}
    local view = Template.render(view_path, vars)
    vars.content = view
    return Template.render(layout_path, vars)
end

return Template
