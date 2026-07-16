# src/ — Rust Source Layout

Binary crate `agent-sandbox` (entry: `src/main.rs`).

```
src/
├── main.rs                 # Entry point — wires CLI to subcommand handlers
├── cli.rs                  # clap CLI definition (wizard, build-image, list-images, doctor, template, preview)
├── error.rs                # thiserror error types
├── paths.rs                # XDG / project path resolution (.agent-sandbox, share, config dirs)
├── compose/                # Compose-file handling
│   ├── mod.rs
│   └── overlay.rs          #   Overlay/merge of compose definitions
├── config/                 # Sandbox config (.agent-sandbox/config)
│   ├── mod.rs
│   ├── schema.rs           #   serde schema for config.yaml
│   └── merge.rs            #   Config layering/merge rules
├── docker/                 # Docker invocation
│   ├── mod.rs
│   └── run.rs              #   Container run/exec (interactive shell into sandbox)
├── image/                  # Sandbox image lifecycle
│   ├── mod.rs
│   ├── slug.rs             #   App-slug normalization → sorted tag set
│   ├── snippets.rs         #   Loads per-app dockerfile fragments (+ user overrides)
│   ├── dockerfile.rs       #   Composes final Dockerfile from base + app fragments
│   ├── registry.rs         #   Local image inventory via OCI label org.agent-sandbox.apps
│   ├── closest.rs          #   Closest subset-image reuse selection
│   └── build.rs            #   docker build orchestration (incl. --dry-run)
├── inference/              # Inference/provider integration
│   └── mod.rs
├── launch/                 # Container launch pipeline
│   ├── mod.rs
│   ├── env.rs              #   Controlled env var passthrough
│   ├── hooks.rs            #   Pre/post launch hooks
│   └── tools.rs            #   Agent tool availability on PATH
├── tui/                    # Ratatui interactive wizard
│   ├── mod.rs
│   ├── widgets.rs          #   Wizard screens/widgets
│   └── fixtures.rs         #   Fixture data for `preview` mode (no docker/git)
└── worktree/               # Git worktree management under .agent-sandbox/worktrees/
    ├── mod.rs
    ├── create.rs           #   Worktree creation
    └── status.rs           #   Worktree status listing
```
