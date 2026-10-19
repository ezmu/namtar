-- namtar/cli/commands/serve.lua
-- Info: Namtar itself runs inside handler.c, so serve just prints info.

return {
    name = "serve",
    description = "Show how to run Namtar (inside handler.c)",
    run = function(app, args)
        print("ℹ️  Namtar runs inside handler.c (Ereshkigal runtime).")
        print("   To test in-process, use namtar.testing client.")
    end
}
