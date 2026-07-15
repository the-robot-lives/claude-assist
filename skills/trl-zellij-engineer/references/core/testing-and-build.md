# Building & Testing Zellij

> **Verified against Zellij `0.45.0`.** xtask: `xtask/src/main.rs:127-141`.

## Use `cargo xtask`, Not Bare `cargo`

Zellij's build is **not** a plain `cargo build`. Plugins must be compiled to
`wasm32-wasip1` and staged as assets before the binary is useful. `cargo build` at the workspace
root produces a binary with **stale or missing bundled plugins** — which then fails at runtime with
`PLUGIN_MISMATCH` or blank plugin panes.

> If a self-built Zellij shows an empty status bar or panics loading a plugin, you almost
> certainly ran `cargo build` instead of `cargo xtask build`. Check this before debugging anything
> else.

## Commands

From `xtask/src/main.rs:127-141`:

| Command | Purpose |
|---|---|
| `cargo xtask build` | Build plugins (wasm) + the binary |
| `cargo xtask test` | Run the test suite |
| `cargo xtask run` | Build and run Zellij |
| `cargo xtask ci` | The full CI pipeline |
| `cargo xtask format` | rustfmt |
| `cargo xtask clippy` | Lints |
| `cargo xtask dist` | Distribution artifacts |
| `cargo xtask install` | Install locally |
| `cargo xtask make` | Composite pipeline |
| `cargo xtask manpage` | Generate the manpage |
| `cargo xtask publish` | Release |

The dev loop:
```bash
cargo xtask run              # build everything and launch
cargo xtask test
cargo xtask format && cargo xtask clippy
cargo xtask ci               # before opening a PR
```

Implementations live in `xtask/src/{build,test,ci,clippy,format,dist,pipelines}.rs` — read them
when a command's behavior is unclear; they're short.

## Test Layout

### Unit tests

Co-located under `unit/` directories:

| Path | Covers |
|---|---|
| `zellij-server/src/unit/screen_tests.rs` | Screen thread, instruction handling |
| `zellij-server/src/unit/pty_tests.rs` | PTY spawning |
| `zellij-server/src/unit/pty_writer_tests.rs` | PTY writes |
| `zellij-server/src/unit/os_input_output_tests.rs` | OS abstraction |
| `zellij-server/src/tab/unit/` | Tab logic, layout application |
| `zellij-server/src/panes/unit/` | Pane/grid behavior |
| `zellij-utils/src/input/unit/layout_test.rs` | **Layout KDL parsing** |

> `zellij-utils/src/input/unit/layout_test.rs` doubles as the **best available layout-schema
> documentation** — each test is a small KDL document plus its expected parse. When the layout docs
> and this file disagree, the file is right.

### Snapshot tests (`insta`)

`insta 1.6.0` (`Cargo.toml:49`, `zellij-server/Cargo.toml:72`). **214 snapshots** in
`zellij-server/src/unit/snapshots/`, e.g.
`zellij_server__screen__screen_tests__mouse_hover_effect.snap`.

Snapshots capture rendered terminal output. Workflow:
```bash
cargo xtask test                 # failing snapshot → a .snap.new file
cargo insta review               # inspect and accept/reject interactively
```

> **Never bulk-accept snapshots** (`cargo insta accept` across the board). A snapshot diff is the
> *only* signal that a change altered what users see. Read every diff: if you didn't intend a
> rendering change, an "accepted" snapshot has just silently baked in a regression. This is the
> highest-leverage review step in the whole codebase — rendering bugs rarely fail any other test.

### e2e tests

`src/tests/e2e/` plus `src/tests/cli.rs`. These drive a real terminal. They are slower and have
environment prerequisites — read `src/tests/mod.rs` and the CI config before assuming they run
locally.

## Writing Tests

Match the local pattern rather than inventing one:
- Screen/tab behavior → follow `unit/screen_tests.rs`: construct state, send instructions,
  assert (often via snapshot).
- Layout parsing → follow `input/unit/layout_test.rs`: a KDL string, parse, assert the tree.
- Rendering → snapshot.

For a new action, at minimum: a layout/KDL parse test if it's configurable, and a screen test
asserting the instruction produces the intended state change.

## Verifying a Change

**A green build and green tests do not mean the feature works.** Zellij is an interactive terminal
application; most of its behavior is unobservable to the test suite. Always drive it:

```bash
cargo xtask run                                  # a real session
zellij action <your-action>                      # the CLI path
zellij --layout ./scratch.kdl                    # the layout path
```

Test all three entry paths for an action (keybind, CLI, plugin) — each traverses a different
subset of layers (see [adding-an-action.md](adding-an-action.md)).

Check specifically at **80×24** and while **resizing** — layout bugs hide at default sizes.

## Debugging

Plugins can't `println!` — stdout is the render channel. Zellij logs to its cache dir
(`~/.cache/zellij/`). `report_panic` (installed by `register_plugin!`) routes plugin panics there.

```bash
zellij setup --check            # config/asset locations and validity
zellij setup --dump-config      # effective config
zellij action dump-layout       # canonical KDL for the live session
```

## Checklist

- [ ] Built with `cargo xtask build` (not bare `cargo build`)
- [ ] `cargo xtask test` green
- [ ] Every snapshot diff **read**, not bulk-accepted
- [ ] `cargo xtask format` + `cargo xtask clippy` clean
- [ ] Tests added following the neighboring pattern
- [ ] Driven live at 80×24 and on resize
- [ ] All relevant entry paths exercised (keybind / CLI / plugin)
- [ ] `cargo xtask ci` before the PR

## Source Map

| What | Where |
|---|---|
| xtask dispatch | `xtask/src/main.rs:127-141` |
| Build (wasm target `wasm32-wasip1`) | `xtask/src/build.rs:46,189` |
| Test runner | `xtask/src/test.rs` |
| CI pipeline | `xtask/src/ci.rs` |
| Unit tests | `zellij-server/src/unit/`, `.../tab/unit/`, `zellij-utils/src/input/unit/` |
| Snapshots (214) | `zellij-server/src/unit/snapshots/` |
| e2e | `src/tests/` |
