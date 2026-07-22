# Project Layout — Summary (utilities/)

Top-level grouping directory for all DevOps utilities. Ten child groups/packages,
each with its own Makefile and docs (`<child>/docs/PROJ-LAYOUT.summary.md`).
`make install` fans out to children (skips `osx/` — SUBDIRS_NO_OSX); generic
targets dispatch via `mk/subdirs.mk`.

```
utilities/
├── agent/                      # Agent tooling (claude-assist, dangerously-safe, media-tool, ...)
├── colo/                       # Colo host helpers + deploy relay
├── database/                   # DB CLIs (liquibase-shell, provision-db, tsdb-snapshot)
├── k8/                         # k8s deploy pipeline (docker/helm/infra/secret utils + k8-lib)
├── linux/                      # Linux desktop utils (queue-populator, Rust)
├── mk/                         # Shared subdirs.mk Make dispatch + check-subdirs.sh
├── osx/                        # macOS-only utils (fstab, Swift queue-populator)
├── shell/                      # Shell/terminal utils (dc, secret-bucket, repo-lock, zellij, ...)
├── start-app-scaffold/         # start-app project scaffolding (bin/ + lib/)
├── terraform/                  # tf-plan-all + migrate-tfstate
├── docs/                       # PROJ-LAYOUT.md + this summary
├── push-3rd-party-images.sh    # Build/mirror 3rd-party images → ops.noizu.com
├── Makefile                    # SUBDIRS fan-out; includes mk/subdirs.mk
├── .envrc                      # direnv — source_up
└── .gitignore
```

Child docs: [agent](../agent/docs/PROJ-LAYOUT.summary.md) · [colo](../colo/docs/PROJ-LAYOUT.summary.md) · [database](../database/docs/PROJ-LAYOUT.summary.md) · [k8](../k8/docs/PROJ-LAYOUT.summary.md) · [linux](../linux/docs/PROJ-LAYOUT.summary.md) · [mk](../mk/docs/PROJ-LAYOUT.summary.md) · [osx](../osx/docs/PROJ-LAYOUT.summary.md) · [shell](../shell/docs/PROJ-LAYOUT.summary.md) · [start-app-scaffold](../start-app-scaffold/docs/PROJ-LAYOUT.summary.md) · [terraform](../terraform/docs/PROJ-LAYOUT.summary.md)
