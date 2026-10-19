-- apps/starter/migrations/001_initial.lua
-- Creates all starter tables (users, articles, pages, settings, sessions)

return {
    up = function(db)
        db:execute([[
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE NOT NULL,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                full_name TEXT,
                role TEXT DEFAULT 'user',
                active INTEGER DEFAULT 1,
                last_login DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db:execute([[
            CREATE TABLE IF NOT EXISTS articles (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                slug TEXT UNIQUE NOT NULL,
                excerpt TEXT,
                body TEXT,
                status TEXT DEFAULT 'draft',
                author_id INTEGER,
                views INTEGER DEFAULT 0,
                published_at DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db:execute([[
            CREATE TABLE IF NOT EXISTS pages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                slug TEXT UNIQUE NOT NULL,
                body TEXT,
                status TEXT DEFAULT 'published',
                show_in_menu INTEGER DEFAULT 0,
                menu_order INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db:execute([[
            CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                value TEXT,
                "group" TEXT DEFAULT 'general',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db:execute([[
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                token TEXT UNIQUE NOT NULL,
                user_id INTEGER NOT NULL,
                expires_at DATETIME NOT NULL,
                ip TEXT,
                user_agent TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        db:execute("CREATE INDEX IF NOT EXISTS idx_articles_status ON articles(status)")
        db:execute("CREATE INDEX IF NOT EXISTS idx_articles_slug ON articles(slug)")
        db:execute("CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token)")
    end,

    down = function(db)
        db:execute("DROP TABLE IF EXISTS sessions")
        db:execute("DROP TABLE IF EXISTS settings")
        db:execute("DROP TABLE IF EXISTS pages")
        db:execute("DROP TABLE IF EXISTS articles")
        db:execute("DROP TABLE IF EXISTS users")
    end,
}
