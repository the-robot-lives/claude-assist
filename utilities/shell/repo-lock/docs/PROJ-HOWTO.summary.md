# repo-lock — How To (summary)

Companion index to [PROJ-HOWTO.md](PROJ-HOWTO.md) — task list only, no steps.

- **Get repo-lock installed and confirmed working** — build, install, export a session id,
  install the commit hook, verify with a throwaway lock.
- **Claim a directory lane before I start editing** — stop another session from touching the
  same files while you work a subtree.
- **Lock a single file instead of a whole directory lane** — narrow a lock to one file so you
  don't block untouched siblings.
- **See who holds what before I touch a path** — check the registry before `git commit`
  rejects you.
- **Stop my agent from editing a locked path before it even tries** — wire `repo-lock check`
  into a harness pre-tool-call hook.
- **Run `git commit` safely when other sessions share this checkout** — wrap the whole
  stage+commit ritual under the repo-wide mutex with `exec`.
- **Recover a lock left behind by a crashed or abandoned session** — clear it with `break`,
  forcing only when the holder is confirmed gone.
- **Sanity-check the lock registry itself** — find orphaned/expired/dead-pid records with
  `doctor`.
- **Recover after another tool clobbers the commit hook** — restore repo-lock's pre-commit
  checks after an overwrite-style installer (e.g. `doc-pointers hook`) replaces the hook file.
  Also covers resolving `hook install` refusing outright when both an unmanaged hook and a
  leftover `pre-commit.chained` already exist.
