# repo-lock

Advisory file/directory locks plus a repo-wide commit-ritual mutex for the Noizu
monorepo, where multiple concurrent AI sessions (and humans) share one checkout.

It addresses two failure classes:

1. **Edit collisions** — two workers editing the same file with nothing enforcing the
   roadmap's "lane ownership" convention at runtime.
2. **Git index/HEAD races** — one session's `commit --amend` / `reset --soft` sweeping up
   or unwinding another session's staged/committed work. File locks alone don't stop this;
   it needs mutual exclusion around the whole stage+commit ritual.

Both mechanisms are **advisory** — nothing in the filesystem stops an uncooperative
process. Enforcement is opt-in and layered (a pre-commit hook, and an edit-time harness
hook). See `docs/PROJ-ARCH.md` for the full design and `docs/PROJ-LAYOUT.md` for the
module map.

## Install

```bash
make -C utilities/shell/repo-lock install   # builds --release, installs to ~/.local/bin
# or, with the rest of the toolbelt:
make install-utilities
```

Requires a local filesystem (flock over NFS is unsupported) and `git` on `PATH`.

## Session identity — `REPO_LOCK_SESSION` (read this first)

Every **mutating** command (`acquire`, `release`, `heartbeat`, `break`, `exec`, and the
pre-commit hook's lock-reject decision) requires a session UUID in `REPO_LOCK_SESSION` and
**fails closed** with an actionable error if it is unset. There is no auto-generated
fallback — that would mask exactly the harness-wiring bug it should surface. Read-only
commands (`list`, `status`, `check`, `doctor`) work unset, treating the caller as anonymous
(so every existing lock reads as foreign).

Export it **per session** from your harness — e.g. a session-start hook that publishes the
tobor session UUID before any `repo-lock` call:

```bash
export REPO_LOCK_SESSION="$TOBOR_SESSION_UUID"   # any v4 UUID
```

> **Never source `REPO_LOCK_SESSION` from a committed/shared `.envrc`.** If every session
> read the same value, every lock would look self-owned to every caller and the tool would
> silently no-op — locks would never conflict because nothing would ever look foreign.

Every child/subagent shell must inherit the parent's `REPO_LOCK_SESSION`; ordinary
environment inheritance in the harness process tree is enough.

## Quickstart

```bash
# Claim a directory "lane" for 2h with a note:
repo-lock acquire terraform/kubernetes/platform/ai --dir --ttl 2h --intent "wiring CRDs"

# See what's held (glyph handles; --ascii for the 8-hex fallback):
repo-lock list
repo-lock status terraform/kubernetes/platform/ai

# Keep it alive (heartbeat at an interval shorter than the TTL):
repo-lock heartbeat --all

# Run the whole stage+commit ritual under the repo-wide mutex:
repo-lock exec --label "release cut" -- git commit -am "ship"

# Release when done:
repo-lock release --all
```

## Subcommand reference

| Command | Session | Purpose |
|---------|:-------:|---------|
| `acquire <path>... [--dir] [--ttl D=30m] [--intent MSG]` | required | Take a file/dir lock. Same-session re-acquire refreshes. Exit 2 on conflict. |
| `release <path>... \| --all` | required | Drop lock(s) you hold. |
| `list [--mine\|--others\|--stale] [--ascii]` | optional | Show registry contents. |
| `status <path>...` | optional | Lock state for specific path(s). |
| `check <path>...` | optional | Silent; exit 0 free / 2 locked-by-other. For scripts and hooks. |
| `heartbeat [<path>...\|--all]` | required | Refresh `expires_at`. Fails "re-acquire" if the record is gone. |
| `break <path> [--force]` | required | Clear a lock. Expired and same-host dead-pid locks break freely; others need `--force` (journaled loudly). |
| `exec [--label MSG] [--timeout D] -- <cmd>...` | required | Run `<cmd>` holding `commit.mutex`. Nested same-session `exec` passes through. |
| `hook install` | — | Install the managed pre-commit hook (wrap-and-chain, idempotent). |
| `doctor` | optional | Registry sanity: orphaned yaml, expired/dead-pid locks, journal tail. |

TTL accepts `s`/`m`/`h`/`d` units, including compound forms (`1h30m`). Default 30m.

## Commit-time enforcement (`hook install`)

```bash
repo-lock hook install    # once per checkout
```

The managed pre-commit hook makes two checks on every commit: it rejects the commit if any
staged path is locked by another session, and it non-blocking-probes `commit.mutex`,
rejecting if another session currently holds it (extending mutex protection to bare
`git commit` callers who bypass `exec`). A commit running inside its own session's `exec`
skips the mutex probe so it never rejects itself.

Install is **wrap-and-chain**: an existing unmanaged `pre-commit` is preserved as
`pre-commit.chained` and invoked first; re-running is idempotent. Note the known
interaction with `doc-pointers hook` (overwrite-based) in `docs/PROJ-ARCH.md` — running it
after `repo-lock hook install` clobbers the chain; re-run `repo-lock hook install` to
restore it.

A bare `git commit --no-verify` (or hooks disabled) bypasses this entirely — enforcement is
advisory.

## Edit-time enforcement (opt-in harness hook)

`hook install` installs only the commit-time hook. For edit-time protection, wire
`repo-lock check` into your harness's `PreToolUse` step for `Edit`/`Write` so a foreign lock
(exit 2) blocks the edit. Example Claude Code `settings.json` config:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "repo-lock check \"$CLAUDE_TOOL_FILE_PATH\""
          }
        ]
      }
    ]
  }
}
```

A non-zero exit from the hook command blocks the tool call. Adjust the path variable to
whatever your harness exposes for the target file.

## Worktrees & scope

The registry lives under `git rev-parse --git-common-dir`/`repo-lock/`, so **all worktrees
of one repo share one lock space**, keyed by repo-relative path — this is what makes the
commit mutex a real merge-level safety net. A separately `git init`'d copy (e.g. a
`Noizu/staging/` copy) has its own `.git` and therefore its own, independent registry.

## Design notes

Two behaviors worth knowing when reading a lock record. The recorded `holder.pid` is the
**parent** (harness/shell) pid, not repo-lock's own — the CLI process is ephemeral, so its
own pid would always be dead by the time a record is read; the invoking parent is the stable
proxy for the session's liveness, and it's what the dead-pid `break`-without-`--force`
fast-path checks (TTL + heartbeat remain the primary staleness mechanism). And while `exec`
holds `commit.mutex` it writes a best-effort holder record to `commit.mutex.owner`, so a
pre-commit hook rejection can name *who* currently holds the mutex — flock alone exposes only
whether it's held, not by whom; the sidecar is advisory and self-healing (a stale entry is
reaped the moment the flock is observed free).
