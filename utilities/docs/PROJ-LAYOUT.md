# Project Layout — utilities/

Top-level grouping directory for all Noizu Infra DevOps utilities. Every child
is a *grouping directory* (agent, shell, k8, ...) or a self-contained package
(start-app-scaffold) with its own `Makefile`, `docs/PROJ-LAYOUT.summary.md`,
and (usually) `docs/PROJ-ARCH.summary.md`. This document maps only the
top level; child internals are documented in each child's own docs.

Install everything with `make install` (or `make install-utilities` from the
repo root) — fans out to each group's `install` target, skipping `osx/` on
non-macOS hosts (`SUBDIRS_NO_OSX`). Generic targets (`build`, `compile`,
`test`, `clean`) dispatch recursively via `mk/subdirs.mk`.

```
utilities/
├── agent/                      # Agent-centric tools (claude-assist, dangerously-safe,
│                               #   media-tool, mallm, run-claude, skill-manage, ...)
│                               #   → agent/docs/PROJ-LAYOUT.summary.md
├── colo/                       # Colocation/cluster host helpers (colo-utils, deploy relay)
│                               #   → colo/docs/PROJ-LAYOUT.summary.md
├── database/                   # DB DevOps (database-utils: liquibase-shell, provision-db,
│                               #   tsdb-snapshot) → database/docs/PROJ-LAYOUT.summary.md
├── k8/                         # k8s DevOps: cluster/docker/helm/infra/secret/staging utils
│                               #   + shared k8-lib → k8/docs/PROJ-LAYOUT.summary.md
├── linux/                      # Linux-only desktop utils (queue-populator, Rust)
│                               #   → linux/docs/PROJ-LAYOUT.summary.md
├── mk/                         # Shared Make plumbing: subdirs.mk recursive dispatch
│                               #   + check-subdirs.sh → mk/docs/PROJ-LAYOUT.summary.md
├── osx/                        # macOS-only utils (fstab LaunchDaemon, Swift queue-populator)
│                               #   → osx/docs/PROJ-LAYOUT.summary.md
├── shell/                      # Shell/terminal utils (direnv-config, secret-bucket,
│                               #   repo-lock, zellij, tabbing-on, ...)
│                               #   → shell/docs/PROJ-LAYOUT.summary.md
├── start-app-scaffold/         # Project scaffolding package (bin/ + lib/, not a grouping dir)
│                               #   → start-app-scaffold/docs/PROJ-LAYOUT.summary.md
├── terraform/                  # Terraform utils (tf-plan-all, migrate-tfstate)
│                               #   → terraform/docs/PROJ-LAYOUT.summary.md
├── docs/                       # This grouping directory's docs
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Synced tree summary
├── push-3rd-party-images.sh    # Build/mirror 3rd-party Docker images → ops.noizu.com
├── Makefile                    # SUBDIRS fan-out (install skips osx); includes mk/subdirs.mk
├── .envrc                      # direnv — `source_up` to inherit repo-root env
└── .gitignore                  # Local-only files (.env*, editor swap, .DS_Store)
```

## Group Index

| Group | Focus | Child docs |
|-------|-------|------------|
| `agent/` | AI-agent tooling: sandboxes, transcript indexer, media generation, skill management | [layout](../agent/docs/PROJ-LAYOUT.summary.md) · [arch](../agent/docs/PROJ-ARCH.summary.md) |
| `colo/` | Colo host / cluster dashboards + deploy relay systemd units | [layout](../colo/docs/PROJ-LAYOUT.summary.md) · [arch](../colo/docs/PROJ-ARCH.summary.md) |
| `database/` | K8s Postgres/TimescaleDB/Valkey CLIs, Liquibase runners | [layout](../database/docs/PROJ-LAYOUT.summary.md) · [arch](../database/docs/PROJ-ARCH.summary.md) |
| `k8/` | Core k8s deploy pipeline: docker-build/push, helm-upgrade, deploy-service, k8-lib | [layout](../k8/docs/PROJ-LAYOUT.summary.md) · [arch](../k8/docs/PROJ-ARCH.summary.md) |
| `linux/` | Linux desktop: voice-memo + PipeWire virtual-mic (Rust) | [layout](../linux/docs/PROJ-LAYOUT.summary.md) · [arch](../linux/docs/PROJ-ARCH.summary.md) |
| `mk/` | Shared `subdirs.mk` recursive Make dispatch used by every group | [layout](../mk/docs/PROJ-LAYOUT.summary.md) · [arch](../mk/docs/PROJ-ARCH.summary.md) |
| `osx/` | macOS-only: fstab LaunchDaemon, Swift menu-bar queue-populator | [layout](../osx/docs/PROJ-LAYOUT.summary.md) · [arch](../osx/docs/PROJ-ARCH.summary.md) |
| `shell/` | Terminal/shell QoL + secret tooling (dc, secret-bucket, repo-lock, ...) | [layout](../shell/docs/PROJ-LAYOUT.summary.md) · [arch](../shell/docs/PROJ-ARCH.summary.md) |
| `start-app-scaffold/` | start-app template scaffolding + LLM-assisted merge | [layout](../start-app-scaffold/docs/PROJ-LAYOUT.summary.md) · [arch](../start-app-scaffold/docs/PROJ-ARCH.summary.md) |
| `terraform/` | Terragrunt/OpenTofu helpers (tf-plan-all, migrate-tfstate) | [layout](../terraform/docs/PROJ-LAYOUT.summary.md) · [arch](../terraform/docs/PROJ-ARCH.summary.md) |

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.envrc` | Run `direnv allow` (inherits repo-root env via `source_up`) |
| `push-3rd-party-images.sh` | Optionally set `REPOS_3RD_DIR`, `DOCKER_BUILDER`, `DOCKER_PLATFORMS` env vars |

## Conventions

- New utility groups must be added to `SUBDIRS` in the top-level `Makefile`;
  `mk/check-subdirs.sh` verifies SUBDIRS vs on-disk Makefiles stay consistent.
- Each group's Makefile delegates to its children via `../mk/subdirs.mk`.
- Installed tools land in `~/.local/bin`; shared shell libs in `~/.local/share/`.
