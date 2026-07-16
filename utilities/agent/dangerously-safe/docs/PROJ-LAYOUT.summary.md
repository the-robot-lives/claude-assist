# Project Layout — Summary

`agent-sandbox`: Rust TUI + docker builder for sandboxed coding agents; legacy `dangerously-safe` bash script kept in `bin/`.

```
dangerously-safe/
├── bin/dangerously-safe        # legacy bash launcher
├── snippets/                   # dockerfile fragment library
│   ├── base.dockerfile         #   base image
│   └── apps/                   #   per-app fragments (claude, codex, opencode, node, rust, elixir, shell)
├── src/                        # Rust source (see layout/src.md)
│   ├── cli.rs / main.rs / error.rs / paths.rs
│   ├── compose/                #   compose overlay
│   ├── config/                 #   config schema + merge
│   ├── docker/                 #   container run
│   ├── image/                  #   slug, snippets, dockerfile, registry, closest-reuse, build
│   ├── inference/              #   provider integration
│   ├── launch/                 #   env, hooks, tools
│   ├── tui/                    #   wizard widgets + preview fixtures
│   └── worktree/               #   git worktree create/status
├── templates/default/config.yaml  # default config template
├── docs/                       # PROJ-LAYOUT.md, summary, layout/
├── .gitignore
├── Cargo.toml / Cargo.lock
├── Makefile                    # compile/test/install/coverage
└── README.md
```
