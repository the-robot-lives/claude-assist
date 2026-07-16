# How to: keep two hook-installing tools from clobbering each other

**Goal:** run both `repo-lock hook install` (misc-git-utils' sibling,
`doc-pointers hook`) in the same checkout without one silently erasing the
other's `.git/hooks/pre-commit`.
**Prereqs:** `repo-lock` and `misc-git-utils` (`doc-pointers`) both installed.

The two tools install hooks differently:
- `repo-lock hook install` **wraps and chains** — if a `pre-commit` already
  exists, it's preserved as `pre-commit.chained` and run first, then
  repo-lock's own checks run.
- `doc-pointers hook` **overwrites** — running it after `repo-lock hook
  install` replaces `.git/hooks/pre-commit` wholesale, silently dropping
  repo-lock's enforcement with no error.

1. Always install `doc-pointers hook` first, `repo-lock hook install` last:
   ```bash
   doc-pointers hook --root /path/to/repo
   repo-lock hook install
   ```
2. If you're not sure which ran last, just re-run `repo-lock hook install` —
   it's idempotent against its own output and will re-chain correctly.

**Verify:**
```bash
cat .git/hooks/pre-commit          # should reference repo-lock's checks
cat .git/hooks/pre-commit.chained  # should be present and contain the doc-pointers hook body
```

**Gotchas:**
- If `repo-lock hook install` refuses outright with `refusing to clobber;
  resolve by hand`, a leftover `.git/hooks/pre-commit.chained` from an
  earlier install is already occupying the chain slot. Read it first (it may
  hold work not yet folded in), then remove it and re-run:
  ```bash
  cat .git/hooks/pre-commit.chained
  rm .git/hooks/pre-commit.chained
  repo-lock hook install
  ```
- Scripting a fresh-clone setup that runs both tools: always put
  `repo-lock hook install` as the last line, not first — order in the setup
  script matters exactly as much as manual invocation order.
- Full detail and additional edge cases: [repo-lock's own hook-conflicts guide](../../repo-lock/docs/howto/hook-conflicts.md).
