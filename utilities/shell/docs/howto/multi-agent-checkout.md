# How to: commit safely when several agent sessions share one checkout

**Goal:** let multiple Claude/Codex/human sessions edit the same monorepo
checkout in parallel without stomping each other's files or interleaving
commits.
**Prereqs:** `repo-lock` installed and its commit hook wired up (see
[repo-lock's first-hour guide](../../repo-lock/docs/howto/first-hour.md));
`REPO_LOCK_SESSION` exported per session; one of `misc-git-utils` (`gcap`/
`gp`) or `github-utils` (`submodule-commit`) installed for the actual
commit/push.

1. Before editing, claim the directory (or single file) you're about to work:
   ```bash
   repo-lock acquire path/to/area --dir --ttl 2h --intent "implementing X"
   ```
2. Edit as normal. If the work runs long, keep the lock alive:
   ```bash
   repo-lock heartbeat --all
   ```
3. When ready to commit, wrap the whole stage+commit step under the repo-wide
   mutex instead of calling git directly — this serializes commits across
   sessions even for paths nobody explicitly locked:
   ```bash
   repo-lock exec --label "implementing X" -- git commit -am "message"
   ```
   or, for the toolkit's own shortcut:
   ```bash
   repo-lock exec -- gcap "message"
   ```
4. Release the lane the moment you're done:
   ```bash
   repo-lock release --all
   ```

**Verify:** `repo-lock status path/to/area` shows nothing held by you after
release; `repo-lock doctor` shows matching `exec-begin`/`exec-end` journal
entries around your commit.

**Gotchas:**
- `acquire` alone does not block commits — it only blocks *other sessions'
  `acquire` calls* on the same path. The pre-commit hook (from `hook install`)
  is what actually rejects a racing/foreign-locked commit; without it, a bare
  `git commit` from another session sails through even while you hold a lock.
- If another tool (`doc-pointers hook`) also installs a `pre-commit` hook in
  this checkout, install order matters — see
  [hook-install-order.md](hook-install-order.md) or every session's commits
  will look "safe" while actually running no lock check at all.
- For submodule-heavy work, swap `gcap`/`gp` for `github-utils`'
  `submodule-commit` inside the same `repo-lock exec --` wrapper — the mutex
  doesn't care what command it's wrapping.
