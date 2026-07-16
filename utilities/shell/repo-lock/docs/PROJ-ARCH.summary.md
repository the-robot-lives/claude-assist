# Project Architecture — Summary

implemented.

`repo-lock` gives concurrent sessions file/dir locks in a central registry plus a
repo-wide mutex guarding the stage+commit ritual, closing index/HEAD races.

**Identity:** REPO_LOCK_SESSION (harness-exported UUID) required for mutating ops
(incl. `hook run`) — fails closed if unset; read-only ops work anonymous.

**Enforcement:** commit-time hook (wrap-and-chain; probes commit.mutex via its owner
sidecar) plus opt-in edit-time `check` hook — concurrent edits uncovered without it.

**Design:** TTL 30m, extended per-lock by heartbeat; dead-pid locks (harness pid,
not repo-lock's own) break without --force; unicode4 handle is cosmetic/lossy.
