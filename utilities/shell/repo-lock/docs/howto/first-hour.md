# First hour with repo-lock

## How to: install repo-lock and confirm it's wired up correctly

**Goal:** get `repo-lock` on `PATH`, a session identity exported, and the commit-time hook
installed — the minimum for the tool to actually protect anything.

**Prereqs:** local filesystem checkout (no NFS), `git` on `PATH`, Rust toolchain to build.

1. Build and install to `~/.local/bin`:
   ```bash
   make -C utilities/shell/repo-lock install
   # or, with the rest of the toolbelt:
   make install-utilities
   ```
2. Export a session identity — this must come from your harness's session-start step, one
   UUID per running session, **never** from a shared/committed `.envrc`:
   ```bash
   export REPO_LOCK_SESSION="$TOBOR_SESSION_UUID"   # any v4 UUID works for a quick test:
   # export REPO_LOCK_SESSION=$(uuidgen)
   ```
3. Install the managed pre-commit hook, once per checkout (safe to re-run):
   ```bash
   repo-lock hook install
   ```
4. Confirm the registry resolves and is empty:
   ```bash
   repo-lock doctor
   ```

**Verify:**
```bash
repo-lock acquire README.md --ttl 5m --intent "smoke test"
repo-lock list                 # shows the lock under your session's glyph handle
repo-lock release --all
```
`list` should show one active record naming your 4-glyph handle; after `release --all` it's
empty again.

**Gotchas:**
- `acquire`/`release`/`heartbeat`/`break`/`exec` all fail closed with an actionable error if
  `REPO_LOCK_SESSION` is unset — that's by design, not a bug; export it and retry.
- If a repo already has an unmanaged `pre-commit` hook, `hook install` preserves it as
  `pre-commit.chained` and runs it first — nothing is silently dropped, but confirm with
  `cat .git/hooks/pre-commit` that both stanzas are present.
- Running `doc-pointers hook` *after* `repo-lock hook install` overwrites the hook file and
  drops the chain — see [howto/hook-conflicts.md](hook-conflicts.md) if commits stop being
  checked.
