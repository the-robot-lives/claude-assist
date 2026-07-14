---
name: trl-hologram-engineer
description: >
  Expert engineering and UX design for Hologram — the full-stack isomorphic Elixir
  web framework that compiles client-side Elixir to JavaScript on top of Phoenix.
  Use this skill when the user wants to build a Hologram page or component, write
  templates with the ~HOLO sigil or .holo files, wire client-side actions and
  server-side commands, manage client state, handle events (click, submit, key,
  scroll, pointer), build forms with isomorphic validation, set up routing and
  navigation, use context/session/cookies/middleware, add realtime server push,
  do JavaScript interop, debug transpilation gaps, or design accessible, snappy
  UIs in Hologram — even if they don't say "Hologram." Also trigger when users
  mention isomorphic Elixir, Elixir-to-JS, Hologram.Page, Hologram.Component,
  ~HOLO, .holo template, put_state, put_command, put_action, action/3, command/3,
  prop/2, cid, Hologram.UI.Runtime, Hologram.UI.Link, $click, $submit, $key_down,
  Hologram router, client-side Elixir, or "LiveView without the server round-trip."
---

# Hologram Engineer

Build rich, interactive web UIs entirely in Elixir with Hologram — the isomorphic framework that keeps state in the browser and transpiles your client code to JavaScript. This skill covers engineering (pages, components, actions/commands, transpilation) and UX (interaction patterns, forms, accessibility, snappy navigation).

## Overview

This skill turns UI requirements into production Hologram code and well-designed user experiences. It provides:

- **Complete Hologram model** — Pages, layouts, stateful/stateless components, the `~HOLO` template language, and the client/server split
- **The action/command boundary** — client-side `action/3` (no round-trip) vs server-side `command/3` (privileged, middleware-gated), and how state flows between them
- **Template & event mastery** — `~HOLO` interpolation, `{%if}`/`{%for}` blocks, the full `$event` binding set, modifiers (`.debounce`, `.throttle`, key filters), and event data shapes
- **Transpilation awareness** — what Elixir transpiles to JS (~88% stdlib), what does not (processes, regex), and how to stay inside the supported subset
- **Realtime, forms, and state** — SSE server push, isomorphic validation (incl. Ecto changesets), context, session, and cookies
- **UX and accessibility** — infinite scroll, command palettes, optimistic UI, prefetch-on-interaction navigation, focus management, and ARIA for a framework that emits plain semantic HTML

> Hologram is **pre-1.0** (v0.10.0, July 2026) and evolving fast. Verify APIs against the installed version and `/reference/client-runtime/elixir` before assuming a stdlib function transpiles. Cite docs at https://hologram.page/docs.

## Core Philosophy

**Six Principles:**

1. **State lives in the browser** — Unlike LiveView, Hologram keeps component state client-side and runs event handlers locally. Default to `action` (instant, no round-trip); reach for `command` only when you need the server.
2. **The action/command line is the trust boundary** — Actions cross no trust boundary and have no middleware. All authorization, DB access, and privileged work belongs in `command/3`, gated by middleware. Never trust action-side logic.
3. **Stay inside the transpilable subset** — Client-reachable code must be code Hologram can compile to JS. No processes/GenServers, no regex on the client. Check coverage before relying on a stdlib function.
4. **SSR first, then hydrate** — First load is server-rendered HTML (SEO-friendly, works before JS). Design so the page is meaningful before it becomes interactive.
5. **The template is plain HTML** — Hologram adds a small `~HOLO` layer over real HTML. Bring standard CSS, semantic elements, and accessibility practices; the framework won't do a11y for you.
6. **One language, whole stack** — Frontend and backend are both Elixir. Model data once, validate once (isomorphically), and let convention over configuration remove boilerplate.

## When to Use This Skill

- **Building a Hologram page** — routing, params, layout, server-side `init/3`, SSR
- **Building components** — stateful (with `cid`) vs stateless, props, slots, client vs server init
- **Wiring interactivity** — actions, commands, events, state updates, navigation
- **Forms** — synchronized vs non-synchronized inputs, isomorphic validation with Ecto changesets
- **Realtime** — SSE server push, channels, `put_broadcast`, subscriptions
- **Context / session / cookies / middleware** — sharing data, server-side state, auth gating
- **JavaScript interop** — calling JS from Elixir, Promise→Task, `Hologram.JS.NativeValue`
- **Debugging transpilation** — "why won't this compile to JS," unsupported stdlib, no-op-during-SSR interop
- **UX & accessibility design** — snappy navigation, optimistic updates, focus management, keyboard, ARIA live regions
- **Migration / comparison** — deciding between Hologram, LiveView, and a JS SPA

## Anti-Scope

This skill does NOT cover:
- **Phoenix internals beyond the Hologram integration** (channels, contexts, Ecto schema design in depth) — use a Phoenix/Ecto skill
- **JavaScript-framework SPAs** (React, Vue, Svelte) — see `trl-react-engineer`
- **Server-state LiveView / Surface** as the primary tool — this skill contrasts with them but builds in Hologram
- **General Elixir/OTP backend architecture** — see `trl-noizu-frameworks`

> For React/Next.js SPA engineering, see **trl-react-engineer**.
> For Elixir framework and OTP backend patterns, see **trl-noizu-frameworks**.
> For design-system / landing-page visual design, see **trl-user-experience-engineer**.
> For web-component (Lit) UIs, see **trl-lit-dev**.

## Hologram at a Glance

### How it compares

| Dimension | Hologram | Phoenix LiveView | JS SPA (React) |
|-----------|----------|------------------|----------------|
| Where state lives | **Browser** | Server | Browser |
| Event handler runs | Client (`action`) or server (`command`) | Server (round-trip each event) | Client |
| Language | Elixir (transpiled to JS) | Elixir + minimal JS | JS/TS |
| First paint | SSR HTML | SSR HTML | CSR (or SSR w/ framework) |
| Transport | HTTP/2 request-response + SSE stream | Persistent WebSocket | fetch/XHR |
| Round-trip per interaction | Only for `command`s | Every interaction | Only explicit fetches |

### Requirements (v0.10.0)

Elixir 1.15+ · OTP 24+ · Node.js 20+ · an existing Phoenix app. License Apache-2.0. Hex package `hologram`.

### Install (mix.exs + endpoint + formatter)

```elixir
# mix.exs — deps
{:hologram, "~> 0.10.0"}

# mix.exs — project/0
compilers: Mix.compilers() ++ [:hologram]

# endpoint.ex — mount Hologram's router BEFORE the Phoenix router
plug Hologram.Router
plug MyAppWeb.Router

# endpoint.ex — serve Hologram static assets
only: ["hologram" | MyAppWeb.static_paths()]

# .formatter.exs
import_deps: [:hologram],
inputs: ["{app,config,lib,test}/**/*.{ex,exs,holo}"]
```

Run with `mix holo` (starts Phoenix with Hologram enabled). Pages/components can live in an `app/` dir (add to `elixirc_paths/1`). Templates are inline `~HOLO` or a colocated `.holo` file with the same base name.

## Component Anatomy

A page (always stateful, server-initialized) with a client action and a server command:

```elixir
defmodule Blog.PostPage do
  use Hologram.Page

  route "/posts/:id"
  param :id, :integer
  layout Blog.MainLayout

  # Server-side init: runs during SSR, returns the component (and optionally server)
  def init(params, component, _server) do
    post = Blog.get_post!(params.id)
    put_state(component, :post, post)
  end

  def template do
    ~HOLO"""
    <article>
      <h1>{@post.title}</h1>
      <p>{@post.content}</p>
      <button $click="like_post">Like ({@post.likes})</button>
    </article>
    """
  end

  # Client-side: instant, no round-trip. Optimistically bump, then persist.
  def action(:like_post, _params, component) do
    component
    |> put_state([:post, :likes], component.state.post.likes + 1)
    |> put_command(:save_like, post_id: component.state.post.id)
  end

  # Server-side: privileged, async, middleware-gated.
  def command(:save_like, params, server) do
    Blog.like_post!(params.post_id)
    server
  end
end
```

A stateless component (renders purely from props) and its layout:

```elixir
defmodule Blog.PostPreview do
  use Hologram.Component
  prop :post, :map

  def template do
    ~HOLO"""
    <a href={"/posts/#{@post.id}"}>{@post.title}</a>
    """
  end
end

defmodule Blog.MainLayout do
  use Hologram.Component

  def template do
    ~HOLO"""
    <html>
      <head><Hologram.UI.Runtime /></head>
      <body><slot /></body>
    </html>
    """
  end
end
```

The layout **must** include `<Hologram.UI.Runtime />` in `<head>` and a `<slot />` for page content.

## Template & Event Quick Reference

### Interpolation & control flow (`~HOLO`)

| Purpose | Syntax |
|---------|--------|
| Text expression | `<p>{@name}</p>` |
| Full attribute | `<div class={@cls}>` |
| Interpolated attribute | `<div class="base-{@dyn}">` |
| Component prop (expr) | `<C count={42} />` |
| Component prop (string) | `<C title="Hi" />` |
| Conditional | `{%if @x} … {%else} … {/if}` |
| Iteration (pattern match ok) | `{%for item <- @items} … {/for}` |
| Raw (no processing) | `{%raw} … {/raw}` |
| Escape literal braces | `\{@literal\}` |

All interpolated expressions are **auto HTML-escaped** (XSS-safe). State/props are read with `@key`; in handler code use `component.state.key`.

### Event bindings

| Form | Example | Target |
|------|---------|--------|
| Text (action only) | `<button $click="save">` | current component |
| Shorthand w/ params (action) | `<button $click={:save, id: 1}>` | current |
| Longhand (action) | `<button $click={action: :save, target: "cart", params: %{id: 1}}>` | any cid |
| Command | `<button $click={command: :persist, params: %{id: 1}}>` | server |
| Delay | `<button $click={action: :save, delay: 1000}>` | — |
| Conditional (nil = no binding) | `<button $click={if @editable do :save end}>` | — |

**Events:** `$blur $change $click $click_outside $focus $key_down $key_up $mouse_move $pointer_cancel $pointer_down $pointer_move $pointer_up $reach_bottom $reach_left $reach_right $reach_top $resize $scroll $select $submit $transition_*`. **Global:** `<window $key_down.ctrl+k="palette" />`, `<document …>`.

**Modifiers (dot-chained):** key filters `$key_down.enter`, `$key_down.ctrl+enter`; `.debounce(300)` (default 250), `.throttle(100)`, `.once`, `.prevent_default`, `.allow_default`, `.stop_propagation`. Reach events take `within(200px)` / `within(50%)`. Event data arrives under `params.event`.

### State & flow helpers

| In an action (`%Component{}`) | In a command (`%Server{}`) |
|-------------------------------|----------------------------|
| `put_state(c, :k, v)` / `put_state(c, k1: v1, k2: v2)` / `put_state(c, [:a, :b], v)` | `put_action(s, :name)` / `put_action(s, :name, k: v)` |
| `put_action(c, :name[, params])` | `put_action(s, name: :n, target: "cid", params: %{})` |
| `put_command(c, :name[, params])` | `put_session/get_session/delete_session` |
| `put_page(c, Page[, params])` | `put_cookie/get_cookie/delete_cookie` |
| `put_context(c, :key, value)` | `put_broadcast(s, channel, :action[, params])` |

## Design Workflow

### Phase 1: Model & Boundary

| Activity | Output |
|----------|--------|
| Define routes, params, and page state shape | Page/state spec |
| Split each interaction into action (client) vs command (server) | Boundary map |
| Identify what crosses the wire and what needs auth (middleware) | Trust map |

### Phase 2: Build

| Activity | Reference |
|----------|-----------|
| Page + layout + routing | [hologram-pages-and-layouts.md](references/hologram-pages-and-layouts.md) |
| Components, props, state, `cid`, context | [hologram-components-and-state.md](references/hologram-components-and-state.md) |
| Template + event bindings | [hologram-templates-and-events.md](references/hologram-templates-and-events.md) |
| Actions & commands | [hologram-actions-and-commands.md](references/hologram-actions-and-commands.md) |

### Phase 3: Integrate

| Activity | Reference |
|----------|-----------|
| Forms + isomorphic validation | [hologram-forms-session-cookies.md](references/hologram-forms-session-cookies.md) |
| Session, cookies, middleware | [hologram-forms-session-cookies.md](references/hologram-forms-session-cookies.md) |
| Realtime server push, JS interop | [hologram-client-server-and-realtime.md](references/hologram-client-server-and-realtime.md) |

### Phase 4: UX & Quality

| Activity | Reference |
|----------|-----------|
| Interaction patterns (scroll, palette, optimistic) | [patterns/ux-interaction-patterns.md](references/patterns/ux-interaction-patterns.md) |
| Accessibility & focus management | [patterns/accessibility-patterns.md](references/patterns/accessibility-patterns.md) |
| Transpilation limits / debugging | [hologram-transpilation-limits.md](references/hologram-transpilation-limits.md) |
| Testing & deployment | [hologram-testing-and-deployment.md](references/hologram-testing-and-deployment.md) |

## Quick Start Guides

### Build an interactive page
1. Read [hologram-core-concepts.md](references/hologram-core-concepts.md) for the isomorphic model and setup
2. Scaffold the page/layout per [hologram-pages-and-layouts.md](references/hologram-pages-and-layouts.md)
3. Split interactions into actions vs commands using [hologram-actions-and-commands.md](references/hologram-actions-and-commands.md)
4. Follow the workflow in [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md)

### Add a form with validation
1. Read the forms section of [hologram-forms-session-cookies.md](references/hologram-forms-session-cookies.md)
2. Choose synchronized vs non-synchronized inputs
3. Wire isomorphic validation (share an Ecto changeset client + server)

### "Why won't this compile to JS?"
1. Read [hologram-transpilation-limits.md](references/hologram-transpilation-limits.md)
2. Check `/reference/client-runtime/elixir` for the specific function
3. Refactor privileged/unsupported code into a `command` (server-side)

### Design a snappy, accessible UI
1. Read [patterns/ux-interaction-patterns.md](references/patterns/ux-interaction-patterns.md)
2. Apply [patterns/accessibility-patterns.md](references/patterns/accessibility-patterns.md)
3. Use `Hologram.UI.Link` prefetch-on-interaction for navigation

## Reference Guide

| Task | Read These |
|------|-----------|
| **Understanding the model / setup** | `hologram-core-concepts.md` |
| **Pages, routing, layouts, navigation** | `hologram-pages-and-layouts.md` |
| **Components, props, state, cid, context** | `hologram-components-and-state.md` |
| **Template syntax and events** | `hologram-templates-and-events.md` |
| **Actions vs commands, state flow** | `hologram-actions-and-commands.md` |
| **Client/server, realtime, JS interop** | `hologram-client-server-and-realtime.md` |
| **Forms, session, cookies, middleware** | `hologram-forms-session-cookies.md` |
| **What transpiles / debugging** | `hologram-transpilation-limits.md` |
| **Testing and deployment** | `hologram-testing-and-deployment.md` |
| **UX interaction patterns** | `patterns/ux-interaction-patterns.md` |
| **Accessibility** | `patterns/accessibility-patterns.md` |
| **End-to-end build** | `worked-example-interactive-dashboard.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-react-engineer** — JS-framework SPAs when Hologram/Elixir isn't the stack
- **trl-noizu-frameworks** — Elixir/OTP backend patterns behind Hologram commands
- **trl-user-experience-engineer** — Visual design systems and landing pages
- **trl-lit-dev** — Standards-based web components for non-Elixir UIs
- **trl-skill-engineer** — Meta-skill for creating and evaluating skills

## Bundled Resources

### References

**Foundation** (read first):
- [hologram-core-concepts.md](references/hologram-core-concepts.md) — Isomorphic model, call-graph transpilation, SSR→hydrate, comparison to LiveView/Surface/SPA, installation, directory conventions
- [hologram-pages-and-layouts.md](references/hologram-pages-and-layouts.md) — `use Hologram.Page`, `route`/`param`/`layout`/`init/3`, layouts with `Hologram.UI.Runtime` + `<slot />`, navigation and `Hologram.UI.Link` prefetch
- [hologram-components-and-state.md](references/hologram-components-and-state.md) — `use Hologram.Component`, `prop/2,3`, stateful vs stateless, `cid`, `init/2` vs `init/3`, state map, `put_state`, slots, context

**Interactivity**:
- [hologram-templates-and-events.md](references/hologram-templates-and-events.md) — `~HOLO`/`.holo`, interpolation, `{%if}`/`{%for}`/`{%raw}`, escaping, the full `$event` set, modifiers, event-data shapes
- [hologram-actions-and-commands.md](references/hologram-actions-and-commands.md) — `action/3` (client) vs `command/3` (server), the trust boundary, `put_state`/`put_action`/`put_command`/`put_page`/`put_context`, server→client actions
- [hologram-client-server-and-realtime.md](references/hologram-client-server-and-realtime.md) — Transports (HTTP/2 + SSE), JS interop and Promise→Task, Realtime channels, `put_broadcast`, subscriptions

**Server integration**:
- [hologram-forms-session-cookies.md](references/hologram-forms-session-cookies.md) — Synchronized vs non-synchronized inputs, isomorphic validation (Ecto changesets), session, cookies, flat middleware and its security note

**Quality & operations**:
- [hologram-transpilation-limits.md](references/hologram-transpilation-limits.md) — Supported/unsupported Elixir, stdlib coverage, no-op-during-SSR interop, documented gotchas and anti-patterns
- [hologram-testing-and-deployment.md](references/hologram-testing-and-deployment.md) — Mirage browserless tests, feature/browser tests, deploying as a Phoenix/OTP release

**Patterns** (`references/patterns/`):
- [patterns/ux-interaction-patterns.md](references/patterns/ux-interaction-patterns.md) — Infinite scroll, command palette, popovers/menus, optimistic UI, prefetch navigation, search-as-you-type
- [patterns/accessibility-patterns.md](references/patterns/accessibility-patterns.md) — Semantic HTML, focus management on client transitions, ARIA live regions, keyboard interaction

**Execution**:
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role definition and execution workflows

**Worked Examples**:
- [worked-example-interactive-dashboard.md](references/worked-example-interactive-dashboard.md) — End-to-end: an interactive, realtime, accessible dashboard from routing through deployment

### Assets

- [project-tracker.md](assets/project-tracker.md) — Engagement tracker: page/component inventory, client/server boundary map, UX + quality checklists
- [component-scaffold-template.md](assets/component-scaffold-template.md) — Copy-paste scaffolds for pages, layouts, stateful/stateless components, forms, and commands
