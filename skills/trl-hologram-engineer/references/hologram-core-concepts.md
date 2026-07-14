# Hologram Core Concepts

The isomorphic model, how transpilation works, and how to set up a project. Read this first.

## What Hologram is

Hologram is a **full-stack isomorphic Elixir web framework that runs on top of Phoenix**. You write the entire application — frontend and backend — in pure Elixir. Hologram builds a **call graph** of your code, determines which parts are reachable on the client (from action handlers and templates), and **transpiles that Elixir to JavaScript** at build time so it runs in the browser. No JavaScript framework is required.

It is inspired by **Elm, Phoenix LiveView, Surface, and Ruby on Rails**. The value proposition: one language for the whole stack, convention over configuration, and a snappy client-state UI without hand-writing JS.

## The execution model

1. **First load = SSR.** The page is server-side rendered to full HTML (SEO-friendly, works before JS loads).
2. **Then it hydrates.** Hologram mounts the page in the browser and manages a **virtual DOM** for efficient updates.
3. **State lives in the browser.** Component/page state is a client-side map. Reading it in templates uses `@key`; in handler code, `component.state.key`.
4. **Event handlers run where you choose:**
   - **`action/3` — client-side.** Runs locally in transpiled Elixir/JS. No server round-trip. Instant UI updates.
   - **`command/3` — server-side.** Async, privileged, middleware-gated. Used for persistence, DB, secrets, external APIs.
5. **Transports are automatic.** Action→command round-trips use **HTTP/2 request/response**; server-pushed updates (Realtime) use a **Server-Sent Events (SSE) stream**. There is no persistent WebSocket (unlike LiveView).

## How it compares

| | Hologram | LiveView | Surface | JS SPA |
|--|----------|----------|---------|--------|
| State location | Browser | Server | Server (LiveView) | Browser |
| Per-interaction round-trip | Only `command`s | Every event | Every event | Only explicit fetch |
| Language | Elixir → JS | Elixir + JS | Elixir + JS | JS/TS |
| Transport | HTTP/2 + SSE | WebSocket | WebSocket | fetch |
| First paint | SSR | SSR | SSR | CSR/SSR |

**When to prefer Hologram:** you want SPA-like snappiness (client state, no round-trip per click) but written in Elixir with SSR-first HTML. **When to prefer LiveView:** you want the simplest server-authoritative model, mature/stable tooling, and are fine with a round-trip per interaction. **When to prefer a JS SPA:** the team is JS-first or you need the JS ecosystem directly.

## Maturity & status

- **v0.10.0** (July 1, 2026), 25 releases, **pre-1.0** — expect breaking changes.
- **License Apache-2.0.** Repo `github.com/bartblast/hologram` (default branch `dev`). Hex package `hologram`.
- **Author Bart Blast**; sponsors include Curiosum and the Erlang Ecosystem Foundation.
- **Elixir stdlib transpilation ~88% complete.** Still-planned (roadmap): built-in auth, component-level re-rendering, first-party testing toolkit, i18n, hot reload, mobile.
- Treat as **maturing / early-adopter**, not battle-tested. Verify against the installed version.

## Requirements

Elixir **1.15+** · OTP **24+** · Node.js **20+** · an existing **Phoenix** app.

## Installation

```elixir
# mix.exs — add the dependency
defp deps do
  [
    {:hologram, "~> 0.10.0"}
    # ...
  ]
end

# mix.exs — add the Hologram compiler in project/0
def project do
  [
    # ...
    compilers: Mix.compilers() ++ [:hologram]
  ]
end
```

```elixir
# lib/my_app_web/endpoint.ex — mount Hologram's router BEFORE the Phoenix router
plug Hologram.Router
plug MyAppWeb.Router

# Serve Hologram's static assets from the "hologram" path
plug Plug.Static,
  at: "/",
  from: :my_app,
  only: ["hologram" | MyAppWeb.static_paths()]
```

```elixir
# .formatter.exs — register Hologram's formatter and include .holo files
[
  import_deps: [:phoenix, :hologram],
  inputs: ["{app,config,lib,test}/**/*.{ex,exs,holo}"]
]
```

Then:

```bash
mix deps.get
mix holo        # starts Phoenix with Hologram enabled
```

## Directory conventions

- Pages and components can live in a dedicated **`app/`** directory (separate from `lib/`). Add it to your `elixirc_paths/1` clauses so Mix compiles it.
- **Templates** are either:
  - **inline** via the `~HOLO"""..."""` sigil in `template/0`, or
  - a **colocated `.holo` file** with the same base name in the same directory as the module (e.g. `post_page.ex` + `post_page.holo`).

## The three building blocks

| Block | `use` | Stateful? | Key callbacks |
|-------|-------|-----------|---------------|
| **Page** | `use Hologram.Page` | Always (cid `"page"`) | `route`, `param`, `layout`, `init/3`, `template/0`, `action/3`, `command/3` |
| **Layout** | `use Hologram.Component` | Yes (cid `"layout"`) | `template/0` — must contain `<Hologram.UI.Runtime />` (in `<head>`) and `<slot />` |
| **Component** | `use Hologram.Component` | Stateless or stateful (needs `cid`) | `prop`, `init/2` (client) / `init/3` (server), `template/0`, `action/3`, `command/3` |

See [hologram-pages-and-layouts.md](hologram-pages-and-layouts.md) and [hologram-components-and-state.md](hologram-components-and-state.md).

## Doc map (official)

Guides: `/docs/introduction`, `/docs/installation`, `/docs/quick-start`. Docs: `/docs/architecture`, `/docs/template-syntax`, `/docs/components`, `/docs/pages`, `/docs/layouts`, `/docs/events`, `/docs/actions`, `/docs/commands`, `/docs/navigation`, `/docs/forms`, `/docs/context`, `/docs/middleware`, `/docs/session`, `/docs/cookies`, `/docs/realtime`, `/docs/javascript-interop`. Reference: `/reference/client-runtime`, `/reference/client-runtime/elixir`, `/reference/features`, `/docs/roadmap`.
