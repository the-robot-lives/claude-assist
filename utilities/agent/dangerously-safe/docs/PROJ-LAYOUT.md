# Project Layout

`agent-sandbox` — Rust TUI + docker image builder for running coding agents
(claude / codex / opencode) in dangerous/auto-approve mode safely, inside an
isolated git worktree mounted into a per-project docker container. Supersedes
the legacy `bin/dangerously-safe` bash script (kept and installed alongside).

```
dangerously-safe/
├── bin/                        # Legacy tooling
│   └── dangerously-safe        #   Original bash launcher (installed alongside the Rust binary)
├── snippets/                   # Dockerfile fragment library used to compose sandbox images
│   ├── base.dockerfile         #   Base image all sandbox images build from
│   └── apps/                   #   Per-app install fragments (front-matter: requires/apt; body: steps)
│       ├── claude.dockerfile   #     Claude Code CLI
│       ├── codex.dockerfile    #     Codex CLI
│       ├── opencode.dockerfile #     OpenCode CLI
│       ├── node.dockerfile     #     Node.js toolchain
│       ├── rust.dockerfile     #     Rust toolchain
│       ├── elixir.dockerfile   #     Elixir toolchain
│       └── shell.dockerfile    #     Shell utilities
├── src/                        # Rust source → [layout/src.md](layout/src.md)
│   ├── image/                  #   Image naming, registry lookup, closest-subset reuse, builds
│   ├── launch/                 #   Container launch: env, hooks, agent tool wiring
│   ├── tui/                    #   Ratatui wizard widgets + preview fixtures
│   └── main.rs                 #   Entry point (binary: agent-sandbox)
├── templates/                  # Bootstrap templates → ~/.config/agent-sandbox/templates
│   └── default/config.yaml     #   Default .agent-sandbox/config template
├── docs/                       # Documentation (this file, summary, layout/)
├── .gitignore                  # Ignores target/, coverage/, .env, .envrc.local
├── Cargo.toml                  # Crate manifest — package name: agent-sandbox
├── Cargo.lock                  # Locked dependency versions
├── Makefile                    # compile/test/install/coverage — dispatched by ../../mk/subdirs.mk
└── README.md                   # Start here — usage, image naming/reuse rules
```

Gitignored (not documented): `target/` (cargo build output), `coverage/`
(tarpaulin HTML report).

## Install Destinations (via `make install`)

| Artifact | Destination |
|----------|-------------|
| `agent-sandbox` binary | `~/.local/bin/agent-sandbox` |
| `bin/dangerously-safe` (legacy) | `~/.local/bin/dangerously-safe` |
| `snippets/` | `~/.local/share/agent-sandbox/snippets/` |
| `templates/` | `~/.config/agent-sandbox/templates/` |

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.agent-sandbox/config` (per target project) | Bootstrapped by the wizard from a template or empty |
| `~/.config/agent-sandbox/snippets/` | Optional user overrides for the snippet library |
