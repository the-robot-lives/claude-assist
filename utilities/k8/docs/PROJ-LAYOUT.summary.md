# Project Layout Summary — utilities/k8

Grouping directory: seven self-contained k8s DevOps utility packages, each with
its own Makefile/README/docs. Top-level Makefile fans targets out via
`../mk/subdirs.mk`. Child details → each child's `docs/PROJ-LAYOUT.summary.md`.

```
k8/
├── cluster-utils/              # cluster-* inspection dashboards (bash)
├── docker-utils/               # docker-build / docker-push / docker-qemu11
├── helm-utils/                 # helm-upgrade / helm-rollback / helm-publish
├── infra-utils/                # deploy-service, infra-config, infra-init, ...
├── k8-lib/                     # shared sourced-shell library (all siblings)
├── secret-utils/               # Rust infisical CLI/TUI + legacy bash CLIs
├── staging-utils/              # staging-up/down/logs/status
├── docs/                       # PROJ-LAYOUT.md + this summary
└── Makefile                    # SUBDIRS fan-out (../mk/subdirs.mk)
```
