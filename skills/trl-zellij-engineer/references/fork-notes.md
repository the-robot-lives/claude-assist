# Fork Notes — Downstream Divergence & Rebase Workflow

> **Scope.** This is the **only** fork-specific reference in this skill. Everything else describes
> upstream Zellij and stays portable. If you are working on a clean upstream checkout, skip this
> file.
>
> **Snapshot: 2026-07-16, against Zellij `0.45.0`** (fork at `~/Work/Space/Repos/3rd/zellij`).
> The inventory below was read from `git diff`/`git status` at that moment and **goes stale as the
> fork evolves**. Re-run the inventory commands before trusting it.

## Re-inventory First

```bash
git log --oneline -15
git status
git diff --stat HEAD                 # uncommitted work
git diff HEAD -- <file>              # a specific divergence
```
At snapshot time the working tree carried **~876 insertions / ~114 deletions across 30 tracked
files**, plus several untracked subsystems — i.e. **most of the fork was uncommitted**. Verify that
is still true; if the work has since been committed, `git diff HEAD` will look clean and you must
diff against the upstream merge-base instead:
```bash
git merge-base HEAD upstream/main
git diff $(git merge-base HEAD upstream/main)..HEAD --stat
```

## Features

### 1. Graphic Panes (the largest divergence)

Runs **GUI applications inside a Zellij pane**.

Two backends (`zellij-server/src/graphic_manager.rs:1-8`, `:34-40`):
- **`Nested`** (default when Xvfb is available) — spawns a nested virtual X display (Xvfb) sized
  to the pane; the app renders with `DISPLAY=:N`; frames are captured as **sixel** and drawn into
  the pane. The GUI is genuinely *inside* Zellij.
- **`Overlay`** (opt-in) — a real host window, optionally positioned with `xdotool`, with
  stdout/stderr captured into the pane. Not embedded.

| File | Lines | Role |
|---|---:|---|
| `zellij-server/src/nested_display.rs` | 1191 | Xvfb lifecycle, frame capture, `GraphicMouse` input translation |
| `zellij-server/src/panes/graphic_pane.rs` | 657 | A `Pane` impl backed by a graphic app |
| `zellij-server/src/graphic_manager.rs` | 567 | Host/orchestrator: backends, `PanePixelRect`, process supervision |

Supporting changes: `zellij-utils/src/input/command.rs` (+124) adds `GraphicApp` and `FitMode`
with `to_run_command_action` / `from_run_command_action`; `zellij-utils/src/cli.rs` (+138) adds
`CliAction::App`; `kdl_layout_parser.rs` (+57) parses `app=` / `fit=` pane properties;
`pty.rs` (+49), `tab/mod.rs` (±165), `route.rs` (+20), `layout_applier.rs` (+25).

Docs: `docs/GRAPHIC_PANES.md`. Example: `example/layouts/graphic_xeyes.kdl`.

> **The key design decision — and it's a good one.** The fork adds **no new `Action` variant**.
> A graphic app is encoded *inside* the existing `RunCommandAction` (via
> `GraphicApp::to_run_command_action`), and the CLI surface is one new `CliAction::App` that
> desugars into existing actions (`input/actions.rs`: `if app && !command.is_empty() { …
> CliAction::App … }` on `new-pane`).
>
> This sidesteps almost the entire cross-layer tax in
> [`core/adding-an-action.md`](core/adding-an-action.md) — no new protobuf field numbers in either
> contract, no new `ScreenInstruction`, no `errors.rs` context. **Preserve this pattern.** If you
> extend graphic panes, resist adding an `Action` variant; keep riding `RunCommandAction`. It is
> the single biggest reason this fork is rebasable at all.

### 2. Save Layout

Round-trips graphic-app panes through layout serialization so a dumped layout restores GUI panes.
`zellij-utils/src/session_serialization.rs` (+46) — `extract_app_and_args` re-emits `app` and
`fit` as KDL properties. `session_layout_metadata.rs` (+1).

Docs: `docs/SAVE_LAYOUT.md`.

> Serialization must stay symmetric with the **parser** (`kdl_layout_parser.rs`). A property the
> parser accepts but the serializer drops means a layout that silently degrades on
> dump→restore — and the round trip is exactly what upstream's resurrection feature does
> automatically. Test the round trip, not just the parse.

### 3. Launch Scripting

`src/main.rs` (+54), `example/launchers/`, `docs/launch-scripting.md`.

### 4. Interactive Launcher Plugin

`default-plugins/interactive-launcher/` (untracked), with a prebuilt
`zellij-utils/assets/plugins/interactive-launcher.wasm`. Wired via `xtask/src/main.rs` (+4),
`zellij-utils/src/input/plugins.rs` (+1), `consts.rs` (+1), `Cargo.toml` (+1).

> The committed `.wasm` is a **build artifact**. It must be rebuilt whenever the plugin source or
> the Zellij version changes, or it panics with `PLUGIN_MISMATCH` at load (see
> [`plugins/plugin-api.md`](plugins/plugin-api.md)). After any rebase that moves the Zellij
> version, **rebuild every bundled plugin** — this is the most likely post-rebase runtime failure.

## Conflict-Risk Map

Ranked by expected pain on an upstream rebase:

| Risk | Files | Why |
|---|---|---|
| **High** | `zellij-server/src/tab/mod.rs` (±165, most of the fork's deletions) | Large, hot upstream file; the fork both adds and *modifies* existing lines. Deletions mean the fork changed upstream logic, not just appended — conflicts here need real understanding, not `--ours`. |
| **High** | `zellij-utils/src/cli.rs` (+138) | Upstream churns `CliAction` regularly; the fork inserts a large variant. |
| **High** | `zellij-utils/src/input/command.rs` (+124) | New types plus changes to shared command construction. |
| **Medium** | `kdl_layout_parser.rs` (+57), `input/layout.rs` (+28) | Inserts into big parse match arms. |
| **Medium** | `pty.rs` (+49), `route.rs` (+20), `session_serialization.rs` (+46) | Insertions into long match statements — textual conflicts, usually mechanical. |
| **Medium** | `input/actions.rs` (+103) | Inserts into the CLI→Action desugaring. |
| **Low** | `graphic_manager.rs`, `nested_display.rs`, `graphic_pane.rs`, `interactive-launcher/` | **New files — cannot conflict.** 2415 of the fork's lines live here. |
| **Low** | `ipc/protobuf_conversion.rs` (+15), `plugin_api/action.rs` (+15), `data.rs` (+2) | Small, additive. |
| **Low** | Docs, examples, `Cargo.lock` | Regenerate or accept. |

**The fork's architecture is deliberately favorable**: the bulk of the code is in new files that
can never conflict, and the integration seams are mostly small additive insertions. Keep it that
way — every line added to `tab/mod.rs` is a line you pay for on every future rebase.

## Rebase Workflow

```bash
# 0. Commit or stash. Much of this fork has historically been UNCOMMITTED — losing it is
#    a real risk. Verify a clean tree before starting.
git status

# 1. Inventory the divergence (above) and save it somewhere outside the worktree.
git diff $(git merge-base HEAD upstream/main)..HEAD > /tmp/fork-divergence.patch

# 2. Always rebase on a scratch branch.
git fetch upstream
git checkout -b rebase-attempt-$(date +%Y%m%d)
git rebase upstream/main
```

Resolving:
1. **New files** — take ours; they cannot conflict.
2. **Additive insertions** into match arms/enums — usually take both sides; re-check ordering.
3. **`tab/mod.rs`** — read upstream's change first. The fork *modified* upstream logic here;
   blindly keeping our side can silently revert an upstream fix.
4. **Protobuf field numbers** — if upstream claimed a number the fork also used, **renumber the
   fork's**, never upstream's. Reusing a number corrupts the wire format rather than erroring.
5. **`Cargo.lock`** — regenerate.

Post-rebase verification (**all of it — none is optional**):
```bash
cargo xtask build
cargo xtask test
# Rebuild bundled plugins — the committed .wasm WILL be stale:
#   interactive-launcher.wasm and any other assets/plugins/*.wasm
```
Then drive it live — a graphic pane is exactly the thing a compile cannot validate:
```bash
zellij --layout example/layouts/graphic_xeyes.kdl
zellij action dump-layout          # save-layout round trip still symmetric?
```

## Housekeeping

Present at snapshot time and worth resolving:

| Item | Assessment |
|---|---|
| `nohup.out` | Almost certainly accidental — should be removed/gitignored, not committed |
| `.tool-versions` | Untracked; intentional? Decide whether it belongs in the repo |
| `zellij-update.md` | Untracked working note; not part of the product |
| `zellij-utils/assets/plugins/interactive-launcher.wasm` | A **build artifact in the tree**. Committing binaries is a deliberate tradeoff — upstream does ship prebuilt plugin wasm, so this follows precedent, but it must be rebuilt on every version bump |
| Most of the fork **uncommitted** | The largest risk here. 876 insertions living only in a working tree is one `git checkout` from gone — commit to a branch |

> Flag these to the user; do not "clean them up" unprompted. `nohup.out` looks like noise but the
> decision to delete files is theirs.

## Extending This Fork — Rules of Thumb

1. **New code goes in new files.** It's why the rebases are survivable.
2. **Don't add `Action` variants** — ride `RunCommandAction` like `GraphicApp` does.
3. **Touch `tab/mod.rs` as little as possible**; it is already the worst seam.
4. **Keep parser and serializer symmetric** (`kdl_layout_parser.rs` ↔ `session_serialization.rs`).
5. **Rebuild bundled plugins** on any version change.
6. **Update `docs/GRAPHIC_PANES.md` / `SAVE_LAYOUT.md`** alongside behavior changes — for an
   unreleased fork, these docs are the only spec.

## Source Map

| Feature | Files |
|---|---|
| Graphic panes | `zellij-server/src/{graphic_manager,nested_display}.rs`, `panes/graphic_pane.rs`, `zellij-utils/src/input/command.rs` (`GraphicApp`, `FitMode`), `cli.rs` (`CliAction::App`), `kdl_layout_parser.rs` (`app=`/`fit=`), `docs/GRAPHIC_PANES.md` |
| Save layout | `zellij-utils/src/session_serialization.rs`, `session_layout_metadata.rs`, `docs/SAVE_LAYOUT.md` |
| Launch scripting | `src/main.rs`, `example/launchers/`, `docs/launch-scripting.md` |
| Interactive launcher | `default-plugins/interactive-launcher/`, `xtask/src/main.rs`, `input/plugins.rs`, `consts.rs` |
| Fork tests | `tab/unit/layout_applier_tests.rs` (+7), `unit/screen_tests.rs` (+18), `input/unit/layout_test.rs` (+26) |
