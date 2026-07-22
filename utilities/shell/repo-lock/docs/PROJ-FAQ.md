# repo-lock — FAQ

Answers to the *why/when/compared-to-what* questions. For *how* see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for full design rationale see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use this instead of just following the roadmap's "lane ownership" convention?

Because the convention is social, not enforced — nothing stops a second session from editing
a path someone else claimed except everyone remembering and honoring a doc. `repo-lock` makes
that claim a runtime fact another tool or hook can check (`repo-lock check`), instead of
something only a human reads. It's still advisory — an uncooperative process can ignore a
lock entirely — so it raises the cost of a collision, it doesn't make one impossible.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-claim-a-directory-lane-before-i-start-editing).*

### Why do I need a commit mutex if I already have file/dir locks?

Because file locks only stop *edits*, not git-state races. Two sessions can hold no
overlapping file locks at all and still collide if one runs `commit --amend` or
`reset --soft` while the other is mid stage-and-commit — that's an index/HEAD race, not an
edit collision, and locking file contents does nothing to prevent it. `exec` wraps the whole
stage+commit ritual under one mutex so the two classes of race get two purpose-built
mechanisms instead of stretching one to cover both.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-run-git-commit-safely-when-other-sessions-share-this-checkout).*

### Why does repo-lock refuse to run instead of auto-generating a session id when `REPO_LOCK_SESSION` is unset?

Because a silent fallback would hide a harness-wiring bug behind the appearance of working.
If repo-lock invented an identity per invocation, every call would look like a different
"session," locks would never match up with their own holder, and re-acquire/heartbeat/release
would misbehave in ways that are hard to diagnose after the fact. Failing closed with an
actionable error surfaces the missing export immediately, when it's cheap to fix.

## Fit

### When is repo-lock the wrong tool for the job?

Three cases: a single-session workflow with no concurrent editors (there's nothing to
coordinate against, just overhead); a checkout on NFS or another network filesystem (`flock`
semantics there are unreliable or unsupported — explicitly out of scope for v1); and any
workflow expecting *prevention*, not just *detection* — repo-lock is advisory end to end, so
a determined or misconfigured process can bypass every check it offers.

### Do I still need this if I'm the only one working the repo right now?

No — install it when a second concurrent session (another agent, a teammate, a background
job) is actually in the picture. Running it solo costs you the `REPO_LOCK_SESSION` export and
nothing else, but there's no collision to guard against yet.

### Is the commit-time hook enough, or do I also need the edit-time hook?

Depends what you're protecting against. The commit-time hook (`hook install`) catches
collisions at the last responsible moment — before a bad commit lands — but two sessions can
still both edit the same locked file for however long before either commits. If you want the
edit itself blocked, you need to wire `repo-lock check` into your harness's `PreToolUse` step;
`hook install` does not do this for you.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-stop-my-agent-from-editing-a-locked-path-before-it-even-tries).*

## Comparison

### How is this different from Git's own locking (`index.lock`, etc.)?

Git's `index.lock` is a low-level, single-operation mutex the git binary itself takes and
releases around one command; it says nothing about intent, has no TTL, and isn't visible as
"who's working on what." `repo-lock`'s registry is a higher-level, human-and-agent-facing
layer above that: named holders, intent notes, TTLs, directory-prefix locks, and a
purpose-built mutex (`commit.mutex`) for the *ritual* around git-mutating commands, not just
one call to `git`.

### How does `hook install` differ from `doc-pointers hook`'s installer?

`repo-lock hook install` is wrap-and-chain: it preserves any existing `pre-commit` as
`pre-commit.chained` and calls it first, so re-running install never destroys another tool's
hook. `doc-pointers hook` installs by overwriting instead — running it *after*
`repo-lock hook install` clobbers repo-lock's chain silently. There's no auto-detection of
this collision; the fix is just to re-run `repo-lock hook install` afterward.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-recover-after-another-tool-clobbers-the-commit-hook).*

### File lock vs. directory lock — which should I take?

Take a `--dir` lock when you're working a subtree for a while (a "lane," per the roadmap
convention) — it prefix-matches everything under it. Take a plain file lock only when you
need something narrower than a whole directory and don't want to block siblings you aren't
touching. There's no automatic promotion between them; you choose the granularity at
`acquire` time.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-lock-a-single-file-instead-of-a-whole-directory-lane).*

## Capability

### Can repo-lock stop two sessions from editing the same file at the same time?

Not by itself. Out of the box it only guarantees the commit-time and mutex-probe checks —
nothing enforces a lock at edit time unless you've separately wired the opt-in
`PreToolUse`/`repo-lock check` hook into your harness. Skip that step and both sessions can
happily edit the same "locked" file right up until one of them tries to commit.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-stop-my-agent-from-editing-a-locked-path-before-it-even-tries).*

### Does a lock taken in one worktree protect the same path in another worktree?

Yes — the registry lives under `--git-common-dir`, shared by every worktree of a repo, so a
lock is visible and enforced everywhere in that repo regardless of which worktree took it.
The flip side: it also means a lock on a feature-branch worktree blocks a teammate on an
unrelated branch in another worktree of the *same* repo, even though the branches never
touch. A separately `git init`'d copy (e.g. a `Noizu/staging/` copy) has its own registry and
shares nothing.

### If a session crashes while holding a lock, does repo-lock clean up automatically?

Only past the TTL, and only passively — an expired lock stops blocking new `acquire` calls
and shows as stale in `list`/`doctor`, but the record itself isn't removed until something
calls `break`. Nothing runs on a timer to sweep expired records proactively.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-recover-a-lock-left-behind-by-a-crashed-or-abandoned-session).*

### What happens if I call `repo-lock exec` from inside another `repo-lock exec` by the same session?

It passes through instead of deadlocking. The commit mutex is scoped per-session, so a script
that wraps `git commit` in `exec` and calls a helper that also wraps its own git command in
`exec` doesn't block itself waiting on a lock it already holds. This only helps within one
session — a *different* session's `exec` still queues normally behind yours.

### Does `repo-lock doctor` fix the problems it finds?

No — it only reports them. `doctor` lists orphaned records, expired-but-uncleared locks, and
dead-pid locks, but never mutates the registry itself; you still call `break` on each flagged
path once you've confirmed it's safe to clear.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-sanity-check-the-lock-registry-itself).*

### Does `hook install` overwrite my existing pre-commit hook?

No — first install writes the managed hook directly if none exists; if one already exists
(and isn't already repo-lock's own), it's renamed to `pre-commit.chained` and invoked first,
so a chained-hook failure still short-circuits the commit before repo-lock's checks run.
If both an unmanaged hook and a leftover `pre-commit.chained` exist, install refuses rather
than guessing which one to keep.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-recover-after-another-tool-clobbers-the-commit-hook).*

## Caveats

### Why does `repo-lock check`/`list` show even my own locks as foreign when `REPO_LOCK_SESSION` is unset?

Because an anonymous caller has no identity to match against, so every held record — including
one you actually hold from another shell — reads as "someone else's." This is the same
fail-closed choice as refusing to auto-generate a session id: an unset session var means
"I don't know who I am," not "trust me, it's mine." Export `REPO_LOCK_SESSION` before trusting
a `[you]`/foreign distinction.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-see-who-holds-what-before-i-touch-a-path).*

### Why does `break` always require `--force` for a lock held on another host, even if that session is actually dead?

Because liveness is checked by probing a pid, and there's no way to probe a pid on a host
you're not running on. Same-host holders get a courtesy check (dead pid → `break` clears it
without `--force`); cross-host holders can't be verified either way, so `break` treats them as
"can't confirm, so don't assume" and requires the explicit override every time.

### What actually stops someone from just ignoring a lock?

Nothing at the filesystem level — every mechanism here is advisory. A bare
`git commit --no-verify`, hooks disabled in the environment, or simply not running
`repo-lock check` before an edit all bypass it completely. The two enforcement points
(pre-commit hook, opt-in edit-time hook) are the whole of the coverage; anything outside them
is unguarded by design, not by omission.

### What happens if `REPO_LOCK_SESSION` ends up shared across sessions (e.g. sourced from a committed `.envrc`)?

Worst case for this tool: every caller looks self-owned to every lock, so nothing ever reads
as foreign and the whole registry silently no-ops as a safety mechanism while still looking
like it's working (`list`/`status` output looks normal). This is why the identity is required
to come from a per-session harness export, never from shared, committed config.

### Does repo-lock work over NFS or a network filesystem?

No — `flock(2)` semantics on NFS and similar filesystems are unreliable or unsupported by
many implementations, and NFS-hosted checkouts are explicitly out of scope for v1. Use it
only on a local filesystem.

### What's the cost of setting too-long a TTL, or forgetting to heartbeat?

A too-long TTL just means a lock outlives the work and sits as dead weight in the registry
until someone notices and `break`s it — it isn't a security problem, just registry clutter and
a false "still locked" read for anyone checking. `heartbeat` refreshes `expires_at` by the
lock's own stored TTL; if you skip it, the lock simply expires on schedule and becomes
breakable by anyone.

## Trust

### Where does lock/registry data live, and does any of it leave my machine?

Entirely local: under `git rev-parse --git-common-dir`/`repo-lock/` in the checkout itself —
plaintext YAML records, an flock sentinel, and an append-only journal. Nothing is transmitted
anywhere by repo-lock itself; it makes no network calls. The registry never appears in
`git status` and needs no `.gitignore` entry since it lives outside the tracked tree.

### Does a lock record contain anything sensitive?

Only what you put in `--intent` (a free-text note) plus host, pid, and session UUID — no file
contents, credentials, or secrets. Treat `--intent` like a commit message: fine for
"wiring AI platform CRDs," not the place to paste anything you wouldn't want another session
on the same box to read.
