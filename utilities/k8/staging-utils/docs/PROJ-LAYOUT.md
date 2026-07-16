# Project Layout

`staging-utils` is a terminal utility package for staging environment lifecycle management (deploy, teardown, logs, status) on the Noizu k8s cluster. Tools install to `~/.local/bin` via `make install` and load configuration from `infra-config.yaml` through the shared k8-lib config chain (`~/.local/share/k8-lib`).

```
staging-utils/
├── bin/                        # Executable staging-* tools (bash)
│   ├── staging-up              #   Deploy all staging services — delegates to `helm-upgrade --env stage --force`
│   ├── staging-down            #   Uninstall all Helm releases in the staging namespace
│   ├── staging-logs            #   Tail logs for a staging service (frontend default; any service by name)
│   └── staging-status          #   Dashboard: pods, Helm releases, KEDA ScaledObjects, resource usage
├── docs/                       # Documentation
│   ├── PROJ-ARCH.md            #   Architecture: config chain, tool internals, KEDA notes
│   ├── PROJ-ARCH.summary.md    #   Condensed architecture reference
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Condensed tree for tools/agents
├── .gitignore                  # Ignores editor swap files, .env, .envrc.local
├── Makefile                    # `make install` → installs bin/staging-* to ~/.local/bin (compile/test are no-ops)
└── README.md                   # Start here — install, prerequisites, config table, usage
```

## Notes

- **No `lib/`**: shared logic lives externally in `k8-lib` (`~/.local/share/k8-lib`), sourced by each tool at runtime; `K8_LIB_DIR` overrides the location.
- All tools accept `--config <path>` (pre-parsed into `K8_CONFIG` before k8-lib sourcing) and support `--assist` AI help via k8-lib's `assist.sh`.
- Key config: `.kubernetes.staging_namespace` (env `K8_STAGING_NAMESPACE`, default `staging`) and `.kubernetes.app_prefix` (env `K8_APP_PREFIX`, default `app`).
- Runtime prerequisites: `kubectl`, `helm`, and `helm-upgrade` from the sibling `helm-tools` package (required by `staging-up`).

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `infra-config.yaml` (repo root) | Provides staging namespace / app prefix; override per-call with `--config <path>` |
| `~/.local/share/k8-lib` | Install shared lib first (`make install-utilities` at repo root) |
