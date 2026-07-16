# Project Layout — utilities/shell

Grouping directory for shell and terminal utilities in the Noizu Infra monorepo.
Each child folder is a self-contained utility with its own Makefile and docs.
This document maps the group; **child internals are documented in each child's
own `docs/` folder** — follow the links rather than expecting detail here.

```
shell/
├── auto-sudo/                  # Rust CLI + zsh loader: rule-based automatic sudo elevation
│   └── docs/                   #   → auto-sudo/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── direnv-config/              # `dc` Rust CLI: layered direnv/.envrc secret & config store, multi-language SDKs
│   └── docs/                   #   → direnv-config/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── github-utils/               # Shell tools for GitHub workflows (submodule-commit)
│   └── docs/                   #   → github-utils/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── make-repo/                  # Create/edit (make-repo) and fork (fork-repo) GitHub repos
│   └── docs/                   #   → make-repo/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── misc-git-utils/             # Small git helpers (gcap, gp, submodule-*) + Rust doc-pointers tool
│   └── docs/                   #   → misc-git-utils/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── quick-gist/                 # Bash CLI for creating GitHub gists quickly
│   └── docs/                   #   → quick-gist/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── remote-tunnel/              # Reverse SSH (autossh) + ngrok TCP tunnel scripts for NAT'd machines
│   └── docs/                   #   → remote-tunnel/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── repo-lock/                  # Rust CLI: advisory session locks + git commit mutex for shared repos
│   └── docs/                   #   → repo-lock/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── secret-bucket/              # Rust CLI: agent-safe secret list/diff/copy across stores (no value output)
│   └── docs/                   #   → secret-bucket/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── tabbing-on/                 # Terminal tab theming/session toolkit — Rust impl + pure-shell impl + Ink prototype
│   └── docs/                   #   → tabbing-on/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── zellij/                     # Zellij launchers (zj-claude, zj-codex, zj-panes, zj-tab, zj-spawn) + KDL layouts
│   └── docs/                   #   → zellij/docs/PROJ-LAYOUT.summary.md, PROJ-ARCH.summary.md
├── docs/                       # This grouping directory's documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion summary
├── .envrc                      # direnv — `source_up` (inherits parent environment)
└── Makefile                    # Delegates to children via ../mk/subdirs.mk (SUBDIRS list)
```

## Child Utilities

| Utility | Language | Purpose |
|---------|----------|---------|
| [auto-sudo](../auto-sudo/docs/PROJ-LAYOUT.summary.md) | Rust + zsh | Rule-based automatic sudo elevation for configured commands |
| [direnv-config](../direnv-config/docs/PROJ-LAYOUT.summary.md) | Rust (+SDKs) | `dc` — layered secret/config store over `.envrc*` files; Elixir/PHP/Python/Rust/TS SDKs |
| [github-utils](../github-utils/docs/PROJ-LAYOUT.summary.md) | Bash | GitHub workflow helpers (bulk submodule commit/push) |
| [make-repo](../make-repo/docs/PROJ-LAYOUT.summary.md) | Bash | Create, edit, and fork GitHub repos with remote configuration |
| [misc-git-utils](../misc-git-utils/docs/PROJ-LAYOUT.summary.md) | Bash + Rust | git shortcuts (gcap, gp, submodule-pull/diff) and doc-pointers scanner |
| [quick-gist](../quick-gist/docs/PROJ-LAYOUT.summary.md) | Bash | Quick GitHub gist creation CLI |
| [remote-tunnel](../remote-tunnel/docs/PROJ-LAYOUT.summary.md) | Bash | autossh reverse tunnels + ngrok TCP tunnels for machines behind NAT |
| [repo-lock](../repo-lock/docs/PROJ-LAYOUT.summary.md) | Rust | Advisory session locks and git commit mutex for concurrent agent sessions |
| [secret-bucket](../secret-bucket/docs/PROJ-LAYOUT.summary.md) | Rust | Policy-gated secret list/diff/copy between stores without printing values |
| [tabbing-on](../tabbing-on/docs/PROJ-LAYOUT.summary.md) | Rust + POSIX sh | Terminal tab theming/session toolkit; dual implementation plus Ink TUI prototype |
| [zellij](../zellij/docs/PROJ-LAYOUT.summary.md) | Bash + KDL | Zellij session/tab launchers and claude-dev layout |

Each child also ships `docs/PROJ-ARCH.summary.md` (architecture summary) alongside its layout docs.

## Key Files

| File | Notes |
|------|-------|
| `Makefile` | `SUBDIRS` drives group-wide targets (install, etc.) via shared `../mk/subdirs.mk`; `SUBDIR_PREFIX := shell/` |
| `.envrc` | `source_up` only — pulls in the parent `utilities/` direnv environment |

## Maintenance

- Adding a utility: create the child folder with its own `Makefile` + `docs/`, then append it to `SUBDIRS` in this directory's `Makefile` and add a row here and in the summary.
- Do not document child internals here — update the child's own `docs/PROJ-LAYOUT.md` instead.
