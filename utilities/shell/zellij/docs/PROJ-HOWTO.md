# How-To Guides

Task-oriented guides for `utilities/shell/zellij`. For *what this is*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where files live*, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the launchers

**Goal:** get `zj-claude`, `zj-codex`, `zj-panes`, `zj-spawn`, `zj-tab` on your `PATH` and `claude-dev.kdl` into zellij's layout dir.
**Prereqs:** `zellij` and `fzf` installed; `yq` and `nvim` optional (needed for `--workspace` and the nvim pane respectively).

1. From this directory:
   ```bash
   make install
   ```
   (or from the repo root: `make install-utilities`, which delegates here)
2. This copies `bin/*` → `~/.local/bin` and `layouts/*.kdl` → `~/.config/zellij/layouts`.

**Verify:**
```bash
command -v zj-claude zj-tab && ls ~/.config/zellij/layouts/claude-dev.kdl
```
**Gotchas:**
- `make install` is idempotent — running it when `bin/` is already symlinked into `~/.local/bin` just prints "same file — skipping" for each script, it does not error.
- `~/.local/bin` must be on `PATH` for the tools to resolve after install.

## How to: open a dev session for one or more project directories

**Goal:** launch a zellij session with Claude Code prefilled, `nvim`, and a shell — one tab per directory you pick.
**Prereqs:** installed (above); `fzf` on `PATH`.

1. Run from the parent directory you want to pick projects from:
   ```bash
   zj-claude ~/Github
   ```
2. In the `fzf` picker (all dirs pre-selected by default): `Tab` toggles a dir off, `Ctrl-a`/`Ctrl-d` select/deselect all, `Enter` confirms.
3. Each selected directory gets a tab: left pane has `claude` **queued but not run** — press `Enter` in that pane to launch it. Right pane opens `nvim .`. Bottom pane is a plain shell in that directory.

**Verify:** `zellij list-sessions` shows a session named `zc-<basename of parent dir>` (or your `--session` override).
**Gotchas:**
- No dirs selected → the script prints "No directories selected." and exits 0 (no session opened) — not an error, just nothing happened.
- Session name is truncated to 20 chars (zellij's Unix-socket path limit); an explicit `--session` that collides with a running session gets a random suffix, an auto-derived one gets a timestamp suffix.
- Want Codex instead of Claude? Same tool, same flags, prefixed `--codex-*`: `zj-codex ~/Github`.

## How to: make a repeatable multi-repo workspace

Define a fixed set of directories + launch options once, reuse with `-w`.
→ *See [howto/workspace-yaml.md](howto/workspace-yaml.md)*

## How to: use a non-default AI provider (Cerebras / Z.AI)

**Goal:** queue `run-claude with cerebras-pro` or `run-claude with zai-pro` instead of plain `claude`.
**Prereqs:** the `run-claude` provider-wrapper tool on `PATH` (sibling Noizu tooling, not part of this package).

1. Add the shorthand flag to any of `zj-claude` / `zj-panes` / `zj-tab`:
   ```bash
   zj-claude --cerebras ~/Github
   zj-tab --zai .
   ```
2. Need a different provider entirely, or extra args? Use `--claude-command` for a full override instead:
   ```bash
   zj-claude --claude-command "run-claude with cerebras-pro --model foo" .
   ```

**Verify:** the prefilled command shown in the left pane (or via `--dry-run`) reads `run-claude with cerebras-pro` (etc.) instead of `claude`.
**Gotchas:** `--cerebras`/`--zai` and `--claude-command` all set the same field — whichever is parsed last on the command line wins; don't combine them expecting composition. `codex` has no such shorthand (`zj-codex` only has `--codex-command`).

## How to: preview a layout before it opens a real session

**Goal:** see the generated KDL and the resolved directory list without spawning zellij.
**Prereqs:** none beyond the tool itself.

1. Append `--dry-run` to `zj-claude`, `zj-codex`, or `zj-tab`:
   ```bash
   zj-tab --start-app "npm run dev" -c "make watch" --dry-run .
   ```
2. Read the printed layout block, then the `Tab:`/`Directory:`/`Claude:` summary lines underneath.

**Verify:** no zellij session appears in `zellij list-sessions` after running.
**Gotchas:** `--dry-run` is not available on `zj-panes` (it acts on your *current* live tab via `zellij action`, there's nothing to preview) or `zj-spawn` (prints its layout unconditionally as part of the launch banner instead).

## How to: add a dev tab or floating dev-server pane to a session already running

**Goal:** grow the session you're in instead of starting a new one.
**Prereqs:** run from inside the target zellij session (`$ZELLIJ_SESSION_NAME` set) for `zj-panes`; `zj-tab` works either inside or outside a session.

1. To add a whole new tab (claude/nvim/shell) for another project, from anywhere:
   ```bash
   zj-tab ~/Github/other-project
   ```
   Outside any session, this starts a new one instead (name `zc-<tab-name>`).
2. To instead split the pane you're *currently* in (no new tab) into the standard claude/nvim/shell layout:
   ```bash
   zj-panes .
   ```
3. Either way, add a floating dev-server preview pane with `--start-app`:
   ```bash
   zj-tab --start-app "npm run dev" .
   ```

**Verify:** `zellij action query-tab-names` (or just look) shows the new tab; for `zj-panes`, the current tab now has 3 panes.
**Gotchas:** `zj-panes` errors immediately ("not inside a zellij session") if run outside one — it tells you to use `zj-tab` instead. `zj-panes` mutates the pane you invoke it from; there's no undo beyond manually closing panes.

## How to: run an arbitrary command across many project directories

**Goal:** spin up a tab (or dense pane grid) per subdirectory with any shell command — not tied to Claude/Codex/nvim.
**Prereqs:** `fzf`; `$EDITOR` set if you want the multi-line command-editing prompt.
**Goal in detail:** → *See [howto/bulk-command-fanout.md](howto/bulk-command-fanout.md)*

**Verify:** `zellij list-sessions` shows a session named after the base directory, with one tab (or grid pane) per selected subdir.
**Gotchas:** `--pane` packs up to 6 dirs per tab in a grid instead of one-tab-per-dir — past 6 selections it opens additional numbered tabs (`session.2`, `session.3`, …).

## How to: use the static layout directly with zellij (no wrapper script)

**Goal:** open the standard claude/nvim/shell shape via zellij's own `-n`/`new-tab --layout` without any of the `zj-*` pickers.
**Prereqs:** `make install` has copied `layouts/claude-dev.kdl` to `~/.config/zellij/layouts/`.

1. New session with the layout:
   ```bash
   zellij -n claude-dev
   ```
2. Or add it as a tab to a running session, targeting a specific directory:
   ```bash
   zellij action new-tab --layout claude-dev --cwd ~/Github/my-project
   ```

**Verify:** session/tab opens with claude pane (left, focused, nothing prefilled — this path does not queue a command) | nvim pane (right) | shell pane (bottom).
**Gotchas:** unlike the `zj-*` scripts, this path does **not** prefill or queue `claude` — the left pane is a bare focused pane, you type the command yourself. It also has no per-directory batching; it's one static tab.
