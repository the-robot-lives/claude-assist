# Project Layout — utilities/terraform

Grouping directory for Terraform-related DevOps utilities. Each child folder is a
self-documented utility package with its own `docs/` — see the child summaries
linked below rather than re-reading internals here.

```
terraform/
├── terraform-utils/            # Terraform helper CLI package → see child docs
│   ├── bin/                    #   tf-plan-all, migrate-tfstate (→ ~/.local/bin)
│   ├── docs/                   #   PROJ-ARCH(.summary).md, PROJ-LAYOUT(.summary).md
│   ├── Makefile                #   make install (compile/test no-ops)
│   └── README.md               #   Install, config, usage
└── Makefile                    # Delegates targets to SUBDIRS via ../mk/subdirs.mk
```

## Children

| Utility | Purpose | Docs |
|---------|---------|------|
| `terraform-utils/` | Two Terraform helper scripts — `tf-plan-all` (batch plan + status table) and `migrate-tfstate` (local tfstate → S3 backend) — installed to `~/.local/bin`, built on the shared k8-lib shell library | [Layout](../terraform-utils/docs/PROJ-LAYOUT.summary.md) · [Architecture](../terraform-utils/docs/PROJ-ARCH.summary.md) |

## Grouping Makefile

`Makefile` declares `SUBDIRS := terraform-utils` with prefix `terraform/` and
includes `../mk/subdirs.mk`, which fans standard targets (install, etc.) out to
each listed child. Add new Terraform utilities by creating a sibling folder and
appending it to `SUBDIRS`.
