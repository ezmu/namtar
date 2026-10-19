-- apps/starter/seeds/initial.lua
local crypto = require("namtar.utils.crypto")
local Model = require("namtar.orm.model")

return function(app)
    local db = app.db

    local User = app.manager:model("User")
    if not User then
        User = Model.new("User", db):set_fields({
            {fieldname="email", fieldtype="Data"},
            {fieldname="username", fieldtype="Data"},
            {fieldname="password_hash", fieldtype="Data"},
            {fieldname="salt", fieldtype="Data"},
            {fieldname="full_name", fieldtype="Data"},
            {fieldname="role", fieldtype="Select"},
            {fieldname="active", fieldtype="Check"},
            {fieldname="last_login", fieldtype="Datetime"},
        })
    end

    if User:count() > 0 then
        print("ℹ️  Users already seeded")
        return
    end

    local salt = crypto.random_hex(16)
    local hash = crypto.sha256(salt .. "admin123" .. salt)

    User:insert({
        username = "admin",
        email = "admin@localhost",
        password_hash = hash,
        salt = salt,
        full_name = "Administrator",
        role = "admin",
        active = 1,
    })
    print("✅ Created admin user (username: admin, password: admin123)")

    local Article = app.manager:model("Article")
    if Article and Article:count() == 0 then
        Article:insert({
            title = "Welcome to Namtar Starter",
            slug = "welcome-to-namtar-starter",
            excerpt = "Your new site is ready.",
            body = "This is your first article. Edit or delete it from the dashboard.\n\nNamtar Framework makes it easy to build content-driven apps.",
            status = "published",
            author_id = 1,
            views = 0,
            published_at = os.date("%Y-%m-%d %H:%M:%S"),
        })
        print("✅ Created sample article")
    end

    local Setting = app.manager:model("Setting")
    if Setting and Setting:count() == 0 then
        Setting:insert({key = "site_name", value = "Namtar Starter", group = "general"})
        Setting:insert({key = "site_description", value = "Built on Namtar Framework", group = "general"})
        Setting:insert({key = "contact_email", value = "admin@localhost", group = "general"})
        Setting:insert({key = "posts_per_page", value = "10", group = "general"})
        print("✅ Created default settings")
    end
end
