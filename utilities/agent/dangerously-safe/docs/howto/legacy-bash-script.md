# How to: run the legacy bash script instead of the Rust wizard

**Goal:** get a sandboxed worktree via OS user/group isolation on a host
without Docker (or where you don't want to build/run an image), using
`bin/dangerously-safe` instead of `agent-sandbox`.
**Prereqs:** a git repo checkout; `sudo` access (it creates a system user/group
and chowns the worktree); on Linux, `getent`/`useradd`/`groupadd`; on macOS,
`dscl`.

1. Run it from anywhere inside the target repo:
   ```bash
   bin/dangerously-safe
   ```
   (Installed alongside `agent-sandbox` onto PATH by `make install-utilities`,
   so a bare `dangerously-safe` also works if the repo's `bin/` isn't already
   on PATH some other way.)
2. First run on a host missing the `claude` user or `agents` group prompts to
   create them (`sudo useradd`/`groupadd` on Linux, `dscl` on macOS) — answer
   `y` to proceed, or create them yourself and re-run.
3. It creates (or reuses) a git worktree at `<repo>/<branch>-agent` on branch
   `<branch>-agent`, rsyncs untracked files (e.g. `.envrc`) in, writes
   `.envrc.danger` (`DANGER_MODE=true`), runs `bin/restrict-access` inside the
   worktree if present and executable, then `chown -R claude:agents` the whole
   worktree.
4. `cd` into the printed worktree path and work from there as the `claude`
   user/group.

**Verify:** `ls -ld <repo>/<branch>-agent` shows owner `claude`, group
`agents`; `cat <repo>/<branch>-agent/.envrc.danger` shows
`export DANGER_MODE=true`.

**Gotchas:**
- No container and no `--network none` — isolation here is OS user/group
  permissions plus the disposable worktree/branch only, not a container
  boundary. It's a weaker sandbox than `agent-sandbox`, by design (zero
  dependencies).
- `bin/restrict-access` is optional and silently skipped (with a warning) if
  present but not executable — `chmod +x` it if your restriction hook isn't
  running.
- This script isn't getting new features — app-set images, TUI, compose/mitm,
  and templates are Rust-tool-only; reach for `agent-sandbox` unless Docker is
  genuinely unavailable.
- Re-running against an existing `<branch>-agent` worktree reuses it (skips
  worktree creation) but still re-syncs untracked files, re-runs the hook, and
  re-chowns — safe to run repeatedly.
