# Zellij Plugin — Pre-Flight Checklist

> Copy into your project. Work top to bottom; the early gates save the most time.

## Gate 0 — Should this be a plugin at all?

Climb *down* only when the rung above genuinely can't do it.

- [ ] A **layout** can't express it (no build, instantly reloadable)
- [ ] A **keybind** can't do it (no build)
- [ ] A **`zellij action` shell script** can't do it (no build, no version coupling)
- [ ] No **bundled plugin** already does it — checked `default-plugins/`
- [ ] It genuinely needs to **render** or **react continuously**

**Justification:**

## Gate 1 — Grounding

The API is version-specific. Recalled signatures are the top failure mode.

- [ ] Zellij version read from workspace `Cargo.toml`: `___________`
- [ ] `zellij-tile/src/lib.rs` read (the trait)
- [ ] Precedent identified in `default-plugins/`: `___________`

| API I need | Read at file:line | ✓ |
|---|---|---|
| | | ☐ |
| | | ☐ |

## Gate 2 — Design

- [ ] State struct defined

| Event | Why subscribed | Permission required |
|---|---|---|
| | | |

- [ ] Subscribing **only** to events consumed (no idle `Mouse` / `InputReceived` — they fire
      constantly and cost a protobuf encode + WASM call each, session-wide)
- [ ] Render sketched at **80×24**

## Gate 3 — Scaffold

- [ ] `zellij-tile` **pinned** to the running Zellij version
- [ ] **No** `crate-type = ["cdylib"]` — plugins are binaries; `register_plugin!` makes `fn main()`
- [ ] `#[derive(Default)]` on state
- [ ] `register_plugin!(State)` called

## Gate 4 — Correctness traps

- [ ] **`_ => false` arm present** — `Event` is `#[non_exhaustive]`; without it you break on the
      next Zellij release
- [ ] `request_permission` in `load()`
- [ ] **No privileged shim calls in `load()`** — grants are async; the user hasn't answered yet
- [ ] All privileged work gated on `Event::PermissionRequestResult`
- [ ] `update`/`pipe` return `true` **iff** state changed
- [ ] Nothing printed from `update` — `render` only
- [ ] `render` is a **pure function of state** (it's re-called on resize with no `update`)
- [ ] `EventType::CustomMessage` subscribed **if** using workers (else replies vanish silently)
- [ ] Async results (`run_command`, `web_request`) correlated via the `Context` map, not by
      assumed ordering
- [ ] `pipe()`'s `bool` understood as a **render request** — blocking is
      `block_cli_pipe_input`/`unblock_cli_pipe_input`, separate and explicit

## Gate 5 — UI

- [ ] Built from `ui_components` (`Text`, `Table`, `NestedList`, ribbon) — theme-aware
- [ ] **No hardcoded ANSI colors** (they ignore the user's theme)
- [ ] Correct at 80×24; long lists capped to available `rows`
- [ ] No `println!` debugging — stdout **is** the render channel

## Gate 6 — Build

- [ ] `rustup target add wasm32-wasip1`
- [ ] Built for **`wasm32-wasip1`** (not `wasm32-wasi` — that's the stale advice everywhere)
- [ ] In-tree plugins: `cargo xtask build`, not bare `cargo build`

## Gate 7 — Verify live

A clean build proves the plumbing typechecks. Nothing more.

| Check | How | Result |
|---|---|---|
| Loads without panic | | |
| Renders expected content | | |
| Interactions work | | |
| **First-run permission path** (cleared cache) | | |
| 80×24 | | |
| Resize | | |

- [ ] **Cleared the permission cache and re-ran.** Grants are cached, so the "privileged call
      before grant" bug is invisible on every run after the first. This is the check that matters.
- [ ] Reloaded after a rebuild — Zellij **caches plugins**; a same-path `.wasm` often isn't picked
      up, which masquerades as "my change did nothing"

## Gate 8 — Ship

- [ ] Loaded via a **plugin alias**, not an absolute path in a shared layout
- [ ] Keybind ends with `SwitchToMode "Normal"` if it launches from a mode
- [ ] README notes the **Zellij version** it's built against
- [ ] Reported honestly what was verified vs. assumed

## Symptom → Cause

| Symptom | Look at |
|---|---|
| Panic on load | Version mismatch — rebuild against the running Zellij |
| Blank pane | `render` prints nothing, or `update` never returns `true` |
| Works only after first run | Privileged call before the grant (cache hides it) |
| Edits do nothing | Plugin cache — reload explicitly |
| Worker reply never arrives | `CustomMessage` not subscribed |
| Results mismatched | Concurrent async calls not correlated via `Context` |
| Session feels slow | Over-subscribed to high-frequency events |
| Ignores theme | Hardcoded ANSI instead of `ui_components` |
