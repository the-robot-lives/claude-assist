# Worked Example — Adding a Core Action

An end-to-end walkthrough of the most expensive change type in Zellij: adding an `Action`.
Demonstrates ruling out cheaper paths, deriving the file list by grep, and the traps that
compile clean and fail at runtime.

**Goal:** add `ToggleSyncAllTabs` — toggle sync mode across *every* tab at once.
(Zellij ships `ToggleActiveSyncTab`, which affects only the active tab.)

---

## Step 1 — Rule Out the Cheap Paths

Core changes are the top of the escalation ladder. Justify getting there.

**Considered:**

| Option | Verdict |
|---|---|
| Existing `Action` | `ToggleActiveSyncTab` — active tab only ❌ |
| Compose in a keybind | Needs *per-tab iteration*; KDL binds are a fixed list, not a loop ❌ |
| Shell script | `zellij action toggle-active-sync-tab` per tab — but requires focusing each tab, which is user-visible thrashing, and there's no "for each tab" primitive ❌ |
| **Plugin** | A plugin with `ChangeApplicationState` could iterate `TabUpdate` and act per tab — **viable, and cheaper** ⚠️ |

> **Be honest with the user here.** A plugin genuinely *can* do this without touching core. The
> case for a core action is: it belongs in the keybind vocabulary, needs no wasm build, no
> permission prompt, and no version coupling. That's a reasonable argument — but it's a
> *preference*, not a necessity. Say that plainly and let them choose.

Suppose they want it in core. Proceed.

## Step 2 — Ground on a Precedent

**Do not work from this skill's file list. Derive it.** The layer set drifts between versions.

Pick the structurally closest action. `ToggleActiveSyncTab` is the obvious sibling — but for the
*shape* of a no-payload action, `SaveSession` is the cleanest template.

```bash
$ grep -rn "SaveSession" --include='*.rs' --include='*.proto' \
    zellij-utils/src zellij-server/src src
```
```
zellij-utils/src/cli.rs:888:                     SaveSession,
zellij-utils/src/errors.rs:266:                  SaveSession,
zellij-utils/src/input/actions.rs:187:           SaveSession,
zellij-utils/src/input/actions.rs:904:           CliAction::SaveSession => Ok(vec![Action::SaveSession]),
zellij-utils/src/plugin_api/plugin_command.proto:181:   SaveSession = 186;
zellij-utils/src/plugin_api/plugin_command.proto:1022:  message SaveSessionPayload {}
zellij-utils/src/plugin_api/plugin_command.rs:2415:     Some(CommandName::SaveSession) => ...
zellij-utils/src/plugin_api/plugin_command.rs:4142:     PluginCommand::SaveSession => ...
zellij-utils/src/plugin_api/action.rs:1943:             | Action::SaveSession
zellij-utils/src/client_server_contract/common_types.proto:235:  SaveSessionAction save_session = 97;
zellij-utils/src/client_server_contract/common_types.proto:293:  message SaveSessionAction {}
zellij-utils/src/ipc/protobuf_conversion.rs:1665:       Action::SaveSession => ActionType::SaveSession(...)
zellij-utils/src/ipc/protobuf_conversion.rs:1945:       ActionType::SaveSession(_) => Ok(Action::SaveSession)
zellij-server/src/route.rs:492:                  Action::SaveSession => { ... }
zellij-server/src/screen.rs:392:                 SaveSession(ClientId, Option<NotificationEnd>),
zellij-server/src/screen.rs:943:                 ScreenInstruction::SaveSession(..) => ScreenContext::SaveSession,
```

**That output is the file list.** One command, more reliable than any documentation.

Two things it reveals that surprise people:

1. **Two separate protobuf contracts.** `plugin_api/plugin_command.proto` (host ⇄ wasm) *and*
   `client_server_contract/common_types.proto` (client ⇄ server). Independent, both required.
2. **`errors.rs`.** Every `*Instruction` has a paired `*Context` for error breadcrumbs.

## Step 3 — Present the Plan Before Editing

> **13 files, two protobuf contracts.** Show this to the user *first*. It's a large change and
> they may reconsider the plugin option once they see the surface.

| # | Layer | File |
|---|---|---|
| 1 | Action | `zellij-utils/src/input/actions.rs` |
| 2 | KDL parse | `zellij-utils/src/kdl/mod.rs` |
| 3 | CliAction | `zellij-utils/src/cli.rs` |
| 4 | CLI → Action | `zellij-utils/src/input/actions.rs` |
| 5 | Plugin proto | `zellij-utils/src/plugin_api/plugin_command.proto` |
| 6 | Plugin conv. | `zellij-utils/src/plugin_api/plugin_command.rs` |
| 7 | Classification | `zellij-utils/src/plugin_api/action.rs` |
| 8 | IPC proto | `zellij-utils/src/client_server_contract/common_types.proto` |
| 9 | IPC conv. | `zellij-utils/src/ipc/protobuf_conversion.rs` |
| 10 | Route | `zellij-server/src/route.rs` |
| 11 | Instruction | `zellij-server/src/screen.rs` |
| 12 | Context | `zellij-utils/src/errors.rs` + mapping in `screen.rs` |
| 13 | Handler | `zellij-server/src/screen.rs` |

## Step 4 — Implement

### 1. The Action
`zellij-utils/src/input/actions.rs`, near `ToggleActiveSyncTab` (:220):
```rust
/// Toggle sync mode across all tabs.
ToggleSyncAllTabs,
```

### 2. KDL parsing
`zellij-utils/src/kdl/mod.rs` — string-keyed. **A miss here fails at config-load with "unknown
action", not at compile time.**

### 3–4. CLI
`cli.rs`:
```rust
/// Toggle sync mode across all tabs
ToggleSyncAllTabs,
```
`actions.rs` (near :904):
```rust
CliAction::ToggleSyncAllTabs => Ok(vec![Action::ToggleSyncAllTabs]),
```
> The return is `Vec<Action>` — one CLI verb may desugar into several actions.

### 5–7. Plugin ABI (protobuf #1)
`plugin_command.proto` — take the **next unused** number:
```protobuf
ToggleSyncAllTabs = 214;              // NOT a recycled number
message ToggleSyncAllTabsPayload {}
// + the oneof payload slot, also a fresh number
```
`plugin_command.rs` — both `TryFrom` directions.
`plugin_api/action.rs` — add to the relevant classification arm (`:1943` shows the shape).

> **Never reuse or renumber a protobuf field number.** Numbers *are* the wire format. Recycling one
> makes a mismatched plugin silently misread messages — data corruption, not a clean error.

### 8–9. IPC (protobuf #2)
`common_types.proto`:
```protobuf
message ToggleSyncAllTabsAction {}
// + slot in the action oneof, fresh number
```
`ipc/protobuf_conversion.rs` — both directions (`:1665` / `:1945` show the pattern).

> **Skipping this layer is the classic failure.** The keybind path works; the plugin path panics.
> It compiles clean either way.

### 10. Route
`zellij-server/src/route.rs`, near `:492`:
```rust
Action::ToggleSyncAllTabs => {
    session
        .senders
        .send_to_screen(ScreenInstruction::ToggleSyncAllTabs(client_id))
        .with_context(err_context)?;
},
```

### 11–13. Instruction + Context + handler
`screen.rs:321` enum:
```rust
ToggleSyncAllTabs(ClientId),
```
`errors.rs` `ScreenContext` (:215 region):
```rust
ToggleSyncAllTabs,
```
`screen.rs:943` mapping — **the step everyone forgets**:
```rust
ScreenInstruction::ToggleSyncAllTabs(..) => ScreenContext::ToggleSyncAllTabs,
```
Then the handler: iterate tabs, toggle each tab's sync flag, re-render.

> Sync state is per-tab, and focus is **per-client** (`panes/active_panes.rs`). "All tabs" means
> all tabs in the session, not all tabs the requesting client has seen. Don't accidentally make it
> client-scoped.

### Optional — default keybind
`zellij-utils/assets/config/default.kdl`. **We skip it.** Adding a default binding shadows a key
someone may rely on; leave it unbound and document it.

## Step 5 — Test

`zellij-server/src/unit/screen_tests.rs`, following the neighbors: construct state, send
`ScreenInstruction::ToggleSyncAllTabs`, assert every tab's sync flag flipped.

## Step 6 — Verify

```bash
$ cargo xtask build     # NOT bare `cargo build` — plugins must be staged
$ cargo xtask test
```

Snapshot diffs: **read them**. If a `.snap.new` appears and you didn't intend a rendering change,
that's a regression, not something to accept.

Then drive **all three entry paths** — each traverses a different subset of the 13 layers:

| Path | Command | Exercises |
|---|---|---|
| CLI | `zellij action toggle-sync-all-tabs` | cli.rs → actions.rs → IPC proto → route |
| Keybind | bind in scratch config, press | kdl/mod.rs → IPC proto → route |
| Plugin | `run_action` from a test plugin | plugin_api proto → route |

> Testing only the CLI leaves the KDL and plugin layers unverified — and the plugin protobuf layer
> is precisely where the silent failure lives. **One passing path proves very little.**

## Step 7 — Report Honestly

> "Added `ToggleSyncAllTabs` across 13 files and both protobuf contracts. `cargo xtask build` and
> `cargo xtask test` pass; the 3 snapshot diffs were reviewed and are unrelated to this change.
> Verified live via all three entry paths: `zellij action toggle-sync-all-tabs`, an `Alt s`
> keybind, and a fixture plugin calling `run_action`. Not bound by default — adding a default
> binding would shadow an existing key; document it instead."

## What This Example Demonstrates

1. **Justify reaching core** — a plugin was genuinely viable; the user chose, not you.
2. **Derive the file list by grep** — never trust a doc's list, including this skill's.
3. **Both protobuf contracts** — the single most common omission.
4. **Fresh field numbers, always.**
5. **`errors.rs` context + mapping** — the forgotten layer.
6. **The compiler won't tell you when you're done** — protobuf fallbacks and string-parsed KDL
   compile clean and fail at runtime.
7. **Three entry paths, three different layer subsets.**
8. **Read snapshots; don't bulk-accept.**

## Related

- [core/adding-an-action.md](core/adding-an-action.md) — the full recipe and checklist
- [core/server-internals.md](core/server-internals.md) — threads, the route funnel
- [core/testing-and-build.md](core/testing-and-build.md) — xtask, snapshots, verification
