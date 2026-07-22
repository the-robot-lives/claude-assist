# Project Layout

Grouping directory for database-related DevOps utilities in the Noizu Infra
monorepo. It holds no tooling of its own beyond a delegating Makefile; each
child folder is a self-documented utility package with its own `docs/`.

```
database/
├── database-utils/             # CLI tools + SQL templates for K8s Postgres/TimescaleDB/Valkey
│   ├── bin/                    #   liquibase-shell, liquibase-update, provision-db, tsdb-snapshot, SQL templates
│   ├── docs/                   #   Child docs — see links below
│   ├── Makefile                #   make install → ~/.local/bin
│   └── README.md               #   Install, prerequisites, configuration
├── docs/                       # This grouping directory's docs
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion
└── Makefile                    # Delegates to child dirs via ../mk/subdirs.mk (SUBDIRS := database-utils)
```

## Child Utility Docs

Child internals are documented in each child's own `docs/` — reference those,
do not duplicate here:

| Child | Layout | Architecture |
|-------|--------|--------------|
| `database-utils/` | [PROJ-LAYOUT.summary.md](../database-utils/docs/PROJ-LAYOUT.summary.md) | [PROJ-ARCH.summary.md](../database-utils/docs/PROJ-ARCH.summary.md) |

`database-utils` in brief (from its summaries): config-driven CLI tools for
administering K8s-hosted PostgreSQL/TimescaleDB and Valkey — `liquibase-shell`
(port-forward Liquibase), `liquibase-update` (legacy in-cluster Job),
`provision-db` (DB/role + Valkey ACL provisioning), `tsdb-snapshot`
(app-consistent EBS snapshots) — plus PgBouncer/migration-role SQL templates.
It also carries `docs/liquibase-shell-spec.md`.

## Key Files Requiring Setup

None at this level. The grouping Makefile is driven by `utilities/mk/subdirs.mk`;
installation happens through repo-root `make install-utilities` or per-child
`make install`. Child-level configuration (`.infra-config.yaml` targets, dc
credentials) is documented in `database-utils/README.md`.
