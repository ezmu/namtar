-- namtar/core/container.lua

local Container = {}
Container.__index = Container

function Container:new()
    return setmetatable({ bindings = {}, instances = {} }, Container)
end

function Container:bind(name, factory)
    self.bindings[name] = factory
    return self
end

function Container:singleton(name, factory)
    self.bindings[name] = { factory = factory, singleton = true }
    return self
end

function Container:instance(name, obj)
    self.instances[name] = obj
    return self
end

function Container:get(name, ...)
    if self.instances[name] then return self.instances[name] end
    local binding = self.bindings[name]
    if not binding then error("Binding not found: " .. tostring(name)) end
    if type(binding) == "function" then
        local obj = binding(...)
        self.instances[name] = obj
        return obj
    end
    if binding.singleton then
        local obj = binding.factory(...)
        self.instances[name] = obj
        return obj
    end
    return binding.factory(...)
end

function Container:has(name)
    return self.instances[name] ~= nil or self.bindings[name] ~= nil
end

return Container
