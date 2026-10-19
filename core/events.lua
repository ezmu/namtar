-- namtar/core/events.lua

local Events = {}
Events.__index = Events

function Events:new()
    return setmetatable({ listeners = {} }, Events)
end

function Events:on(event, callback, priority)
    priority = priority or 0
    if not self.listeners[event] then self.listeners[event] = {} end
    table.insert(self.listeners[event], {callback = callback, priority = priority, once = false})
    table.sort(self.listeners[event], function(a, b) return a.priority > b.priority end)
    return self
end

function Events:once(event, callback, priority)
    priority = priority or 0
    if not self.listeners[event] then self.listeners[event] = {} end
    table.insert(self.listeners[event], {callback = callback, priority = priority, once = true})
    table.sort(self.listeners[event], function(a, b) return a.priority > b.priority end)
    return self
end

function Events:off(event, callback)
    if not self.listeners[event] then return self end
    if not callback then self.listeners[event] = nil return self end
    local new_list = {}
    for _, l in ipairs(self.listeners[event]) do
        if l.callback ~= callback then table.insert(new_list, l) end
    end
    self.listeners[event] = new_list
    return self
end

function Events:emit(event, ...)
    if not self.listeners[event] then return end
    local to_remove = {}
    for i, l in ipairs(self.listeners[event]) do
        local ok, err = pcall(l.callback, ...)
        if not ok then
            print("[Events] Error in listener for '" .. event .. "': " .. tostring(err))
        end
        if l.once then table.insert(to_remove, i) end
    end
    for i = #to_remove, 1, -1 do table.remove(self.listeners[event], to_remove[i]) end
    return self
end

function Events:has(event)
    return self.listeners[event] ~= nil and #self.listeners[event] > 0
end

function Events:clear()
    self.listeners = {}
    return self
end

return Events
