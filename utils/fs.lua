-- namtar/utils/fs.lua
-- File system helpers — pure Lua, no lfs dependency

local fs = {}

-- ============================================================
-- Basic file operations
-- ============================================================

function fs.exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

function fs.read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

function fs.write(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function fs.append(path, content)
    local f = io.open(path, "a")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function fs.is_dir(path)
    -- Try to open as directory by listing via find
    local handle = io.popen("test -d '" .. path .. "' && echo yes 2>/dev/null")
    if not handle then return false end
    local result = handle:read("*all")
    handle:close()
    return result:match("yes") ~= nil
end

-- ============================================================
-- Directory listing
-- ============================================================

function fs.scan(dir, pattern)
    local files = {}
    pattern = pattern or "%.lua$"

    local handle = io.popen("ls -1 '" .. dir .. "' 2>/dev/null")
    if not handle then return files end

    for entry in handle:lines() do
        -- entry is a filename (no path prefix)
        if entry ~= "" and not entry:match("^%.") and entry:match(pattern) then
            table.insert(files, dir .. "/" .. entry)
        end
    end
    handle:close()

    table.sort(files)
    return files
end

function fs.directories(dir)
    local dirs = {}

    -- Use find with -maxdepth 1 and explicit format — most reliable
    local handle = io.popen("find '" .. dir .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null")
    if not handle then return dirs end

    for entry in handle:lines() do
        entry = entry:gsub("^%s+", ""):gsub("%s+$", "")
        if entry ~= "" then
            -- entry is full path like "./namtar/apps/starter" — extract basename
            local name = entry:match("([^/]+)$")
            if name and name ~= "." and name ~= ".." then
                table.insert(dirs, name)
            end
        end
    end
    handle:close()

    table.sort(dirs)
    return dirs
end

function fs.mkdir(path)
    os.execute("mkdir -p '" .. path .. "'")
    return true
end

return fs
