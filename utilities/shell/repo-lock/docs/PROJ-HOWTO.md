# repo-lock — How To

Task-oriented guides for using `repo-lock` day to day. For *what it is* see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where things live* see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: get repo-lock installed and confirmed working
Build, install, export a session id, install the commit hook, verify with a throwaway lock.
→ *See [howto/first-hour.md](howto/first-hour.md)*

## How to: claim a directory lane before I start editing

**Goal:** stop another session from touching the same files while you work a subtree.
**Prereqs:** `repo-lock` installed; `REPO_LOCK_SESSION` exported for this session.

1. Acquire the lane with a TTL long enough to cover the work, and an intent note:
   ```bash
   repo-lock acquire terraform/kubernetes/platform/ai --dir --ttl 2h --intent "wiring CRDs"
   ```
2. Keep it alive past the TTL with a heartbeat (run in the background or on a timer shorter
   than the TTL):
   ```bash
   repo-lock heartbeat --all
   ```
3. Release it the moment you're done:
   ```bash
   repo-lock release --all
   ```

**Verify:** `repo-lock status terraform/kubernetes/platform/ai` shows `locked by ... [you]`.

**Gotchas:**
- `acquire` on a path you already hold refreshes it in place — safe to re-run, not an error.
- A lock past its TTL with no heartbeat is just dead weight in the registry, not enforcement
  — nothing un-stages a stale editor's changes; heartbeat or keep TTLs realistic.

## How to: lock a single file instead of a whole directory lane

**Goal:** narrow a lock to one file so you don't block siblings you aren't touching.
**Prereqs:** `repo-lock` installed; `REPO_LOCK_SESSION` exported for this session.

Omit `--dir` — plain `acquire` targets exactly the path given, no prefix match:

```bash
repo-lock acquire terraform/kubernetes/platform/ai/main.tf --ttl 45m --intent "fixing CRD typo"
```

**Verify:** `repo-lock status terraform/kubernetes/platform/ai/main.tf` shows `locked by ...
[you]`; `repo-lock status terraform/kubernetes/platform/ai/variables.tf` (an untouched
sibling) shows free.

**Gotchas:**
- There's no automatic promotion between file and directory locks — re-run `acquire --dir` on
  the parent if the work grows into a whole-subtree effort; the file lock doesn't expand on
  its own.
- A directory lock already held by another session on an ancestor path still blocks your file
  lock underneath it — the prefix match works both directions.

## How to: see who holds what before I touch a path

**Goal:** avoid finding out about a collision only after `git commit` rejects you.
**Prereqs:** none — `list`/`status`/`check` all work with `REPO_LOCK_SESSION` unset.

```bash
repo-lock list                 # everything in the registry
repo-lock list --others        # just what other sessions hold
repo-lock status <path>...     # state for specific path(s)
repo-lock check <path>...      # silent; exit 0 free / 2 locked-by-other — for scripts
```

**Verify:** `list` output shows each holder's 4-glyph handle, expiry, and intent note; pass
`--ascii` if your terminal can't render the glyphs.

**Gotchas:** with `REPO_LOCK_SESSION` unset, every existing lock — including one you actually
hold from another shell — reads as foreign. Export the session id before trusting `[you]`.

## How to: stop my agent from editing a locked path before it even tries
Wire `repo-lock check` into your harness's pre-tool-call hook so edits against a
foreign-locked path are blocked, not just flagged at commit time.
→ *See [howto/edit-time-enforcement.md](howto/edit-time-enforcement.md)*

## How to: run `git commit` safely when other sessions share this checkout

**Goal:** guarantee no other session's stage/commit/rebase/reset interleaves with yours.
**Prereqs:** `REPO_LOCK_SESSION` exported.

1. Wrap the whole stage+commit ritual, not just the final `commit`:
   ```bash
   repo-lock exec --label "release cut" -- git commit -am "ship"
   ```
2. Bound how long you're willing to wait for the mutex if another session is mid-ritual:
   ```bash
   repo-lock exec --timeout 5m -- git commit -am "ship"
   ```

**Verify:** `repo-lock doctor`'s journal tail shows matching `exec-begin`/`exec-end` entries
for your session around the commit.

**Gotchas:**
- Without `hook install` also run once (see first-hour guide), a bare `git commit` outside
  `exec` is never blocked even if another session holds the mutex — `exec` and the pre-commit
  hook are complementary, not substitutes for each other.
- A nested `exec` from the *same* session (e.g. a script that calls `exec` and then a helper
  that also calls `exec`) passes through instead of deadlocking on its own mutex.

## How to: recover a lock left behind by a crashed or abandoned session

**Goal:** unblock a path after the session that locked it is gone, without waiting out a long
TTL.
**Prereqs:** `REPO_LOCK_SESSION` exported.

1. Check whether it's already safe to clear (expired, or same-host holder process is dead —
   these break without `--force`):
   ```bash
   repo-lock break terraform/kubernetes/platform/ai
   ```
2. If it's still active and live (or on another host, where liveness can't be checked), force
   it — this is journaled loudly, so only do it once you've confirmed the other session is
   actually gone:
   ```bash
   repo-lock break terraform/kubernetes/platform/ai --force
   ```

**Verify:** `repo-lock list` no longer shows the path; `repo-lock doctor`'s journal records the
force-break with the prior holder's handle.

**Gotchas:**
- `--force` doesn't ask "are you sure" — confirm with the holder (or their handle/host in
  `repo-lock status`) before breaking a live lock out from under them.
- Cross-host holders can't be liveness-checked (no pid to probe remotely), so `break` always
  requires `--force` for those even if the session is actually dead.

## How to: sanity-check the lock registry itself

**Goal:** find orphaned records, expired-but-uncleared locks, or dead-pid locks before they
confuse someone.
**Prereqs:** none — `doctor` never resolves a session identity.

```bash
repo-lock doctor
```

**Verify:** output lists registry path, record count, any problems found, and the last few
journal entries — `no problems detected` means the registry is clean.

**Gotchas:** `doctor` reports problems, it doesn't fix them — clear a flagged lock with
`break` (see above) once you've confirmed it's safe to.

## How to: recover after another tool clobbers the commit hook
Restore repo-lock's pre-commit checks after `doc-pointers hook` (or another overwrite-style
installer) replaces the hook file.
→ *See [howto/hook-conflicts.md](howto/hook-conflicts.md)*
