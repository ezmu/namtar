-- namtar/init.lua
-- Namtar Framework entry point

local Application = require("namtar.core.application")

local Namtar = {
    Application = Application,
    _app = nil,
}

function Namtar.setup(opts)
    Namtar._app = Application:new(opts)
    return Namtar._app
end

function Namtar.boot()
    if not Namtar._app then error("Call Namtar.setup() first") end
    Namtar._app:boot()
    return Namtar._app
end

function Namtar.app()
    return Namtar._app
end


function Namtar.handle(path, method, raw_request)
    if not Namtar._app then
        error("Namtar not initialized. Call Namtar.setup() and Namtar.boot() first.")
    end
    return Namtar._app:handle(path, method, raw_request)
end

return Namtar
