# Zellij Plugin Development — Scaffold, Build, Debug

> **Verified against Zellij `0.45.0`.** For the API itself (trait, events, permissions, shim,
> ui_components) see [plugin-api.md](plugin-api.md). This file covers the *workflow* around it.

## Decide First: Do You Need a Plugin?

Plugins are the heaviest extension mechanism Zellij offers. Cheaper options, in order:

| Want | Reach for |
|---|---|
| A different pane arrangement | A **layout** (`../config/layouts.md`) |
| A key that does a thing | A **keybind** (`../config/keybinds-and-actions.md`) |
| Scripted session control | **`zellij action`** from a shell script |
| Automate an existing session | `zellij action` + `zellij pipe` |
| **Custom UI in a pane, reacting to session state** | **A plugin** |
| Behavior no `Action` expresses | **Core change** (`../core/adding-an-action.md`) |

A plugin earns its cost when you need to *render* something or *react* to events continuously.
If you're only issuing commands, a shell script over `zellij action` is faster to write, needs no
build step, and never version-mismatches.

## Scaffold

```
my-plugin/
├── Cargo.toml
└── src/
    └── main.rs
```

**`Cargo.toml`** — modeled on `default-plugins/status-bar/Cargo.toml`:
```toml
[package]
name = "my-plugin"
version = "0.1.0"
edition = "2021"

[dependencies]
zellij-tile = "0.45.0"        # MUST match your Zellij version
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

> **No `crate-type = ["cdylib"]`.** Zellij plugins are **binaries** — `register_plugin!` generates
> `fn main()`. Adding `cdylib` produces a module without the expected exports and fails to load.

> **Pin `zellij-tile` to the Zellij you run.** This is not ordinary semver caution: the protobuf
> ABI is regenerated per version, and a mismatch is a panic at load, not a graceful degradation.
> In-tree plugins use `zellij-tile = { path = "../../zellij-tile" }`, which is why they can't drift.

**`src/main.rs`** — the minimum viable plugin:
```rust
use zellij_tile::prelude::*;
use std::collections::BTreeMap;

#[derive(Default)]
struct State {
    tabs: Vec<TabInfo>,
    granted: bool,
}

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[PermissionType::ReadApplicationState]);
        subscribe(&[
            EventType::PermissionRequestResult,
            EventType::TabUpdate,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(status) => {
                self.granted = matches!(status, PermissionStatus::Granted);
                true
            },
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
                true                     // state changed → re-render
            },
            _ => false,                  // REQUIRED: Event is #[non_exhaustive]
        }
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        if !self.granted {
            print_text(Text::new("awaiting permission…").dim_all());
            return;
        }
        // TabInfo fields verified at zellij-utils/src/data.rs:2239
        let mut table = Table::new().add_row(vec!["TAB", "SYNC"]);
        for tab in &self.tabs {
            let name = Text::new(&tab.name);
            let name = if tab.active { name.selected() } else { name };
            table = table.add_styled_row(vec![
                name,
                Text::new(if tab.is_sync_panes_active { "on" } else { "" }),
            ]);
        }
        print_table(table);
    }
}

register_plugin!(State);
```

## Build

```bash
rustup target add wasm32-wasip1
cargo build --release --target wasm32-wasip1
# → target/wasm32-wasip1/release/my-plugin.wasm
```

> Target is **`wasm32-wasip1`** (`xtask/src/build.rs:46`). Older docs say `wasm32-wasi` — that
> target no longer applies here and is the most common first-build failure.

In-tree plugins build via `cargo xtask build` instead.

## Load

```bash
# ad hoc, fastest for iteration
zellij plugin -- file:$PWD/target/wasm32-wasip1/release/my-plugin.wasm
zellij plugin --floating -- file:/abs/path/my-plugin.wasm
```

In a layout:
```kdl
pane {
    plugin location="file:/abs/path/my-plugin.wasm" {
        refresh_interval "5"
    }
}
```

Via an alias, so layouts stay portable (`config.kdl`):
```kdl
plugins {
    my-plugin location="file:/home/me/plugins/my-plugin.wasm"
}
```
```kdl
pane { plugin location="my-plugin" }
```

## The Dev Loop

```
edit → cargo build --target wasm32-wasip1 → reload in the live session → observe
```

Reload without restarting Zellij by binding the reload action:
```kdl
keybinds {
    shared_except "locked" {
        bind "Alt r" {
            StartOrReloadPlugin "file:/abs/path/my-plugin.wasm";
        }
    }
}
```

> **Zellij caches plugins.** A rebuilt `.wasm` at the same path is frequently *not* picked up.
> When a change appears to do nothing, suspect the cache before your code — reload explicitly.
> This wastes more plugin-dev time than any other single thing.

## Debugging

**You cannot `println!` to debug** — stdout is the render channel; printing corrupts your own UI.

| Need | Do |
|---|---|
| Trace values | `eprintln!` / `log` → lands in `~/.cache/zellij/` logs, not your pane |
| Panics | `report_panic` is auto-installed by `register_plugin!`; check the log |
| See rendered state | Render it into your own pane deliberately (a debug line) |
| Inspect session state | `zellij action list-panes` / `list-tabs` / `dump-layout` |

| Symptom | Likely cause |
|---|---|
| Panic on load | Version mismatch — rebuild against the running Zellij (`PLUGIN_MISMATCH`) |
| Pane blank | `render` prints nothing, or `update` never returns `true` |
| Nothing after a state change | `update` returned `false` |
| Works after first run only | Privileged call before `PermissionRequestResult`; permissions are cached, hiding it |
| Edits have no effect | Plugin cache — reload |
| Worker reply never arrives | Didn't `subscribe(&[EventType::CustomMessage])` |
| Async result lost | Not subscribed to `RunCommandResult` / `WebRequestResult` |
| Results mismatched | Concurrent commands not correlated via `Context` |
| Slow session | Subscribed to `Mouse`/`InputReceived` unnecessarily |
| UI ignores theme | Hardcoded ANSI instead of `ui_components` |

## Learn From the Bundled Plugins

`default-plugins/` is the best corpus available — maintained, idiomatic, always version-correct:

| Plugin | Demonstrates |
|---|---|
| `status-bar` | Modes, keybind caching (`InitialKeybinds`), ribbon rendering |
| `tab-bar` | Minimal render-only plugin |
| `compact-bar` | The same, smaller |
| `strider` | File explorer: filesystem permissions, **workers** |
| `session-manager` | Session control, list UIs, search |
| `plugin-manager`, `layout-manager`, `configuration` | Management UIs |
| `fixture-plugin-for-tests` | The API exercised deliberately for tests |

When unsure how to do something, `grep default-plugins/` for the shim function — a real call site
beats any documentation.

## Checklist

- [ ] Cheaper mechanism (layout/keybind/`zellij action`) genuinely ruled out
- [ ] `zellij-tile` pinned to the running Zellij version
- [ ] No `crate-type = ["cdylib"]`
- [ ] `_ => false` arm present (`#[non_exhaustive]`)
- [ ] Permissions requested in `load`; privileged work gated on the result event
- [ ] Tested with a **cleared permission cache**
- [ ] Subscribed only to events consumed
- [ ] `render` pure; correct at 80×24 and on resize
- [ ] Built for `wasm32-wasip1`
- [ ] `ui_components` used (theme-aware)
- [ ] Loaded and driven in a live session

## Source Map

| What | Where |
|---|---|
| API reference | [plugin-api.md](plugin-api.md) |
| Trait + macros | `zellij-tile/src/lib.rs` |
| Shim (202 fns) | `zellij-tile/src/shim.rs` |
| Examples | `default-plugins/` |
| wasm build | `xtask/src/build.rs` |
| Upstream starter | `https://github.com/zellij-org/rust-plugin-example` (`zellij-tile/src/lib.rs:16`) |
