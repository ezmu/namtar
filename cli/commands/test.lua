-- namtar/cli/commands/test.lua

return {
    name = "test",
    description = "Run tests from tests/ directory",
    run = function(app, args)
        local path = args[1] or "tests"
        local Testing = require("namtar.testing")
        local results = Testing.run_dir(path)
        os.exit(results.failed == 0 and 0 or 1)
    end
}
