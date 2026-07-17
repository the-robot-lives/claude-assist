---
name: trl-zellij-engineer
description: >
  Engineer Zellij plugins, KDL layouts/config, keybinds, core Actions,
  pane/rendering fixes, and fork rebases. Use for zellij-tile/WASM, PipeMessage,
  ZellijWorker, ScreenInstruction, PtyInstruction, or server internals—not tmux
  or general TUIs.
extended_description: >
  Extend, configure, and modify Zellij — the Rust terminal workspace
  multiplexer. Use this skill when the user wants to write a Zellij plugin,
  author a layout or config, add or change a keybind, contribute to Zellij
  core, add a new Action, debug a pane/tab/rendering problem, or maintain a
  Zellij fork across upstream rebases — even if they don't say "Zellij."
  Also trigger when users mention zellij-tile, ZellijPlugin, register_plugin,
  zellij action, zellij pipe, KDL layout, swap_tiled_layout, pane_template,
  floating panes, stacked panes, plugin permissions, PipeMessage, ZellijWorker,
  wasm32-wasip1 plugins, cargo xtask, ScreenInstruction, PtyInstruction, or
  zellij-server internals. NOT for tmux/screen config, and NOT for general
  terminal UI frameworks like ratatui or bubbletea (that is trl-tui-engineer).
ch-description: >
  開發 Zellij 外掛、KDL 配置/版面、快捷鍵、核心 Action、窗格/渲染與分支重整。
  適用 zellij-tile/WASM、PipeMessage、ZellijWorker、Screen/PtyInstruction、
  伺服器內部；不適用 tmux 或一般 TUI。
---

# Zellij Engineer

Extend Zellij across all four of its surfaces — plugins, configuration, core internals, and fork
maintenance — grounded in the actual source checkout rather than recalled API.

## Overview

- **Plugin development** — the `zellij-tile` WASM API: `ZellijPlugin`, events, permissions, the
  202-function shim, pipes, workers, and theme-aware UI components
- **Configuration & layouts** — KDL config, the layout tree, templates, swap layouts, keybind
  modes, themes, and plugin aliases
- **Core internals** — the two-process model, seven server threads, the `Action` funnel, the
  screen/tab/pane model, and the exhaustive recipe for adding an `Action`
- **Fork maintenance** — inventorying downstream divergence and surviving upstream rebases
- **Verification discipline** — Zellij is an interactive terminal app; this skill treats a green
  build as the start of verification, not the end

## Core Philosophy

**Five Principles:**

1. **Read the checkout; never recall the API.** Zellij's plugin API and KDL schema move materially
   between releases. A remembered signature is confidently wrong — the worst kind. Every API claim
   carries a `file:line`.
2. **Count the layers before you cut.** A cross-cutting core change spans up to 13 sites across two
   independent protobuf contracts, and **the compiler will not tell you when you're done**. Enumerate
   by grepping a precedent, then edit.
3. **Climb down the escalation ladder.** Layout → keybind → `zellij action` → plugin → core change.
   Most "I need a plugin" requests are a layout.
4. **A green build proves almost nothing.** Rendering, focus, resize, and multiplayer behavior are
   invisible to the test suite. Drive it, then report what you actually drove.
5. **On a fork, protect the rebase surface.** New code in new files; no gratuitous `Action`
   variants; touch hot upstream files as little as possible.

## When to Use

- **Writing a Zellij plugin** — status bars, pickers, session tooling, custom pane UIs
- **Authoring layouts** — dev environments, swap layouts, floating/stacked arrangements
- **Configuring Zellij** — keybinds, modes, themes, options, plugin aliases
- **Contributing to core** — adding an `Action`/`Event`/`Permission`, changing pane behavior
- **Debugging** — a key that does nothing, a blank plugin pane, rendering corruption, a layout that
  won't apply
- **Scripting a session** — `zellij action` / `zellij pipe` automation
- **Maintaining a fork** — divergence inventory and upstream rebases

> For general terminal UI frameworks (ratatui, bubbletea, Ink), see **trl-tui-engineer**.
> For documenting a plugin or a Zellij change, see **trl-technical-writer**.
> For carrying a Zellij feature from story to shipped release, see **trl-story-to-release**.

## Ground Before You Answer

The one non-negotiable step. Zellij questions *feel* answerable from memory; they mostly aren't.

| Step | Why |
|---|---|
| Read `version` from the workspace `Cargo.toml` | Everything else depends on it |
| Locate the source checkout | The API is only knowable by reading it |
| Read the specific types you'll use | Produces the `file:line` you cite |
| Find the closest in-repo precedent | Beats any doc — including this skill |

**No checkout available?** Say so, and flag every signature as unverified. Do not smooth over the
gap — an unhedged wrong answer costs a debugging session.

> Verified facts from this checkout that contradict widely-circulated advice: the WASM target is
> **`wasm32-wasip1`** (not `wasm32-wasi`); plugins build as **binaries**, not `cdylib`; and
> **`EventType`/`PermissionType` are strum discriminants**, not hand-written enums.

## Surface Routing

| The user wants | Surface | Start here |
|---|---|---|
| Custom UI in a pane, reacting to session state | **Plugin** | [plugins/plugin-api.md](references/plugins/plugin-api.md) |
| A particular pane arrangement | **Layout** | [config/layouts.md](references/config/layouts.md) |
| A key that does a thing | **Keybind** | [config/keybinds-and-actions.md](references/config/keybinds-and-actions.md) |
| Scripted/automated session control | **CLI** | [config/keybinds-and-actions.md](references/config/keybinds-and-actions.md) |
| Options, themes, aliases | **Config** | [config/kdl-config.md](references/config/kdl-config.md) |
| Behavior no `Action` expresses | **Core** | [core/adding-an-action.md](references/core/adding-an-action.md) |
| To understand/debug internals | **Core** | [core/server-internals.md](references/core/server-internals.md) |
| To carry patches over upstream | **Fork** | [fork-notes.md](references/fork-notes.md) |

**The escalation ladder — always try to climb *up* this list:**

```
layout        ← no build, no code, instantly reloadable
  keybind     ← no build
    zellij action (shell script)   ← no build, no version coupling
      plugin  ← build step, version-locked to Zellij, permission model
        core change   ← up to 13 files, two protobuf contracts, upstream politics
```

A plugin earns its cost only when you must *render* something or *react* continuously. If you're
only issuing commands, a shell script over `zellij action` is faster and never version-mismatches.

## Architecture at a Glance

```
┌────────────────┐  unix socket   ┌─────────────────────────────────┐
│ zellij-client  │◀──(protobuf)──▶│ zellij-server  (the session)    │
│ owns the TTY   │                │  threads: screen, pty, wasm,    │
└────────────────┘                │  pty_writer, background_jobs,   │
                                  │  server_listener, server_router │
                                  └─────────────────────────────────┘
```

The server **outlives clients** — that is what detach/attach is, and why per-client state must be
keyed by `ClientId`. Threads communicate **only by message passing**; never block the screen thread.

Every `Action` — from a keybind, the CLI, or a plugin — funnels through
**`zellij-server/src/route.rs`**. To learn what something does, start there.

> Full detail: [core/server-internals.md](references/core/server-internals.md).

## The Action Vocabulary

**137 `Action` variants** (`zellij-utils/src/input/actions.rs:117`) back all three entry points:

| Entry | Form |
|---|---|
| Keybind | `bind "n" { NewPane; SwitchToMode "Normal"; }` |
| CLI | `zellij action new-pane --direction right` |
| Plugin | `run_action(...)` via the shim |

Learn the vocabulary once, use it three ways. Adding to it is a core change — see below.

## Adding an Action: The Cost

This is the skill's sharpest warning. An `Action` is **not one enum** — it is a term spelled
identically across up to 13 sites and **two independent protobuf contracts**:

- `plugin_api/` — the host ⇄ wasm plugin ABI
- `client_server_contract/` — the client ⇄ server IPC wire

Update one and not the other and you get an action that works from a keybind but panics from a
plugin. **Rust will not catch this**: the protobuf layers use catch-all fallbacks that compile
clean and fail at runtime, and the KDL layer is string-parsed.

**Therefore: grep a precedent first — that grep *is* the file list.**
```bash
grep -rn "SaveSession" --include='*.rs' --include='*.proto' zellij-utils/src zellij-server/src src
```

> Full 13-layer recipe and checklist: [core/adding-an-action.md](references/core/adding-an-action.md).

## Quick Start Guides

### Write a plugin
1. Rule out layout/keybind/`zellij action` first
2. Ground: version + read `zellij-tile/src/lib.rs`
3. Scaffold per [plugins/plugin-development.md](references/plugins/plugin-development.md) — pin
   `zellij-tile` to your version, no `cdylib`
4. `request_permission` in `load`; gate privileged work on `PermissionRequestResult`
5. `update` returns `true` iff state changed; `render` is pure
6. `cargo build --target wasm32-wasip1`; load with `zellij plugin -- file:...`
7. Verify live at 80×24, on resize, and **with a cleared permission cache**

### Author a layout
1. Read `zellij-utils/assets/layouts/{default,compact,strider}.kdl`
2. Sketch the tree; `split_direction` goes on the **parent**
3. Write it; templates that wrap content need `children`
4. Swap layouts: order constraints **narrowest → widest**
5. Load live; add/remove panes to exercise swaps

> Fastest path: build it interactively, then `zellij action dump-layout` for canonical KDL.

### Add a core action
1. Rule out composing existing actions
2. Grep a precedent → the exhaustive file list
3. **Present the plan before editing**
4. Implement per [core/adding-an-action.md](references/core/adding-an-action.md) — both protobuf
   contracts, fresh field numbers, the `errors.rs` context
5. `cargo xtask build && cargo xtask test`; read every snapshot diff
6. Drive **all three** entry paths

### Rebase a fork
1. Re-inventory — [fork-notes.md](references/fork-notes.md) is a dated snapshot
2. Check for uncommitted work first
3. Scratch branch; **confirm before any destructive git op**
4. Resolve: new files safe; hot files need judgment
5. Rebuild bundled `.wasm`; drive it live

## Reference Guide

| Task | Read |
|---|---|
| **Any Zellij work** | `agent-playbook.claude-code.md` |
| Plugin API: trait, events, permissions, shim, ui_components | `plugins/plugin-api.md` |
| Plugin scaffold, build, dev loop, debugging | `plugins/plugin-development.md` |
| Layout KDL: nodes, templates, swap layouts, floating | `config/layouts.md` |
| Keybinds, modes, the 137-action vocabulary | `config/keybinds-and-actions.md` |
| Config options, themes, plugin aliases | `config/kdl-config.md` |
| Crates, threads, IPC, screen/tab/pane, where to start reading | `core/server-internals.md` |
| The cross-layer action recipe | `core/adding-an-action.md` |
| xtask, unit/snapshot/e2e tests, verification | `core/testing-and-build.md` |
| Fork divergence + rebase workflow | `fork-notes.md` |
| End-to-end plugin build | `worked-example-plugin.md` |
| End-to-end core action | `worked-example-core-action.md` |

All paths relative to `references/`.

## Related Skills

- **trl-tui-engineer** — General terminal UI frameworks (ratatui, bubbletea, Ink, ncurses). Use it
  for TUI *apps*; use this skill for Zellij *itself*.
- **trl-technical-writer** — Document a plugin, a layout library, or a core change
- **trl-story-to-release** — Carry a Zellij feature from backlog to verified release
- **trl-threat-modeler** — Review the plugin permission surface or web-server exposure

> **Trigger boundary:** building a terminal app that *runs inside* a multiplexer →
> **trl-tui-engineer**. Building or configuring *the multiplexer* → this skill.

## Bundled Resources

### Root
- [INTRODUCTION.md](INTRODUCTION.md) — Consumer I/O contract (read first)

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Role, grounding
  protocol, five execution workflows, hard constraints
- [fork-notes.md](references/fork-notes.md) — **The only fork-specific file.** Downstream
  divergence inventory, conflict-risk map, rebase workflow

**Plugins** (`references/plugins/`):
- [plugin-api.md](references/plugins/plugin-api.md) — `ZellijPlugin`, the execution model, the full
  event catalogue, permissions, pipes, workers, the 202-function shim, `ui_components`
- [plugin-development.md](references/plugins/plugin-development.md) — Scaffold, `wasm32-wasip1`
  build, loading, dev loop, debugging tables, learning from `default-plugins/`

**Config** (`references/config/`):
- [layouts.md](references/config/layouts.md) — Layout tree, pane/tab nodes, templates and
  `children`, floating panes, swap layouts, debugging
- [keybinds-and-actions.md](references/config/keybinds-and-actions.md) — Modes, bind syntax,
  `shared_except`, the 137-action vocabulary grouped
- [kdl-config.md](references/config/kdl-config.md) — Options, themes, plugin aliases, env,
  runtime reconfiguration

**Core** (`references/core/`):
- [server-internals.md](references/core/server-internals.md) — Crate map, two-process model, seven
  threads, the bus, the action flow, screen/tab/pane, where to start reading
- [adding-an-action.md](references/core/adding-an-action.md) — The 13-layer recipe, a verified
  `SaveSession` trace, both protobuf contracts, the `errors.rs` trap
- [testing-and-build.md](references/core/testing-and-build.md) — `cargo xtask`, unit/snapshot/e2e
  tests, why never to bulk-accept snapshots

**Worked Examples**:
- [worked-example-plugin.md](references/worked-example-plugin.md) — Building a tab-switcher plugin
  from request through verification
- [worked-example-core-action.md](references/worked-example-core-action.md) — Adding an action
  end-to-end across every layer

### Assets
- [project-tracker.md](assets/project-tracker.md) — Per-surface tracker with a grounding checklist
- [plugin-scaffold-checklist.md](assets/plugin-scaffold-checklist.md) — Pre-flight for plugin work
- [layout-worksheet.md](assets/layout-worksheet.md) — Layout design intake
