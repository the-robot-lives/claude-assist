# Project Layout — start-app-scaffold

Terminal utility package for scaffolding new portfolio projects from the
`components/start-app` Elixir template in the Noizu Infra monorepo. Tools run
both in-repo (`utilities/start-app-scaffold/bin/*`) and installed standalone
to `~/.local/bin` via `make install` (shared lib goes to
`~/.local/share/start-app-scaffold`).

```
start-app-scaffold/
├── bin/                          # Executable tools (installed to ~/.local/bin)
│   ├── init-proj-scaffold        #   Create a new portfolio project from the start-app template (project_dir/slug/module args; --target, --helm/--no-helm)
│   ├── start-app-scaffold        #   Scaffold + provision a start-app instance; writes .start-app-provision artifacts; --execute applies Postgres/Valkey steps
│   ├── llm-merge-start-app       #   Stage a fresh scaffold with inferred project identity and hand the merge to an LLM coding agent (LLM_MERGE_AGENT_CMD)
│   └── build-start-app-tarball   #   Rebuild components/start-app/start-app.tar.gz when template sources are newer (-f to force)
├── lib/                          # Shared shell library (installed to ~/.local/share/start-app-scaffold)
│   └── repo-root.sh              #   Repo-root resolver: $INFRA_ROOT → script-dir walk-up → $PWD walk-up; never falls back to "/"
├── docs/                         # Documentation
│   ├── PROJ-LAYOUT.md            #   This file
│   └── PROJ-LAYOUT.summary.md    #   Tree-only companion for tools/agents
└── Makefile                      # compile (no-op) / test (bash -n syntax checks) / install targets
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `Makefile` | Run `make install` to install tools; override `INSTALL_DIR` / `LIB_INSTALL_DIR` if needed |
| `lib/repo-root.sh` | Installed copies rely on `$INFRA_ROOT` or `$STARTAPP_LIB_DIR` when run outside the monorepo |

## Notes

- All four `bin/` scripts source `lib/repo-root.sh` (relative path in-repo,
  `$STARTAPP_LIB_DIR` / `~/.local/share/start-app-scaffold` when installed).
- The scaffold template itself lives outside this package at
  `components/start-app/` in the monorepo root.
