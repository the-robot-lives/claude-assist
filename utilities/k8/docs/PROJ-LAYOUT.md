# Project Layout — utilities/k8

Grouping directory for the Kubernetes DevOps utility packages of the Noizu
monorepo. Each child folder is a self-contained utility project with its own
`Makefile`, `README.md`, and docs; the top-level `Makefile` fans `build /
compile / test / install / clean` out to every child via the shared
`../mk/subdirs.mk` include (used by repo-root `make install-utilities`).

Child internals are documented in each child's own `docs/` — see the linked
`PROJ-LAYOUT.summary.md` / `PROJ-ARCH.summary.md` files; they are not
re-documented here.

```
k8/
├── cluster-utils/              # Cluster inspection dashboards (7 cluster-* bash tools:
│   │                           #   status, nodes, resources, helm, layout, manticore,
│   │                           #   setup-telemetry)
│   ├── bin/
│   └── docs/                   #   → cluster-utils/docs/PROJ-LAYOUT.summary.md
├── docker-utils/               # Docker build/push layer (docker-build, docker-push
│   │                           #   w/ Infisical patch versioning, docker-qemu11)
│   ├── bin/
│   └── docs/                   #   → docker-utils/docs/PROJ-LAYOUT.summary.md
├── helm-utils/                 # Helm chart lifecycle (helm-upgrade tiered w/ change
│   │                           #   detection, helm-rollback reverse-tier, helm-publish OCI)
│   ├── bin/
│   └── docs/                   #   → helm-utils/docs/PROJ-LAYOUT.summary.md
├── infra-utils/                # Infra orchestration CLIs (deploy-service pipeline,
│   │                           #   infra-config, infra-init, deploy-one-off,
│   │                           #   open-dashboard, add-import-permissions)
│   ├── bin/
│   └── docs/                   #   → infra-utils/docs/PROJ-LAYOUT.summary.md
├── k8-lib/                     # Shared sourced-shell library (18 modules) used by all
│   │                           #   sibling packages via $K8_LIB_DIR (~/.local/share/k8-lib)
│   ├── bin/
│   ├── docs/                   #   → k8-lib/docs/PROJ-LAYOUT.summary.md
│   └── infra-config.yaml.example   # Structural config template
├── secret-utils/               # Secrets management: Rust `infisical` CLI/TUI + 11
│   │                           #   legacy bash CLIs + hydrate-envrc
│   ├── bin/
│   ├── lib/                    #   secret-engine.sh (shared shell engine)
│   ├── rust/                   #   Rust crate (clap CLI + ratatui TUI)
│   ├── docs/                   #   → secret-utils/docs/PROJ-LAYOUT.summary.md
│   ├── envrc.dc.example        #   Credential template (.envrc.k8.dc)
│   └── secrets.yaml.example    #   Declarative secret-definitions template
├── staging-utils/              # Staging env lifecycle (staging-up/down/logs/status)
│   ├── bin/
│   └── docs/                   #   → staging-utils/docs/PROJ-LAYOUT.summary.md
├── docs/                       # This documentation
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
└── Makefile                    # Fan-out to SUBDIRS via ../mk/subdirs.mk
```

## Child Project Docs

| Package | Layout | Architecture |
|---------|--------|--------------|
| cluster-utils | [summary](../cluster-utils/docs/PROJ-LAYOUT.summary.md) · [full](../cluster-utils/docs/PROJ-LAYOUT.md) | [summary](../cluster-utils/docs/PROJ-ARCH.summary.md) |
| docker-utils | [summary](../docker-utils/docs/PROJ-LAYOUT.summary.md) · [full](../docker-utils/docs/PROJ-LAYOUT.md) | [summary](../docker-utils/docs/PROJ-ARCH.summary.md) |
| helm-utils | [summary](../helm-utils/docs/PROJ-LAYOUT.summary.md) · [full](../helm-utils/docs/PROJ-LAYOUT.md) | [summary](../helm-utils/docs/PROJ-ARCH.summary.md) |
| infra-utils | [summary](../infra-utils/docs/PROJ-LAYOUT.summary.md) · [full](../infra-utils/docs/PROJ-LAYOUT.md) | [summary](../infra-utils/docs/PROJ-ARCH.summary.md) |
| k8-lib | [summary](../k8-lib/docs/PROJ-LAYOUT.summary.md) · [full](../k8-lib/docs/PROJ-LAYOUT.md) | [summary](../k8-lib/docs/PROJ-ARCH.summary.md) |
| secret-utils | [summary](../secret-utils/docs/PROJ-LAYOUT.summary.md) · [full](../secret-utils/docs/PROJ-LAYOUT.md) | [summary](../secret-utils/docs/PROJ-ARCH.summary.md) |
| staging-utils | [summary](../staging-utils/docs/PROJ-LAYOUT.summary.md) · [full](../staging-utils/docs/PROJ-LAYOUT.md) | [summary](../staging-utils/docs/PROJ-ARCH.summary.md) |

## Conventions

- All bash executables install flat to `~/.local/bin` via each child's `make install`.
- Shared shell code lives only in `k8-lib` (installed to `~/.local/share/k8-lib`,
  overridable via `K8_LIB_DIR`); children carry no duplicated library code
  (exception: `secret-utils/lib/secret-engine.sh`, local to its legacy CLIs).
- Config source of truth: repo-root `.infra-config.yaml` (structural) +
  `.envrc.k8.dc` / `K8_*` env vars (scalars), resolved by k8-lib.
- `Makefile` here defines only `SUBDIRS`, `SUBDIR_PREFIX := k8/`, and a
  description; all target logic comes from `../mk/subdirs.mk` (build falls back
  to `compile` when a child defines only that).
