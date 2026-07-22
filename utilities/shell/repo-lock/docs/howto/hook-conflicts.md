# Recovering the pre-commit hook chain

## How to: fix commits no longer being checked by repo-lock

**Goal:** restore repo-lock's pre-commit checks after another tool has overwritten the hook
file.

**Prereqs:** `repo-lock` installed; you previously ran `repo-lock hook install` in this
checkout.

`repo-lock hook install` is wrap-and-chain — it preserves whatever was at `pre-commit`
already as `pre-commit.chained` and calls it first. Some other tools install hooks by
**overwrite** instead. The known offender in this monorepo is `doc-pointers hook`: running it
after `repo-lock hook install` replaces `.git/hooks/pre-commit` wholesale, silently dropping
repo-lock's lock/mutex checks — commits will succeed even against a locked path.

1. Confirm the hook is missing repo-lock's stanza:
   ```bash
   grep -q "repo-lock-managed-hook" .git/hooks/pre-commit || echo "repo-lock hook missing"
   ```
2. Re-run install to restore the chain:
   ```bash
   repo-lock hook install
   ```

**Verify:**
```bash
cat .git/hooks/pre-commit   # should show the repo-lock-managed-hook banner + exec into repo-lock
```

**Gotchas:**
- Order matters if you run both tools regularly: whichever installs *last* wins. If you use
  both `doc-pointers hook` and `repo-lock hook install` in the same checkout, re-run
  `repo-lock hook install` last, or script it to always run after `doc-pointers hook`.
- `repo-lock hook install` is idempotent against its own output, so re-running it after
  itself is always safe — there's no reason to hesitate to re-run it defensively.

## How to: resolve `hook install` refusing to install at all

**Goal:** get past `repo-lock: ... refusing to clobber; resolve by hand` and end up with both
the pre-existing hook and repo-lock's checks active.

**Prereqs:** `repo-lock` installed; error message names both `pre-commit` and
`pre-commit.chained` as already present.

This happens when `.git/hooks/pre-commit` is unmanaged (not repo-lock's) **and**
`.git/hooks/pre-commit.chained` already exists from an earlier install — install won't
guess which of the two chained-candidate files is the one you actually want called first, so
it refuses outright rather than silently discarding either.

1. Inspect both files to decide which should run first:
   ```bash
   cat .git/hooks/pre-commit
   cat .git/hooks/pre-commit.chained
   ```
2. Merge them by hand into one script (or decide one supersedes the other), then remove
   whichever file you didn't keep as the merged version:
   ```bash
   rm .git/hooks/pre-commit.chained   # once its contents are folded in or confirmed obsolete
   ```
3. Re-run install now that only one candidate remains:
   ```bash
   repo-lock hook install
   ```

**Verify:** `repo-lock hook install` completes instead of refusing; `cat
.git/hooks/pre-commit` shows the managed marker with your merged logic invoked as the chain.

**Gotchas:**
- Don't just delete `pre-commit.chained` without reading it first — it may hold the same
  overwrite-style hook this guide's main scenario is about, and discarding it silently is the
  exact "guessing" install is refusing to do on your behalf.
