# Zellij Core Internals

> **Verified against Zellij `0.45.0`.** Line numbers read from the checkout; re-verify per version.

## Crate Map

| Crate | Role |
|---|---|
| `zellij` (`src/`) | The binary. CLI entry, arg parsing, decides attach vs start vs `action`/`plugin` dispatch |
| `zellij-client` | Terminal-side process: raw-mode input, renders server output, owns the user's TTY |
| `zellij-server` | The session process: threads, PTYs, terminal emulation, screen/tab/pane state, plugin host |
| `zellij-utils` | The shared spine: `Action`, `Event`, config/KDL, layouts, IPC types, both protobuf contracts, errors |
| `zellij-tile` | The **plugin-side** API crate (`ZellijPlugin`, shim, ui_components) |
| `zellij-tile-utils` | Styling helpers for plugins |
| `default-plugins/` | Bundled plugins (status-bar, tab-bar, strider, session-manager, …) compiled to wasm |
| `xtask/` | The task runner (`cargo xtask build|test|run|ci`) |

**The dependency shape that matters:** `zellij-utils` is depended on by *everything*, including
`zellij-tile`, which is why plugins and core share `Action`/`Event` definitions — and why a change
to `zellij-utils::data` ripples into the plugin ABI. That coupling is the reason plugin/host
version mismatches are fatal rather than degraded.

## Process Model

Zellij is **two processes**, not one:

```
┌────────────────┐   unix socket   ┌────────────────────────────┐
│ zellij-client  │◀───(protobuf)──▶│ zellij-server (the session)│
│ owns the TTY   │                 │ survives detach            │
└────────────────┘                 └────────────────────────────┘
```

The server outlives clients — that is what detach/attach *is*. Multiple clients can attach to one
server (multiplayer). Anything holding per-client state must be keyed by `ClientId`; assuming a
single client is a recurring source of multiplayer bugs.

**IPC types:** `ClientToServerMsg` (`zellij-utils/src/ipc.rs:98`), `ServerToClientMsg` (`:178`),
serialized via `zellij-utils/src/ipc/protobuf_conversion.rs` against
`client_server_contract/common_types.proto`.

## Server Threads

From `zellij-server/src/lib.rs`, each a named OS thread owning one instruction queue:

| Thread | Name | Instruction enum | Owns |
|---|---|---|---|
| Listener | `server_listener` (`lib.rs:845`) | — | Accepts client connections |
| Router | `server_router` (`lib.rs:894`) | — | Per-client; decodes msgs, routes via `route.rs` |
| PTY | `pty` (`lib.rs:1934`) | `PtyInstruction` (`pty.rs:48`) | Spawning processes, reading output |
| Screen | `screen` (`lib.rs:1958`) | `ScreenInstruction` (`screen.rs:321`) | Tabs, panes, layout, rendering |
| Plugin | **`wasm`** (`lib.rs:1997`) | `PluginInstruction` (`plugins/mod.rs:58`) | WASM host, plugin lifecycle |
| PTY writer | `pty_writer` (`lib.rs:2044`) | `PtyWriteInstruction` (`pty_writer.rs:15`) | Writes to PTY fds |
| Background jobs | `background_jobs` (`lib.rs:2061`) | `BackgroundJob` (`background_jobs.rs:42`) | Slow/periodic work |

Plus `ServerInstruction` (`lib.rs:83`) for server-level control.

> The plugin thread is named **`wasm`**, not `plugin`. When reading a backtrace or `top -H`, that
> is the thread running plugin code.

### The Bus

`zellij-server/src/thread_bus.rs`. `ThreadSenders` (`:13`) holds a channel to every thread:

```rust
senders.send_to_screen(ScreenInstruction::...)?;   // :26
senders.send_to_pty(PtyInstruction::...)?;         // :44
senders.send_to_plugin(PluginInstruction::...)?;   // :62
senders.send_to_server(ServerInstruction::...)?;   // :80
senders.send_to_pty_writer(PtyWriteInstruction::...)?;    // :97
senders.send_to_background_jobs(BackgroundJob::...)?;     // :114
```

**Threads communicate only by message passing** — no shared locks over screen state. This is the
core architectural invariant. Consequences you must respect:

1. **Never block the screen thread.** It renders. Blocking work (filesystem walks, network,
   `sleep`) goes to `background_jobs` or the pty thread, with the result sent back as an
   instruction. A blocked screen thread freezes the entire UI for every client.
2. **Ordering is per-channel, not global.** Two instructions sent to *different* threads have no
   ordering guarantee between them. If step B must observe step A's effect, B must be triggered
   *by* A's completion, not sent alongside it.
3. **Every `*Instruction` has a paired `*Context`** in `zellij-utils/src/errors.rs` for error
   breadcrumbs. Adding an instruction means adding a context (see
   [adding-an-action.md](adding-an-action.md)).

## Action Flow, End to End

```
keypress in the terminal
  → zellij-client reads raw bytes, maps via keybinds → Action
  → ClientToServerMsg (protobuf) over the unix socket
  → server_router thread decodes
  → route.rs: Action → *Instruction (route.rs:492 for SaveSession)
  → owning thread's handler (e.g. screen.rs)
  → Tab → Pane state mutation
  → render → ServerToClientMsg → client writes to TTY
```

`zellij-server/src/route.rs` is the **single funnel** where every `Action` becomes an instruction.
To learn what an action actually does, start there, not at the keybind.

The same funnel serves all three entry points — keybind, `zellij action` CLI, and plugin
`run_action` — which is why they converge on identical behavior once past their respective
decoding layers.

## Screen, Tab, Pane

- `zellij-server/src/screen.rs` — owns all tabs, the active tab per client, and top-level render.
- `zellij-server/src/tab/mod.rs` — one tab: its tiled panes, floating panes, and focus.
- **`pub trait Pane`** (`tab/mod.rs:233`) — the polymorphic pane interface. Implementors:
  - `panes/terminal_pane.rs` — a PTY-backed terminal
  - `panes/plugin_pane.rs` — a WASM plugin surface
  - `panes/graphic_pane.rs` — *fork-only* (see `references/fork-notes.md`)

> `Pane` is a **large trait** and the main extension seam. Adding a method means implementing it
> for every pane type — a real cost. Prefer a default implementation when the behavior is
> meaningful for only one kind.

### Layout managers

| Path | Role |
|---|---|
| `panes/tiled_panes/` | The tiled tree: splits, resize, stacking |
| `panes/floating_panes/` | Floating overlay panes with x/y/w/h coordinates |
| `panes/active_panes.rs` | Focus tracking, **keyed by `ClientId`** (multiplayer) |

### The terminal emulator

`panes/grid.rs` is the emulator core: the character grid, scrollback, cursor, and the `vte`
parser driving it. Supporting cast:

| File | Role |
|---|---|
| `panes/terminal_character.rs` | A styled cell |
| `panes/grid.rs` | Grid, viewport, scrollback, CSI/OSC handling |
| `panes/selection.rs` | Text selection |
| `panes/search.rs` | In-scrollback search |
| `panes/sixel.rs` | Sixel graphics |
| `panes/link_handler.rs`, `hyperlink_tracker.rs` | OSC 8 hyperlinks |
| `panes/alacritty_functions.rs` | Borrowed Alacritty emulation helpers |

> `grid.rs` is the hottest path in the codebase — every byte from every PTY flows through it.
> It is also the least forgiving place to make a change: correctness is defined by decades of
> terminal-emulation edge cases, and regressions surface as subtle rendering corruption in one
> app, not as test failures. Change it only with a specific reproduction, and lean on the
> snapshot tests.

## PTY

`zellij-server/src/pty.rs` + `os_input_output.rs`. `PtyInstruction` (`pty.rs:48`) covers spawning
terminals/commands and wiring their output back to screen. `os_input_output.rs` is the OS
abstraction (openpty, fork/exec, resize, signals) — the seam where platform differences live.

`RunCommand` (`zellij-utils/src/input/command.rs`) describes a command to spawn; `ClientOrTabIndex`
disambiguates who a spawned pane belongs to.

## Where to Start Reading

| Goal | Entry point |
|---|---|
| What does action X do? | `zellij-server/src/route.rs` |
| Why does the UI look like Y? | `screen.rs` render path → `tab/mod.rs` → the `Pane` impl |
| Why does my key do nothing? | keybind config → client mapping → `route.rs` arm |
| Rendering corruption | `panes/grid.rs` (+ snapshot tests) |
| Command spawn behavior | `pty.rs`, `os_input_output.rs` |
| Plugin misbehavior | `plugins/mod.rs` (the `wasm` thread) |
| Wire/serialization bug | `ipc/protobuf_conversion.rs`, `plugin_api/` |

## Source Map

| What | Where |
|---|---|
| Thread spawn | `zellij-server/src/lib.rs:1933-2061` |
| Bus / senders | `zellij-server/src/thread_bus.rs` |
| Action funnel | `zellij-server/src/route.rs` |
| Instructions | `screen.rs:321`, `pty.rs:48`, `plugins/mod.rs:58`, `lib.rs:83`, `pty_writer.rs:15`, `background_jobs.rs:42` |
| Contexts | `zellij-utils/src/errors.rs:215-622` |
| `Pane` trait | `zellij-server/src/tab/mod.rs:233` |
| IPC msgs | `zellij-utils/src/ipc.rs:98,178` |
| Architecture docs | `docs/arch/` |
