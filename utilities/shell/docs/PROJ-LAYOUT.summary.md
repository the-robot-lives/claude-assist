# Project Layout — Summary (utilities/shell)

Grouping directory for shell/terminal utilities; each child is self-contained with its own Makefile and `docs/` (see each child's `PROJ-LAYOUT.summary.md` / `PROJ-ARCH.summary.md`).

```
shell/
├── auto-sudo/                  # Rust+zsh rule-based auto sudo elevation
├── direnv-config/              # dc CLI: layered direnv secret/config store + SDKs
├── github-utils/               # GitHub workflow shell helpers
├── make-repo/                  # make-repo / fork-repo GitHub repo tools
├── misc-git-utils/             # git shortcuts + doc-pointers (Rust)
├── quick-gist/                 # quick GitHub gist CLI
├── remote-tunnel/              # autossh reverse + ngrok TCP tunnels
├── repo-lock/                  # advisory session locks + git commit mutex (Rust)
├── secret-bucket/              # agent-safe secret list/diff/copy (Rust)
├── tabbing-on/                 # terminal tab theming toolkit (Rust + shell + Ink proto)
├── zellij/                     # zellij launchers (zj-*) + KDL layouts
├── docs/                       # PROJ-LAYOUT.md + this summary
├── .envrc                      # direnv — source_up
└── Makefile                    # delegates to children via ../mk/subdirs.mk
```
