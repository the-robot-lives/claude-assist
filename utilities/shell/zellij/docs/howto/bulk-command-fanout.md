## How to: run an arbitrary command across many project directories

**Goal:** open one zellij tab (or a dense pane grid) per selected subdirectory, each running the same shell command — for tasks that have nothing to do with Claude/Codex/nvim (bulk `git pull`, `make watch`, test runs, etc).
**Prereqs:** `zellij` and `fzf` on `PATH`; `$EDITOR` set if you want the interactive multi-line command editor (falls back to `vi`).

1. Pick directories and supply the command inline:
   ```bash
   zj-spawn -c "git pull && npm install" ~/Github
   ```
2. Or omit `-c` to get an editor opened on a scratch script — write any multi-line bash, save and quit:
   ```bash
   zj-spawn ~/Github
   ```
   An empty file (only comments/blank lines) means "shell only, no command."
3. Skip the command step entirely with `--no-command` for a plain shell per directory.
4. For many directories, pack them into a dense grid instead of one-tab-per-dir:
   ```bash
   zj-spawn --pane -c "make test" ~/Github
   ```
   Up to 6 directories share one tab (3 columns × 2 rows); beyond 6, additional tabs (`session.2`, `session.3`, …) are created automatically.

**Verify:** `zellij list-sessions` shows a session named after the base directory (or `--session` override) with one tab per selected dir (or grid tabs if `--pane`).
**Gotchas:**
- Selection picker defaults to *all pre-selected* (`Ctrl-a`/`Ctrl-d` to bulk toggle, `Tab` per-item) — the default header says "Tab=toggle off... (all selected)", easy to misread as opt-in.
- `-g/--glob` still opens the interactive picker (just pre-filters and pre-selects matches) — it does not skip `fzf` the way `zj-claude --workspace` does.
- The scratch command file for the editor path is written to `/tmp` and left in place after the session launches (no cleanup trap on that file, unlike the generated layout) — fine for occasional use, but don't put secrets in it.
