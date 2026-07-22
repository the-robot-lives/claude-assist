# repo-lock — FAQ Summary

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for answers.

## Motivation
- Why would I use this instead of just following the roadmap's "lane ownership" convention?
- Why do I need a commit mutex if I already have file/dir locks?
- Why does repo-lock refuse to run instead of auto-generating a session id when `REPO_LOCK_SESSION` is unset?

## Fit
- When is repo-lock the wrong tool for the job?
- Do I still need this if I'm the only one working the repo right now?
- Is the commit-time hook enough, or do I also need the edit-time hook?

## Comparison
- How is this different from Git's own locking (`index.lock`, etc.)?
- How does `hook install` differ from `doc-pointers hook`'s installer?
- File lock vs. directory lock — which should I take?

## Capability
- Can repo-lock stop two sessions from editing the same file at the same time?
- Does a lock taken in one worktree protect the same path in another worktree?
- If a session crashes while holding a lock, does repo-lock clean up automatically?
- What happens if I call `repo-lock exec` from inside another `repo-lock exec` by the same session?
- Does `repo-lock doctor` fix the problems it finds?
- Does `hook install` overwrite my existing pre-commit hook?

## Caveats
- Why does `repo-lock check`/`list` show even my own locks as foreign when `REPO_LOCK_SESSION` is unset?
- Why does `break` always require `--force` for a lock held on another host, even if that session is actually dead?
- What actually stops someone from just ignoring a lock?
- What happens if `REPO_LOCK_SESSION` ends up shared across sessions (e.g. sourced from a committed `.envrc`)?
- Does repo-lock work over NFS or a network filesystem?
- What's the cost of setting too-long a TTL, or forgetting to heartbeat?

## Trust
- Where does lock/registry data live, and does any of it leave my machine?
- Does a lock record contain anything sensitive?
