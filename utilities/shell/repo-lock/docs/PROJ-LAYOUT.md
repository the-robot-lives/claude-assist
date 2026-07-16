# Project Layout

_status: implemented._

```
repo-lock/
├── Cargo.toml                # single bin `repo-lock`, edition 2021 (libc, uuid v4, serde, serde_yaml, clap, sha2, chrono, anyhow)
├── src/
│   ├── main.rs                # clap dispatch + the acquire/release/list/status/check/heartbeat/break/exec/doctor implementations
│   ├── registry.rs            # registry.flock discipline; locks/*.yaml atomic (temp+rename) read-modify-write; journal.log
│   ├── record.rs               # LockRecord/Holder structs, yaml (de)serialization, path hashing, TTL parsing, pid-liveness check
│   ├── session.rs              # REPO_LOCK_SESSION resolution — fail-closed for mutating ops, anonymous for read-only
│   ├── glyph.rs                 # unicode4 handle encode + 8-hex fallback (--ascii); cosmetic only, duplicated from doc-pointers
│   ├── hook.rs                  # `hook install`/`hook run` — wrap-and-chain pre-commit installer; staged-lock + commit.mutex probe
│   └── mutex.rs                  # commit.mutex + commit.mutex.owner sidecar; REPO_LOCK_IN_EXEC reentrancy; --timeout polling
├── tests/
│   └── integration.rs        # end-to-end CLI tests (acquire/release/conflict/exec/hook flows)
├── Makefile                  # compile/test/install — cargo fmt --check + cargo test, installs target/release/repo-lock → ~/.local/bin
├── README.md                 # usage guide + example harness PreToolUse hook config
└── docs/
    ├── PROJ-ARCH.md
    ├── PROJ-ARCH.summary.md
    ├── PROJ-LAYOUT.md         # this file
    └── PROJ-LAYOUT.summary.md
```

## Key Files Requiring Setup

| File / Step | Purpose |
|-------------|---------|
| `REPO_LOCK_SESSION` env var | **Required** session identity (UUID), intended to be the tobor session UUID. Must be exported per-session by the harness (e.g. a session-start hook: `export REPO_LOCK_SESSION="$TOBOR_SESSION_UUID"`) — never sourced from a committed/shared `.envrc`, which would give every session the same identity and make every lock look self-owned. Every child/subagent shell must inherit it (ordinary env inheritance in the harness process tree). Mutating commands (including `hook run`) fail closed with an actionable error if it's unset; read-only commands (`list`/`status`/`check`) work unset, treating the caller as anonymous; `doctor` needs no session at all. |
| `repo-lock hook install` | One-time per-checkout step to install the managed pre-commit hook (marker: `# repo-lock-managed-hook`). Wrap-and-chain: preserves any existing unmanaged hook (renamed to `pre-commit.chained`, invoked first), idempotent on re-run. Does not overwrite, unlike the `doc-pointers hook` precedent — see PROJ-ARCH.md Integration Points for the known clobber interaction between the two. |
| Harness `PreToolUse` hook config (opt-in) | Wires `repo-lock check <path>` into `Edit`/`Write`/`MultiEdit` calls for edit-time enforcement — a ready-to-copy example ships in README.md. Not installed by `hook install`; the harness wiring itself is a separate, explicit opt-in step. |
| `utilities/shell/Makefile` `SUBDIRS :=` | `repo-lock` is registered, alphabetically between `remote-tunnel` and `secret-bucket`, so `make install-utilities` picks it up via `../mk/subdirs.mk`. |
