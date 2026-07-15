# Worked Example — Building a Tab-Switcher Plugin

An end-to-end walkthrough: request → challenge → ground → design → build → verify.
Demonstrates the grounding protocol, the escalation ladder, the permission trap, and honest
verification reporting.

---

## The Request

> "Write me a plugin that lists my open tabs and lets me fuzzy-jump to one."

## Step 1 — Challenge the Premise

Before building, climb the escalation ladder.

**Considered and rejected:**
- **Keybind** — `GoToTabName` exists, but requires typing an exact name. Not fuzzy, no list.
- **`zellij action`** — `zellij action query-tab-names` lists tabs, but a shell script can't render
  an interactive picker *inside* a pane.
- **Existing plugin** — `session-manager` (bundled) already does session switching with search.
  **Worth checking first.**

```bash
$ ls default-plugins/
about  compact-bar  configuration  fixture-plugin-for-tests  interactive-launcher
layout-manager  link  multiple-select  plugin-manager  session-manager  share
status-bar  strider  tab-bar
```

> **Report to the user:** "`session-manager` already does this for *sessions* and has tab
> navigation. Want me to check whether it covers your case before we build?"
>
> Suppose they confirm: they want a *tab-only*, keyboard-driven picker in a floating pane.
> A plugin is now justified — we need to **render** and **react continuously**. Proceed.

## Step 2 — Ground

Never skip. The API is version-specific.

```bash
$ grep -n -m3 "^version" Cargo.toml
12:version.workspace = true
85:version = "0.45.0"
```
→ **Zellij 0.45.0.**

```bash
$ cat -n zellij-tile/src/lib.rs | sed -n '32,49p'
```
→ `ZellijPlugin` (`zellij-tile/src/lib.rs:32`): `load(BTreeMap<String,String>)`,
`update(Event) -> bool`, `pipe(PipeMessage) -> bool`, `render(rows, cols)`. All defaulted.

What do we need?

| Need | Verified at |
|---|---|
| Tab list | `Event::TabUpdate(Vec<TabInfo>)` — `zellij-utils/src/data.rs:945` |
| Keystrokes | `Event::Key(KeyWithModifier)` — same enum |
| Jump to a tab | `shim::go_to_tab` / `switch_tab_to` — `zellij-tile/src/shim.rs` |
| Close ourselves | `shim::close_self` |
| Permissions | `ReadApplicationState` (read tabs), `ChangeApplicationState` (switch) — `data.rs:1063` |

**Precedent:** `default-plugins/session-manager` — a list UI with search and keyboard nav.

```bash
$ grep -rn "go_to_tab\|switch_tab_to" default-plugins/ | head
```
Read a real call site rather than trusting a signature from memory.

> Two grounded facts that contradict common advice, both worth stating to the user:
> - Target is **`wasm32-wasip1`** (`xtask/src/build.rs:46`), not `wasm32-wasi`.
> - **`EventType` is a strum discriminant of `Event`** (`data.rs:943`) — you subscribe with
>   `EventType`, receive `Event`.

## Step 3 — Design

| Aspect | Decision |
|---|---|
| **State** | `tabs: Vec<TabInfo>`, `filter: String`, `selected: usize`, `granted: bool` |
| **Events** | `TabUpdate` (list), `Key` (input), `PermissionRequestResult` (gate) |
| **Permissions** | `ReadApplicationState`, `ChangeApplicationState` |
| **Render** | Filter line + matching tabs, active one `.selected()` |
| **Keys** | printable → filter; Backspace → delete; Up/Down → move; Enter → jump+close; Esc → close |

At **80×24** the list must not overflow — cap visible rows to `rows - 1`.

Deliberately **not** subscribing to `Mouse` or `InputReceived`: they fire constantly and we don't
use them. Every subscription costs a protobuf encode + WASM call on every occurrence, session-wide.

## Step 4 — Scaffold

**`Cargo.toml`**
```toml
[package]
name = "tab-switcher"
version = "0.1.0"
edition = "2021"

[dependencies]
zellij-tile = "0.45.0"        # pinned to the Zellij we run
```
> No `crate-type = ["cdylib"]` — `register_plugin!` generates `fn main()`; this is a **binary**.
> Version pinned because a mismatch panics at load (`PLUGIN_MISMATCH`, `lib.rs:72`).

**`src/main.rs`**
```rust
use zellij_tile::prelude::*;
use std::collections::BTreeMap;

#[derive(Default)]
struct State {
    tabs: Vec<TabInfo>,
    filter: String,
    selected: usize,
    granted: bool,
}

impl State {
    fn matches(&self) -> Vec<&TabInfo> {
        let needle = self.filter.to_lowercase();
        self.tabs
            .iter()
            .filter(|t| needle.is_empty() || t.name.to_lowercase().contains(&needle))
            .collect()
    }
}

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        subscribe(&[
            EventType::PermissionRequestResult,
            EventType::TabUpdate,
            EventType::Key,
        ]);
        // NOTE: no privileged calls here — the grant hasn't happened yet.
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(status) => {
                self.granted = matches!(status, PermissionStatus::Granted);
                true
            },
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
                self.selected = self.selected.min(self.matches().len().saturating_sub(1));
                true
            },
            Event::Key(key) => self.on_key(key),
            _ => false,   // REQUIRED: Event is #[non_exhaustive]
        }
    }

    fn render(&mut self, rows: usize, _cols: usize) {
        if !self.granted {
            print_text(Text::new("awaiting permission…").dim_all());
            return;
        }
        print_text(Text::new(format!("> {}", self.filter)));

        let matches = self.matches();
        let visible = rows.saturating_sub(1);
        for (i, tab) in matches.iter().take(visible).enumerate() {
            let line = Text::new(&tab.name);
            let line = if i == self.selected { line.selected() } else { line };
            print_text(line);
        }
    }
}

impl State {
    fn on_key(&mut self, key: KeyWithModifier) -> bool {
        match key.bare_key {
            BareKey::Esc => { close_self(); false },
            BareKey::Enter => {
                if let Some(tab) = self.matches().get(self.selected) {
                    switch_tab_to(tab.position as u32);
                    close_self();
                }
                false
            },
            BareKey::Up => { self.selected = self.selected.saturating_sub(1); true },
            BareKey::Down => {
                let max = self.matches().len().saturating_sub(1);
                self.selected = (self.selected + 1).min(max);
                true
            },
            BareKey::Backspace => { self.filter.pop(); self.selected = 0; true },
            BareKey::Char(c) => { self.filter.push(c); self.selected = 0; true },
            _ => false,
        }
    }
}

register_plugin!(State);
```

> **The trap avoided at line ~34.** The instinct is to call `switch_tab_to` or read tabs directly
> in `load()`. Permissions are **asynchronous** — the user hasn't answered the prompt yet. Worse,
> grants are **cached**, so this bug works on every run *after the first* and looks fine in casual
> testing. Everything privileged is gated on `self.granted`, set from
> `PermissionRequestResult`.

> **`update` returns `true` exactly when state changed.** `Esc`/`Enter` return `false` because
> we're closing — no point re-rendering. Getting this wrong either wastes renders or leaves the
> UI stale.

> **Verified for 0.45.0:** `KeyWithModifier { bare_key: BareKey, .. }` at
> `zellij-utils/src/data.rs:108-109`, `BareKey` at `:187`, `PermissionStatus::{Granted, Denied}`
> at `:2752`, and `TabInfo { position, name, active, .. }` at `:2239`.
> Key representation **has changed historically** — re-check these on a different version rather
> than copying this snippet forward. Grep `default-plugins/session-manager` for a live example.

## Step 5 — Build

```bash
$ rustup target add wasm32-wasip1
$ cargo build --release --target wasm32-wasip1
    Finished release [optimized] target(s)
# → target/wasm32-wasip1/release/tab-switcher.wasm
```

## Step 6 — Load

```bash
$ zellij plugin --floating -- file:$PWD/target/wasm32-wasip1/release/tab-switcher.wasm
```

Bind it for real use (`config.kdl`):
```kdl
plugins {
    tab-switcher location="file:/home/me/plugins/tab-switcher.wasm"
}
keybinds {
    shared_except "locked" {
        bind "Alt Tab" {
            LaunchOrFocusPlugin "tab-switcher" { floating true };
            SwitchToMode "Normal";
        }
    }
}
```
> The alias keeps the absolute path out of the keybind and any shared layout.
> `SwitchToMode "Normal"` matters — without it the user is stranded in the invoking mode.

## Step 7 — Verify

**A successful build proves the plumbing typechecks. Nothing more.** What was actually driven:

| Check | Method | Result |
|---|---|---|
| Renders the tab list | Opened with 4 tabs | ✅ |
| Filter narrows | Typed `lo` → only `logs` | ✅ |
| Up/Down moves selection | Arrow keys | ✅ |
| Enter jumps and closes | Selected `logs`, Enter | ✅ |
| Esc closes without switching | Esc | ✅ |
| **First-run permission path** | **Cleared plugin permission cache, reloaded** | ✅ prompt shown, gated until granted |
| 80×24 | Resized to 80×24 with 30 tabs | ✅ list capped at `rows-1`, no overflow |
| Resize | Dragged smaller/larger | ✅ re-renders correctly |

> The **cleared-cache run is the one that matters.** Without it, the permission bug is invisible.
> If you skip it, say so rather than implying full verification.

## What This Example Demonstrates

1. **Challenge before building** — `session-manager` might already have solved it.
2. **Ground, don't recall** — version first, then `file:line` for every API used.
3. **Design the state machine before typing** — state, events, permissions, render.
4. **The permission trap** — async + cached = invisible after first run.
5. **Subscribe narrowly** — no `Mouse`/`InputReceived` we don't use.
6. **`#[non_exhaustive]` discipline** — the `_ =>` arm is mandatory.
7. **Verify honestly** — enumerate what was driven, including the cleared-cache path.

## Related

- [plugins/plugin-api.md](plugins/plugin-api.md) — the full API
- [plugins/plugin-development.md](plugins/plugin-development.md) — scaffold, dev loop, debugging
- [../assets/plugin-scaffold-checklist.md](../assets/plugin-scaffold-checklist.md) — the pre-flight
