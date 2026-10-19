-- apps/starter/config.lua
return {
    name = "Namtar Starter",
    version = "1.0.0",
    description = "Blog + Admin + Docs — Starter App",
    base_path = "",
    admin_path = "/lua/starter/admin",
    views_dir = "namtar/apps/starter/views",
    public_dir = "namtar/apps/starter/public",
    posts_per_page = 10,
    session_ttl = 86400,  -- 24h
}
