# Project Layout — k8-lib

Shared shell library and config loaders for the k8 devops tool suites. Installed
to `~/.local/share/k8-lib` via `make install`; files are sourced by commands,
not invoked directly.

```
k8-lib/
├── bin/                        # Sourced shell modules → [layout/bin.md](layout/bin.md)
│   ├── common.sh               #   Config load + colour/output helpers (base include)
│   ├── config-resolver.sh      #   Unified config resolution (env → dc → YAML → default)
│   └── helm-common.sh          #   Shared defs for helm-upgrade / helm-rollback
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   ├── PROJ-LAYOUT.summary.md  #   Tree-only companion (keep in sync)
│   └── layout/                 #   Extracted per-directory breakdowns
├── .envrc.k8.dc.example        # Template: scalar config via direnv-config (dc)
├── .gitignore                  # Ignores swap files, .env, .envrc.local
├── Makefile                    # install / test (bash -n syntax check) targets
├── README.md                   # Start here — install, config layers, resolution order
└── infra-config.yaml.example   # Template: structural config (tiers, paths, namespaces)
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `infra-config.yaml` | Copy from `infra-config.yaml.example` to project root, customize |
| `.envrc.k8.dc` | Copy from `.envrc.k8.dc.example`, source from `.envrc` |

## Notes

- `make install` copies `bin/*.sh` and both `.example` templates to `~/.local/share/k8-lib`.
- Scalar values resolve: env var → `dc get k8 <path>` → YAML fallback → hardcoded default.
- `infra-config.yaml` resolves: `--config` → `$K8_CONFIG` → `$INFRA_ROOT/` → git-root walk → `$K8_LIB_DIR/`.
- All paths inside `infra-config.yaml` are relative to the config file's directory.
