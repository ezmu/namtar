-- namtar/http/controller.lua
-- Controller base (lightweight)

local Controller = {}
Controller.__index = Controller

function Controller:new(app)
    return setmetatable({ app = app }, Controller)
end

function Controller:json(data, status)
 
    return {data = data, status = status or 200, type = "json"}
end

-- bind: يربط method بالـ handler signature (req, res)
function Controller:bind(method_name)
    local self_ref = self
    return function(req, res)
        return self_ref[method_name](self_ref, req, res)
    end
end

return Controller
