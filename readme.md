
# 𒋻 Namtar

> **A full-stack Lua web framework that runs inside [Ereshkigal](https://kigal.co) — a native infrastructure runtime.**

Namtar gives you routing, ORM, migrations, sessions, templates, testing, CLI, and direct access to shared-memory cache, full-text search, graph DB, and DDoS protection — all in one process. No IPC. No network hops. No services to orchestrate.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lua 5.4](https://img.shields.io/badge/Lua-5.4-blue.svg)](https://www.lua.org/)
[![Status](https://img.shields.io/badge/status-stable-green.svg)]()
[![Version](https://img.shields.io/badge/version-1.0.0-purple.svg)]()
[![Made by Kigal](https://img.shields.io/badge/made%20by-Kigal-9d6dff.svg)](https://kigal.co)

---

## Table of Contents

- [Why Namtar](#why-namtar)
- [Features](#features)
- [Built on Ereshkigal](#built-on-ereshkigal)
- [Data Sovereignty](#data-sovereignty)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [A Complete Example](#a-complete-example)
- [The ereshkigal Bridge](#the-ereshkigal-bridge)
- [Documentation](#documentation)
- [CLI](#cli)
- [Testing](#testing)
- [Deployment](#deployment)
- [Performance](#performance)
- [Security](#security)
- [Ecosystem](#ecosystem)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## Why Namtar

Most web frameworks in Lua are either too minimal (no ORM, no sessions) or too slow (pure-Lua everything, no C acceleration). And virtually all of them run in their own process — separated from the cache, the database, and the security layer by network calls and serialization.

Namtar is different. It is designed from the ground up to run **inside** [Ereshkigal](https://kigal.co), Kigal's native infrastructure runtime. That design decision cascades into everything:

- **It runs in-process with the cache.** A `cache.get()` call reads shared memory directly. No HTTP, no Redis protocol, no serialization.
- **It shares memory with every other layer.** Full-text index, graph database, DDoS tracker, analytics — all reachable as function calls, not network hops.
- **It boots inside C, not next to it.** There is no Namtar server. Ereshkigal already has the sockets, the threads, and the memory. Namtar's `main.lua` runs in the same process.
- **It's explicit over magic.** No conventions-over-configuration black boxes. Every route, middleware, doctype, and model is registered by hand in a Lua file you can read.
- **Pure Lua where it makes sense.** JSON, SHA-256, HMAC, Base64, and templating are implemented in Lua — no external C bindings to break.
- **C where it matters.** Cache, full-text index, graph DB, DDoS tracker, quantum search — all live in shared memory. Namtar calls them through a single C bridge.

The name comes from Sumerian mythology: **Namtar** was the messenger of death, the one who carried fates between the land of the living and the underworld. **Ereshkigal** is that underworld. Namtar carries requests and responses across the boundary between the two.

---

## Features

### Framework

- **HTTP router** with compiled patterns, priorities, and per-route middleware
- **Middleware chain** with global, named, and grouped middleware
- **Request/Response objects** with JSON, form, headers, cookies, and query parsing
- **Controllers** as plain Lua tables — no forced inheritance
- **Events** (pub/sub with priorities and one-shot listeners)
- **Container** for dependency injection
- **Level-based logger** with file output and colors

### Data

- **ORM** — models, fluent query builder, schema sync, relations
- **Multi-database** — SQLite, MySQL, PostgreSQL (via `luasql`)
- **Migrations** — file-based, tracked, with rollback
- **Seeds** — idempotent data loaders
- **Doctypes** — declarative schema definitions with type mapping

### Auth & Security

- **JWT** (HS256) — sign, verify, role-based middleware
- **Session cookies** with `HttpOnly` + `SameSite`
- **CSRF** middleware (double-submit cookie)
- **CORS** middleware with preflight handling
- **Rate limiting** middleware (per-IP or per-user)
- **Input validation** with pipe-separated rules
- **SQL sanitization** on all identifiers and values

### Utility

- **Pure-Lua JSON** encoder/decoder with circular detection
- **Pure-Lua SHA-256, HMAC-SHA256, Base64**
- **Template engine** with `{{var}}`, `{{{raw}}}`, `{{#if}}`, `{{#each}}`
- **String/Table/FS utilities**
- **Validator** with 15+ built-in rules

### Cache

- **Memory cache** (LRU, per-process)
- **SHM cache bridge** — shares memory with Ereshkigal's C cache
- **`remember()`** helper for cache-aside pattern

### C Bridge

- Direct access to **shared-memory cache** (zero-copy reads)
- **Full-text search** with 8 languages, BM25 scoring, fuzzy suggestions
- **Graph database** with nodes, edges, and JSON properties
- **DDoS tracker** with blacklist/whitelist
- **Quantum approximate search** (mmap + hash masks)
- **Analytics** — events, top routes, slow routes, hourly stats
- **Profiler** — per-route CPU time and recommendations
- **Persistence** — snapshots and AOF replay
- **IP allowlist**, **logic rules**, **system reload**

### Developer Experience

- **CLI** for migrations, seeds, tests, and scaffolding
- **Testing framework** with assertions and in-process HTTP client
- **Hot reload** via inotify or SIGHUP
- **Starter app** — a full blog + admin dashboard + Ereshkigal control center

---

## Built on Ereshkigal

Namtar does not run on its own. It runs **inside** [Ereshkigal](https://kigal.co) — a **native infrastructure runtime** written in C.

### What Ereshkigal is

Ereshkigal is not a proxy. It is not a cache. It is not a gateway. It is the **execution layer that replaces them all** — a single 357 KB binary that collapses the traditional service stack into one process:

```
Traditional stack                Ereshkigal
─────────────────                ──────────
Load balancer                    Reverse proxy & routing
Reverse proxy                    Smart cache (SHM + disk)
API gateway                      Rules engine
Auth service                     Embedded Lua framework
Cache (Redis)              →     Security layer
Middleware host                  Direct DB access
Application server               JSON search & index
Database                         Database
```

**Six or more network hops become zero.**

Every layer that used to be a separate service — routing, caching, security, scripting, database access, JSON search — becomes a subsystem of the runtime. It runs on your own servers, with zero dependencies, zero containers, zero IPC.

**Core properties:**

- **357 KB binary** — no dependencies, no runtime, no container
- **0.25 ms average request time** on a 2012 Core i3
- **4,022 requests / second** on 4 cores
- **Zero-copy I/O**, io_uring, shared memory, SO_REUSEPORT, CPU affinity
- **Built-in rules engine** — declarative conditions, triggers, actions
- **Embedded Lua** — programmable infrastructure
- **Direct data access** — MySQL, PostgreSQL, SQLite, JSON indexing
- **Security layer** — DDoS protection, injection/XSS inspection, rate limiting

### Why this matters for Namtar

Traditional Lua frameworks run in their own process. Every call to a cache, a database, or a search engine crosses a network boundary — sockets, serialization, protocol overhead.

Namtar has none of that. Because it runs **inside** Ereshkigal, every layer shares the same memory, the same process, the same execution context:

- **`cache.get()` reads shared memory directly.** No HTTP, no Redis protocol.
- **`ft.search()` walks an inverted index in the same address space.**
- **`db:query()` uses an already-open connection.** No pool handshake.
- **`e.security.*` talks to the DDoS tracker that already inspected the request.**

No IPC. No serialization. No network stack. Every call is a C function invocation.

### Why C matters

Namtar is written in pure Lua. But it lives inside a C runtime:

- **Speed** — shared memory reads complete in nanoseconds. Zero-copy is the default.
- **No bootstrap** — Namtar does not start its own server, open its own sockets, or boot its own runtime. Ereshkigal is already running when Namtar's `main.lua` executes. There is no `Namtar.serve()`, no PID file, no port to bind. Namtar boots inside Ereshkigal's event loop and lives there.
- **One binary to deploy** — the Ereshkigal binary, your `namtar/` directory, one config file. That is the entire deployment.
- **One memory model** — cache entries, graph nodes, full-text postings, analytics events all live in shared-memory segments that both C and Lua can read.

---

## Data Sovereignty

Kigal's design is built on a single principle: **your data. Your servers. Your control.**

Namtar and Ereshkigal run entirely on your infrastructure. Sessions, cache, full-text indexes, graph data, analytics — all live in memory and shared-memory segments on your servers. Nothing leaves. No third-party CDN. No cloud intermediary. No SaaS dependency. No jurisdiction ambiguity.

**What this means in practice:**

- **No external authentication service.** Sessions live in your database. User accounts are rows in your tables. No Auth0, no Okta, no Firebase Auth.
- **No external cache.** The cache is shared memory in the runtime. No Redis Cloud, no Memcached, no Elasticache.
- **No external search service.** Full-text indexes are inverted structures in SHM. No Algolia, no Elasticsearch, no Meilisearch.
- **No external analytics.** Events are written to a memory-mapped file on your disk. No Segment, no Mixpanel, no Google Analytics.
- **No CDN intermediary.** Ereshkigal serves from your servers. There is no edge network in the middle.

**Why this matters:**

- **Compliance** — HIPAA, PCI-DSS, GDPR, SOC 2 — data never leaves your network, so compliance is enforceable by infrastructure, not policy.
- **Sovereignty** — your infrastructure, your jurisdiction, your laws.
- **Performance** — no extra hops, no third-party latency, no opaque edge caching.
- **Cost** — no bandwidth charges, no egress fees, no per-request pricing.

The framework has no telemetry, no phone-home, no license server. Once deployed, Namtar makes zero outbound connections to anyone except your own backend and database.

---

## Architecture

Namtar runs inside Ereshkigal's request handler. When a request matches a Lua route, Ereshkigal calls into the embedded Lua state — same process, same address space, same memory.

```
┌──────────────────────────────────────────────────────────┐
│  Client                                                  │
└─────────────────────────┬────────────────────────────────┘
                          │ HTTP
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Ereshkigal (C)                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  handler.c — reads request, evaluates rules.logic  │  │
│  │                                                    │  │
│  │  if action == "lua":                               │  │
│  │      luazen_handle_request(path, method, raw)      │  │
│  │                    │                               │  │
│  │                    ▼                               │  │
│  │      ┌──────────────────────────────┐              │  │
│  │      │  Namtar (Lua)                │              │  │
│  │      │  Application:handle()        │              │  │
│  │      │    → Router:dispatch()       │              │  │
│  │      │    → Middleware chain        │              │  │
│  │      │    → Handler                 │              │  │
│  │      │    → res:send()              │              │  │
│  │      └────────────┬─────────────────┘              │  │
│  │                   │ ereshkigal.*                   │  │
│  │                   ▼                                │  │
│  │      ┌──────────────────────────────┐              │  │
│  │      │  lua_ereshkigal.c            │              │  │
│  │      │  (C bridge — 17 submodules)  │              │  │
│  │      └────────────┬─────────────────┘              │  │
│  │                   │                                │  │
│  │      ┌────────────┴────────────┬─────────────┐     │  │
│  │      ▼            ▼            ▼             ▼     │  │
│  │   SHM Cache   Full-Text     Graph DB    DDoS       │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Two-way data flow:**

- **C → Lua:** raw HTTP request (string) + path + method
- **Lua → C:** raw HTTP response (string)
- **Lua → C (sideways):** direct function calls into shared memory via `ereshkigal.*`

**Concurrency:** Ereshkigal is thread-per-connection; the C side runs in parallel. All Lua requests serialize on a single `lua_mutex`. This is deliberate — Lua is fast enough for request handling, and shared state (DB connections, caches) becomes trivial to reason about.

---

## Quick Start

### Prerequisites

- **Ereshkigal** — the C runtime binary (contact via [kigal.co](https://kigal.co))
- **Lua 5.4** — `sudo apt install liblua5.4-dev lua5.4`
- **luasql** (optional, for database drivers)
  - SQLite: `sudo apt install lua-sql-sqlite3`
  - MySQL: `sudo apt install lua-sql-mysql`
  - PostgreSQL: `sudo apt install lua-sql-postgres`

### Installation

```bash
git clone https://github.com/your-org/namtar.git
cd namtar
```

Namtar is not a daemon. It's a library that runs inside Ereshkigal. You drop the `namtar/` folder next to your Ereshkigal binary.

### Minimal Setup

**1. Create `namtar/main.lua`:**

```lua
local Namtar = require("namtar")

Namtar.setup({
    name = "My App",
    version = "1.0.0",
    debug = true,
    apps_path = "./namtar/apps",
    auto_migrate = true,
    db = { driver = "sqlite", database = "database.db" },
    logging = { level = "info", console = true },
})

Namtar.boot()

function handle_request(path, method, request)
    return Namtar.handle(path, method, request)
end

return { handle_request = handle_request }
```

**2. Create `namtar/apps/myapp/config.lua`:**

```lua
return {
    name = "My App",
    version = "1.0.0",
    base_path = "",
    admin_path = "/lua/myapp/admin",
    views_dir = "namtar/apps/myapp/views",
    public_dir = "namtar/apps/myapp/public",
}
```

**3. Create `namtar/apps/myapp/doctypes/Post.lua`:**

```lua
return {
    name = "Post",
    fields = {
        {fieldname = "title", fieldtype = "Data", required = true},
        {fieldname = "slug", fieldtype = "Data", required = true, unique = true},
        {fieldname = "body", fieldtype = "Text"},
        {fieldname = "status", fieldtype = "Select",
         options = {"draft", "published"}, default = "draft"},
    },
}
```

**4. Create `namtar/apps/myapp/controllers/posts.lua`:**

```lua
local M = {}

function M.index(ctx)
    local Post = ctx.app.manager:model("Post")
    local posts = Post:query():where("status", "=", "published"):get()
    return ctx.res:json({posts = posts, count = #posts})
end

function M.create(ctx)
    local data = ctx.req:json()
    local Post = ctx.app.manager:model("Post")
    local id = Post:insert({
        title = data.title,
        slug = data.title:lower():gsub("%s+", "-"),
        body = data.body,
    })
    return ctx.res:json({id = id}, 201)
end

return M
```

**5. Create `namtar/apps/myapp/routes.lua`:**

```lua
local Posts = require("namtar.apps.myapp.controllers.posts")

return function(router, app)
    router:get("/lua/myapp/posts", Posts.index)
    router:post("/lua/myapp/posts", Posts.create)
end
```

**6. In `rules.logic`, route `/lua/*` to Lua:**

```
RULE:
  PATTERN: /lua/*
  ACTION: lua
  MESSAGE: Lua handler
```

**7. Run Ereshkigal:**

```bash
./Ereshkigal --config ereshkigal.conf --no-watchdog
```

**8. Test:**

```bash
curl http://127.0.0.1:8081/lua/myapp/posts
curl -X POST http://127.0.0.1:8081/lua/myapp/posts \
     -H "Content-Type: application/json" \
     -d '{"title":"Hello","body":"World"}'
```

Done. You're running Namtar.

---

## Directory Structure

```
namtar/
├── init.lua                       # Framework entry
├── main.lua                       # Your entry point (defines handle_request)
│
├── core/                          # Framework core
│   ├── application.lua            # Application:new/boot/handle
│   ├── config.lua                 # Dotted-key config
│   ├── container.lua              # DI container
│   ├── doctype_manager.lua        # Doctype → Model registry
│   ├── events.lua                 # Pub/sub
│   ├── loader.lua                 # App discovery + loading
│   └── logger.lua                 # Level-based logger
│
├── http/                          # HTTP layer
│   ├── router.lua                 # Routes + middleware per route
│   ├── request.lua                # Request object
│   ├── response.lua               # Response object
│   ├── controller.lua             # Optional base controller
│   ├── middleware.lua             # Chain + groups
│   └── status.lua                 # HTTP status map
│
├── orm/                           # ORM
│   ├── model.lua                  # Model:find/insert/update/delete
│   ├── query.lua                  # Fluent SQL builder
│   ├── schema.lua                 # DDL + sync
│   └── relations.lua              # has_many / belongs_to / etc.
│
├── db/                            # Database
│   ├── init.lua                   # Database facade
│   ├── pool.lua                   # Connection pool
│   ├── migrations.lua             # Migration runner
│   └── drivers/
│       ├── sqlite.lua
│       ├── mysql.lua
│       └── pgsql.lua
│
├── utils/                         # Utilities
│   ├── json.lua                   # Pure-Lua JSON
│   ├── crypto.lua                 # Pure-Lua SHA-256, HMAC, Base64
│   ├── string.lua
│   ├── table.lua
│   ├── fs.lua
│   ├── validator.lua
│   ├── sanitize.lua
│   └── template.lua               # {{var}}, {{#if}}, {{#each}}
│
├── middleware/                    # Built-in middleware
│   ├── auth.lua                   # JWT + API key
│   ├── cors.lua
│   ├── csrf.lua
│   ├── error_handler.lua
│   ├── logger.lua
│   └── rate_limit.lua
│
├── cache/                         # Cache
│   ├── init.lua                   # Facade
│   ├── memory.lua                 # LRU in-process
│   └── shm.lua                    # SHM bridge to C
│
├── cli/                           # Command-line interface
│   ├── init.lua
│   └── commands/
│       ├── serve.lua
│       ├── migrate.lua
│       ├── seed.lua
│       ├── test.lua
│       └── make.lua
│
├── testing/                       # Test framework
│   ├── init.lua                   # describe / it / run_dir
│   ├── assertions.lua
│   └── http_client.lua            # In-process HTTP client
│
└── apps/                          # Your applications
    └── starter/                   # Reference app
        ├── bootstrap.lua          # Runs migrations + seeds
        ├── config.lua
        ├── routes.lua
        ├── controllers/
        ├── doctypes/
        ├── middleware/
        ├── migrations/
        ├── seeds/
        ├── views/
        └── public/
```

---

## A Complete Example

Here's a full CRUD controller with validation, sessions, and templates. This is the starter app's `articles.lua`:

```lua
local Template = require("namtar.utils.template")
local Validator = require("namtar.utils.validator")
local cfg = require("namtar.apps.starter.config")

local M = {}

local function render(ctx, view, vars)
    vars = vars or {}
    vars.app = cfg
    vars.user = ctx.user
    vars.active = "articles"
    return Template.layout(
        cfg.views_dir .. "/dashboard/" .. view .. ".html",
        cfg.views_dir .. "/dashboard/layout.html",
        vars
    )
end

function M.index(ctx)
    local Article = ctx.app.manager:model("Article")
    local articles = Article:query():order_by("id", "DESC"):get() or {}
    return ctx.res:html(render(ctx, "articles", {articles = articles}))
end

function M.save(ctx)
    local data = ctx.req:form()

    -- Validate
    local ok, errors = Validator.validate(data, {
        title = "required|min:3|max:200",
    })
    if not ok then
        return ctx.res:json({errors = errors}, 422)
    end

    data.slug = data.slug ~= "" and data.slug or make_slug(data.title)
    data.author_id = ctx.user.id

    if data.status == "published" and (not data.published_at or data.published_at == "") then
        data.published_at = os.date("%Y-%m-%d %H:%M:%S")
    end

    local Article = ctx.app.manager:model("Article")

    if data.id and data.id ~= "" then
        local id = tonumber(data.id)
        data.id = nil
        Article:update(id, data)
    else
        data.id = nil
        Article:insert(data)
    end

    return ctx.res:redirect(cfg.admin_path .. "/articles", 302)
end

return M
```

And the corresponding route:

```lua
router:get(admin .. "/articles",  Articles.index, {middleware = {"starter_auth"}})
router:post(admin .. "/articles", Articles.save,  {middleware = {"starter_auth"}})
```

And the doctype:

```lua
return {
    name = "Article",
    fields = {
        {fieldname = "title", fieldtype = "Data", required = true},
        {fieldname = "slug", fieldtype = "Data", required = true, unique = true},
        {fieldname = "excerpt", fieldtype = "Text"},
        {fieldname = "body", fieldtype = "Text"},
        {fieldname = "status", fieldtype = "Select",
         options = {"draft", "published", "archived"}, default = "draft"},
        {fieldname = "author_id", fieldtype = "Link"},
        {fieldname = "views", fieldtype = "Int", default = 0},
        {fieldname = "published_at", fieldtype = "Datetime"},
    },
}
```

That's it. Table created, model generated, routes working, template rendering. No config files, no YAML, no annotations.

---

## The ereshkigal Bridge

Namtar calls into Ereshkigal's C internals through a single Lua module. Every function is a direct function call — no IPC, no HTTP, no serialization.

```lua
local e = require("ereshkigal")

-- Cache (shared with C)
e.cache.set("key", "value", 300)
local v = e.cache.get("key")

-- Full-text search
e.ft.create_index("products", "en", 128)
e.ft.add("products", 42, "Wireless headphones")
local results = e.ft.search("products", "headphones")

-- Graph DB
e.graph.add_node("user:1", '{"name":"Alice"}')
e.graph.add_edge("user:1", "user:2", "follows")

-- DDoS
e.security.blacklist("1.2.3.4", "abuse", 3600)
e.security.whitelist("10.0.0.5")

-- Quantum search
e.quantum.load("/data/products.json")
e.quantum.search("water", 1, 20)

-- Analytics
local stats = e.analytics.stats()
local top = e.analytics.top_routes(10, 7)

-- Profiler
e.profiler.time("user.load", function()
    return User:find(42)
end)

-- Persistence
e.persistence.save("backup_2026_01_15")
e.persistence.list()

-- System
local s = e.stats.all()
print("Requests:", s.total_requests, "Hit rate:", s.hit_rate, "%")
```

The 17 submodules are:

| Module | Purpose |
|--------|---------|
| `analytics` | Request and route statistics |
| `profiler` | CPU time and recommendations |
| `cache` | Shared-memory cache |
| `ft` | Full-text search |
| `ac` | Auto-complete |
| `security` | DDoS blacklist / whitelist |
| `graph` | Graph database |
| `persistence` | Snapshots and AOF |
| `quantum` | Approximate search |
| `json` | JSON path indexing |
| `logic` | C-side rule inspection |
| `stats` | Global counters |
| `routes` | C-side cache routes |
| `config` | C config inspection |
| `license` | License status |
| `pools` | Pool statistics |
| `system` | Reload config and routes |

See the [documentation](docs/namtar.html) for full API references.

---

## Documentation

A complete developer reference is available at [`docs/namtar.html`](docs/namtar.html) — a single self-contained HTML file (~280 KB) with 80+ sections covering every part of the framework.

It includes:

- Architecture and data flow
- Every config key
- Every route method and priority rule
- Every ORM method
- Every utility function
- Every middleware signature
- The full `ereshkigal` C bridge
- The CLI
- The starter app walkthrough
- 30 cookbook recipes
- Troubleshooting, FAQ, and glossary

Open it in any browser. No internet needed.

---

## CLI

```bash
# Migrations
namtar migrate
namtar migrate path/to/migrations

# Seeds
namtar db:seed
namtar db:seed path/to/seeds

# Tests
namtar test
namtar test path/to/tests

# Scaffolding
namtar make:doctype Article
namtar make:controller Articles
namtar make:route myapp

# Info
namtar serve
```

Every command boots the app first, so migrations, seeds, and tests run against the fully-initialized application.

---

## Testing

Namtar has a minimal testing framework. Tests use `describe` and `it`, with assertions exposed as globals.

```lua
-- tests/users.lua
local app = require("namtar").app()
local User = app.manager:model("User")

describe("Users", function()
    it("can be created", function()
        local id = User:insert({username = "test", email = "t@x.com"})
        assert_not_nil(id)
    end)

    it("rejects duplicate emails", function()
        assert_error(function()
            User:insert({username = "test2", email = "t@x.com"})
        end)
    end)
end)
```

Run with:

```bash
namtar test
```

Or with the in-process HTTP client:

```lua
local Client = require("namtar.testing.http_client")
local client = Client:new(app)

local res = client:get("/api/users")
assert_equal(res.status, 200)
assert_not_nil(res.json.users)
```

---

## Deployment

Namtar runs inside Ereshkigal, so "deployment" means shipping:

1. The compiled `Ereshkigal` binary
2. `ereshkigal.conf` — the C config
3. `rules.logic` — the C routing rules
4. The `namtar/` directory — your framework + apps
5. Database (SQLite file, or external MySQL/PostgreSQL)

### Production checklist

- [ ] Set `debug = false` in `main.lua`
- [ ] Change `security.secret` from `"change-me"` to a strong random value
- [ ] Enable TLS in `ereshkigal.conf`
- [ ] Set `admin_allowed_ips` to a tight list
- [ ] Disable hot reload (`config_watch = 0`, `lua_watch = 0`)
- [ ] Enable analytics if you want observability (`analytics_enabled = 1`)
- [ ] Configure DDoS protection (`ddos_enabled = 1`)
- [ ] Set up log rotation for the logger output file
- [ ] Configure snapshots (`persistence_enabled = 1`)

### systemd unit

```ini
[Unit]
Description=Ereshkigal (with Namtar)
After=network.target

[Service]
Type=simple
User=ereshkigal
WorkingDirectory=/opt/ereshkigal
ExecStart=/opt/ereshkigal/Ereshkigal --config ereshkigal.conf
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
```

---

## Performance

Namtar's own overhead is small. The C layer does the heavy lifting.

### Measured (starter app, on an i3 2012 laptop)

| Operation | Requests/sec | p50 | p99 |
|-----------|-------------|-----|-----|
| Cached static (`/api/test`) | 4,757 | 84 ms | 386 ms |
| Full-text search | 290 | ~0 ms | ~0 ms |

The C side peaks at **37,154 rps** on a 16-core AWS c7i.8xlarge.

### Costs inside Lua

| Operation | Approx cost |
|-----------|-------------|
| `json.decode` (small) | 10–50 µs |
| `json.encode` (small) | 20–60 µs |
| `crypto.sha256` (1 KB) | ~500 µs |
| `crypto.hmac_sha256` (1 KB) | ~1.2 ms |
| Small DB SELECT | ~200 µs |
| Template render (small) | ~100 µs |

Pure-Lua crypto is the most expensive. If you're hashing passwords, expect ~2 ms per attempt. Cache aggressively.

### The single lock

All Lua requests serialize on `lua_mutex`. Throughput is bounded by the sum of handler times. Keep handlers fast.

---

## Security

Namtar provides:

- **SQL injection protection** — all identifiers validated, all values bound or escaped
- **XSS protection** — templates auto-escape `{{var}}`
- **CSRF** — double-submit cookie middleware (opt-in)
- **Rate limiting** — per-IP or per-user middleware (opt-in)
- **DDoS** — C-side tracker with blacklist/whitelist (runs before Lua)
- **JWT** — HS256 sign/verify with expiry
- **Session cookies** — `HttpOnly` + `SameSite`
- **Input validation** — pipe-separated rule DSL

Namtar does **not** provide:

- Authorization beyond a simple `require_role` hook
- Constant-time comparisons
- RFC-compliant email validation
- Password hashing (starter uses salt+SHA-256 as a placeholder; use Argon2 in production)

**Always change `security.secret` before going live.** The default is `"change-me"` — intentional so dev boxes work out of the box.

See [`SECURITY.md`](SECURITY.md) for the full policy.

---

## Ecosystem

Namtar is part of the **Kigal stack** — a set of native infrastructure components designed to work as one runtime.

**[Kigal](https://kigal.co)** is the philosophy: *from an infrastructure stack to an infrastructure runtime*. One binary. Zero dependencies. A single execution layer. And your data never leaves your infrastructure.

The stack is named after Sumerian and Greek mythology:

| Layer | Name | Role |
|-------|------|------|
| **The Runtime** | **Ereshkigal** | Native infrastructure runtime — One binary, all layers |
| **The Framework** | **Namtar** | Lua application framework — routing, ORM, templates, business logic |
| **The Spider** | **Arachne** | Statistical / inferential graph engine |
| **The Tree** | **GishKigal** | Graph database + analytics studio |
| **The Road** | **Kaskal** | GIS layer on GishKigal |

Each layer runs standalone but composes cleanly with the others.

**Learn more at [kigal.co](https://kigal.co).**

---

## FAQ

**Q: What's the difference between Ereshkigal and Namtar?**
A: Ereshkigal is the native infrastructure runtime written in C. Namtar is the Lua application framework that runs inside it. Namtar cannot run without Ereshkigal; Ereshkigal can run without Namtar (using only `rules.logic` for routing).

**Q: Do I need to write C to use Namtar?**
A: No. Namtar is written in Lua. You write Lua. The C layer is already compiled.

**Q: Why not just use OpenResty?**
A: OpenResty is nginx + Lua. Namtar is a native runtime + Lua. The niche is different: Namtar is for apps that want an in-process cache and a full framework, not for apps that need nginx's ecosystem of modules. Namtar also ships with its own ORM, sessions, migrations, and testing — OpenResty expects you to bring all of that.

**Q: Is there a package manager?**
A: Luarocks works. Namtar itself has no luarocks dependencies except optionally `luasql` for the DB drivers.

**Q: Can I use Namtar as a standalone Lua web server?**
A: Not directly. Namtar relies on Ereshkigal's request handler to invoke `handle_request`. There's a testing HTTP client for in-process requests but no standalone server.

**Q: Does my data leave my servers?**
A: No. Sessions, cache, full-text indexes, graph data, and analytics all live on your servers. There is no telemetry, no phone-home, no license server. Once deployed, Namtar makes zero outbound connections except to your own backend and database.

**Q: How do I contribute?**
A: See [`CONTRIBUTING.md`](CONTRIBUTING.md).

**Q: What's the license?**
A: MIT. See [`LICENSE`](LICENSE).

---

## Contributing

Contributions are welcome. Before opening a PR:

1. Read [`CONTRIBUTING.md`](CONTRIBUTING.md).
2. Ensure tests pass: `namtar test`.
3. Add tests for new behavior.
4. Follow the existing code style — explicit, minimal, no magic.

For larger changes, open an issue first to discuss the approach.

### Development setup

```bash
git clone https://github.com/ezmu/namtar.git
cd namtar

# Install Lua 5.4 + luasql
sudo apt install liblua5.4-dev lua5.4 lua-sql-sqlite3 lua-sql-mysql lua-sql-postgres

# Run tests
namtar test
```

### Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold its terms.

---

## License

```
MIT License

Copyright (c) 2026 Kigal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  <strong>Namtar</strong> · 𒉆𒋻 · <em>Messenger between worlds</em>
  <br>
  <sub>Part of the <a href="https://kigal.co">Kigal</a> stack — native infrastructure runtime.</sub>
</p>

<p align="center">
  <a href="https://kigal.co">kigal.co</a> ·
  <a href="docs/namtar.html">Documentation</a> ·
  <a href="https://github.com/your-org/namtar/issues">Issues</a> ·
  <a href="https://github.com/your-org/namtar/discussions">Discussions</a>
</p>

---
