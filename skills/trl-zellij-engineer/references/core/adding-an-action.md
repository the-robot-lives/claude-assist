# Adding a New Action to Zellij Core

> **Verified against Zellij `0.45.0`.** File paths and line numbers below were read from the
> checkout. Re-verify on a different version — these layers are refactored between releases.

## Why This Doc Exists

An `Action` in Zellij is not one enum. It is a **vocabulary term that must be spelled identically
in seven places**, across two independent protobuf contracts. Adding a variant to
`Action` compiles fine while being unreachable from keybinds, invisible to the CLI, and a
runtime panic from plugins.

**The failure is asymmetric:** Rust's exhaustiveness checking catches *some* missing layers at
compile time (match arms over `Action`), but the protobuf layers use catch-all fallbacks that
compile clean and fail at runtime, and the KDL layer is string-parsed so a missing entry is just
"unknown action" at config-load time. **You cannot rely on the compiler to tell you when you're done.**

So: **enumerate the full file list before editing anything.** Trace an existing action first.

## The Layer Map

```
   config.kdl                     `zellij action ...`            plugin .wasm
   keybind                             CLI                       run_action()
       │                                │                             │
       ▼                                ▼                             ▼
 ┌───────────────┐            ┌──────────────────┐        ┌────────────────────┐
 │ kdl/mod.rs    │            │ cli.rs           │        │ plugin_api/        │
 │ (str→Action)  │            │ CliAction        │        │ action.{proto,rs}  │
 └───────┬───────┘            └────────┬─────────┘        └─────────┬──────────┘
         │                             │                            │
         │                    actions.rs: CliAction → Vec<Action>   │
         │                             │                            │
         └─────────────┬───────────────┴────────────────────────────┘
                       ▼
              input/actions.rs :: Action          ← the canonical enum
                       │
                       │  client → server IPC
                       ▼
        ipc/protobuf_conversion.rs  ⇄  client_server_contract/common_types.proto
                       │                    ← SECOND, SEPARATE protobuf contract
                       ▼
              zellij-server/src/route.rs        ← Action → *Instruction
                       │
                       ▼
              screen.rs :: ScreenInstruction    ← + ScreenContext in errors.rs
                       │
                       ▼
              tab/mod.rs → panes → render
```

> **The trap most people hit:** there are **two unrelated protobuf schemas**, and both need the
> action.
> - `zellij-utils/src/plugin_api/action.proto` — the **plugin** ABI (host ⇄ wasm guest)
> - `zellij-utils/src/client_server_contract/common_types.proto` — the **client⇄server** IPC wire
>
> Updating one and not the other yields an action that works from a keybind but panics from a
> plugin (or vice versa). They are versioned and evolved independently.

## The Reference Trace: `Action::SaveSession`

`SaveSession` is the ideal template: it takes no payload, so the trace shows the *structure*
without payload noise. Every line below was grepped from the checkout.

| # | Layer | File:line | What lives there |
|---|-------|-----------|------------------|
| 1 | **Canonical enum** | `zellij-utils/src/input/actions.rs:187` | `SaveSession,` |
| 2 | **CLI subcommand** | `zellij-utils/src/cli.rs:888` | `SaveSession,` in `CliAction` |
| 3 | **CLI → Action** | `zellij-utils/src/input/actions.rs:904` | `CliAction::SaveSession => Ok(vec![Action::SaveSession])` |
| 4 | **Plugin ABI (proto)** | `zellij-utils/src/plugin_api/plugin_command.proto:181` | `SaveSession = 186;` + `SaveSessionPayload` (:1022), `SaveSessionResponse` (:1024), payload slot (:337) |
| 5 | **Plugin ABI (rust)** | `zellij-utils/src/plugin_api/plugin_command.rs:2415, :4142` | decode + encode `TryFrom` arms |
| 6 | **Action grouping** | `zellij-utils/src/plugin_api/action.rs:1943` | membership in an action classification arm |
| 7 | **IPC (proto)** | `zellij-utils/src/client_server_contract/common_types.proto:235, :293` | `SaveSessionAction save_session = 97;` + `message SaveSessionAction {}` |
| 8 | **IPC (rust)** | `zellij-utils/src/ipc/protobuf_conversion.rs:1665, :1945` | Action→proto (:1665) and proto→Action (:1945) |
| 9 | **Routing** | `zellij-server/src/route.rs:492` | `Action::SaveSession => { ...send_to_screen(ScreenInstruction::SaveSession(...)) }` |
| 10 | **Instruction** | `zellij-server/src/screen.rs:392` | `SaveSession(ClientId, Option<NotificationEnd>)` |
| 11 | **Error context** | `zellij-server/src/screen.rs:943` | `ScreenInstruction::SaveSession(..) => ScreenContext::SaveSession` |
| 12 | **Context enum** | `zellij-utils/src/errors.rs:266` | `SaveSession,` in `ScreenContext` |
| 13 | **Handler** | `zellij-server/src/screen.rs` | the actual `match` arm doing the work |

`SaveSession` additionally hops to the pty thread (`pty.rs:112` `SaveSessionToDisk`,
`pty.rs:178` context mapping, `pty.rs:801` handler, `errors.rs:485` `SaveSessionToDisk`) — an
example of an action fanning out to a second thread, each hop needing its own
Instruction + Context + handler.

> **Layer 11/12 is the one everybody forgets.** Every `*Instruction` enum has a parallel
> `*Context` enum in `zellij-utils/src/errors.rs` used for the error/panic breadcrumb trail, plus
> a `From` impl mapping between them. Miss it and you get a non-obvious compile error in
> `errors.rs` far from your change — or worse, a misleading breadcrumb in a bug report.
>
> The pairs: `ScreenInstruction`↔`ScreenContext` (:215), `PtyInstruction`↔`PtyContext` (:469),
> `PluginInstruction`↔`PluginContext` (:504), `ClientInstruction`↔`ClientContext` (:553),
> `ServerInstruction`↔`ServerContext` (:578), `PtyWriteInstruction`↔`PtyWriteContext` (:613),
> `BackgroundJob`↔`BackgroundJobContext` (:622).

## The Recipe

### Step 0 — Trace a precedent (do not skip)

Pick an existing action **structurally closest to yours**:
- no payload → `SaveSession`
- pane-targeted → any `*ByPaneId` variant
- payload + CLI args → `DumpScreen`
- spawns a pane → `NewTiledPane`

Then, in the checkout:
```bash
grep -rn "SaveSession" --include='*.rs' --include='*.proto' zellij-utils/src zellij-server/src src
```
That single grep **is** the file list. It is more reliable than any doc, including this one.
Do this every time — the layer set drifts between versions.

### Step 1 — Define the Action

`zellij-utils/src/input/actions.rs`. Match the surrounding style: named struct fields (not tuples)
for anything with more than one datum, doc comment above.

```rust
/// Toggle pane sync across all tabs.
ToggleSyncAllTabs {
    tab_id: Option<usize>,
},
```

Zellij favors `Option<T>` for "current/focused if unspecified" — follow that convention rather
than adding a separate variant.

### Step 2 — KDL parsing

`zellij-utils/src/kdl/mod.rs` — the `TryFrom<&KdlNode> for Action` machinery. This is
**string-keyed**, so a missing entry fails at config-load with "unknown action", not at compile
time. Add parsing for arguments as KDL properties/children.

### Step 3 — CLI

`zellij-utils/src/cli.rs`: add the `CliAction` variant with `clap` derives.
`zellij-utils/src/input/actions.rs`: add the `CliAction → Vec<Action>` arm.

> The return is `Vec<Action>` — one CLI invocation may expand to several actions. Useful when a
> user-facing verb is a composite.

### Step 4 — Plugin ABI (protobuf #1)

- `zellij-utils/src/plugin_api/plugin_command.proto` (and/or `action.proto`): add the enum entry
  **with a fresh field number**, the `*Payload` message, and the payload slot in the oneof.
- `zellij-utils/src/plugin_api/plugin_command.rs`: both `TryFrom` directions.
- `zellij-utils/src/plugin_api/action.rs`: add to the relevant classification arm.

> **Never reuse or renumber a protobuf field number.** Numbers are the wire format. Reusing one
> silently misinterprets messages from a mismatched plugin — a corrupt-data bug, not a clean error.
> Always take the next unused number.

### Step 5 — Client↔Server IPC (protobuf #2)

- `zellij-utils/src/client_server_contract/common_types.proto`: `message FooAction {}` + a slot
  in the action oneof with a fresh number.
- `zellij-utils/src/ipc/protobuf_conversion.rs`: both directions.

### Step 6 — Route it

`zellij-server/src/route.rs`: map `Action::Foo` to an instruction on the owning thread.
Choose by ownership: screen/tab/pane state → `ScreenInstruction`; spawning processes →
`PtyInstruction`; plugin lifecycle → `PluginInstruction`; slow/blocking work →
`BackgroundJob` (**never block the screen thread**).

### Step 7 — Instruction + Context + handler

1. Add the variant to the `*Instruction` enum (e.g. `screen.rs:321`).
2. Add the matching `*Context` variant in `errors.rs` **and** the mapping arm
   (e.g. `screen.rs:943`).
3. Implement the handler.

### Step 8 — Keybind default (optional)

`zellij-utils/assets/config/default.kdl` if it should ship bound by default. Adding a default
binding is a **user-facing behavior change** — it can shadow a key someone relies on. Prefer
leaving it unbound and documenting it.

### Step 9 — Verify

```bash
cargo xtask build
cargo xtask test
```
Then **drive it for real** — a green build proves the plumbing typechecks, not that the action
does anything:

```bash
# CLI path
zellij action <your-action>
# keybind path: bind it in a scratch config, press the key
# plugin path: call it from a plugin via run_action / the shim
```

> Each of the three entry paths (keybind, CLI, plugin) traverses a **different** subset of the
> layers. Exercising only one leaves the other two untested — and they are exactly where the
> silent protobuf failures live. Test all three, or explicitly state which you verified.

## Complete Checklist

Copy into your tracker:

- [ ] Precedent action grepped; actual file list captured
- [ ] `Action` variant added (`input/actions.rs`)
- [ ] KDL parsing (`kdl/mod.rs`)
- [ ] `CliAction` variant (`cli.rs`)
- [ ] `CliAction → Vec<Action>` (`input/actions.rs`)
- [ ] Plugin proto: enum entry + payload message + oneof slot, **fresh field number**
- [ ] Plugin rust conversion, both directions (`plugin_api/plugin_command.rs`)
- [ ] Action classification (`plugin_api/action.rs`)
- [ ] IPC proto (`client_server_contract/common_types.proto`), **fresh field number**
- [ ] IPC rust conversion, both directions (`ipc/protobuf_conversion.rs`)
- [ ] `route.rs` arm
- [ ] `*Instruction` variant
- [ ] `*Context` variant in `errors.rs` **+ mapping arm**
- [ ] Handler implemented
- [ ] Extra thread hops repeated (Instruction + Context + handler each)
- [ ] Default keybind considered (and justified if added)
- [ ] `cargo xtask build` + `cargo xtask test`
- [ ] Driven live via **keybind, CLI, and plugin**

## Adding an Event or Permission Instead

Same discipline, different spine — and **easier than it looks**, because of strum:

```rust
// zellij-utils/src/data.rs:941-945
#[derive(EnumDiscriminants, ...)]
#[strum_discriminants(name(EventType))]
#[non_exhaustive]
pub enum Event { ... }

// data.rs:1060-1063
#[strum_discriminants(name(PermissionType))]
#[non_exhaustive]
pub enum Permission { ... }
```

`EventType` and `PermissionType` are **generated discriminants** — add the variant to `Event` /
`Permission` and the type-side enum follows automatically. You do **not** hand-edit `EventType`.

Then: the protobuf side (`plugin_api/event.proto` + conversions), the emit site in the server,
and — for permissions — `PermissionType::display_name()` (`data.rs:1083`), which is the string the
user reads in the grant prompt. An empty/wrong display name means users approve something they
can't identify; treat it as required, not cosmetic.

Because both enums are `#[non_exhaustive]`, adding a variant does **not** break downstream plugin
matches — they're required to have a `_` arm. That's a deliberate compatibility affordance.

## Source Map

| Layer | File |
|---|---|
| `Action` | `zellij-utils/src/input/actions.rs:117` (137 variants) |
| KDL → Action | `zellij-utils/src/kdl/mod.rs` |
| `CliAction` | `zellij-utils/src/cli.rs` |
| Plugin ABI | `zellij-utils/src/plugin_api/{action,plugin_command}.{proto,rs}` |
| IPC ABI | `zellij-utils/src/client_server_contract/common_types.proto`, `zellij-utils/src/ipc/protobuf_conversion.rs` |
| Routing | `zellij-server/src/route.rs` |
| Instructions | `screen.rs:321`, `pty.rs:48`, `plugins/mod.rs:58`, `lib.rs:83`, `pty_writer.rs:15`, `background_jobs.rs:42` |
| Contexts | `zellij-utils/src/errors.rs:215,469,504,553,578,613,622` |
| Default keybinds | `zellij-utils/assets/config/default.kdl` |
