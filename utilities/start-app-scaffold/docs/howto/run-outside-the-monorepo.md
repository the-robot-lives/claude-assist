# How to: run these tools outside the monorepo checkout

**Goal:** use an installed (`~/.local/bin/*`) copy of these tools from a
`$PWD` that isn't inside the Noizu Infra monorepo, without it silently
resolving paths to `/`.
**Prereqs:** `make install` already run once from a checkout.

1. Point `$INFRA_ROOT` at your checkout explicitly (most reliable):
   ```bash
   export INFRA_ROOT=/path/to/Noizu
   start-app-scaffold --project-dir example.com --slug example --module Example ...
   ```
2. If you don't set `INFRA_ROOT`, `lib/repo-root.sh` falls back to walking
   up from the script's own install location, then from `$PWD`, looking for
   monorepo markers. This works if you happen to be inside (or under) a
   checkout, but not from an arbitrary directory.

**Verify:**
```bash
bash -x "$(command -v start-app-scaffold)" --help 2>&1 | grep -i repo_root
```
(or just watch the first few lines of real output — a resolution failure
exits immediately with a clear error rather than defaulting to `/`.)

**Gotchas:**
- This is the whole reason `lib/repo-root.sh` exists: older per-script
  `.git`-walk-up loops used to bottom out at `/` for installed copies,
  silently writing/reading in the wrong place. If you ever see paths like
  `/components/start-app`, `INFRA_ROOT` isn't set and resolution fell
  through further than intended — treat that as a bug, not a valid result.
- `lib/repo-root.sh` itself must also be present at
  `~/.local/share/start-app-scaffold/repo-root.sh` (installed by
  `make install`) or via `$STARTAPP_LIB_DIR` — if you copied only the
  `bin/` scripts manually without running `make install`, they'll fail to
  source it.
- Setting `$INFRA_ROOT` is the one override that works regardless of where
  `$PWD` or the installed script live — prefer it in CI or scripted contexts.
