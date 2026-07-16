# Project Layout — Summary

Grouping directory for database DevOps utilities; one child package.

```
database/
├── database-utils/             # K8s Postgres/TimescaleDB/Valkey CLI tools → database-utils/docs/PROJ-LAYOUT.summary.md
│   ├── bin/                    #   liquibase-shell, liquibase-update, provision-db, tsdb-snapshot, SQL templates
│   ├── docs/                   #   Child PROJ-ARCH/PROJ-LAYOUT (+ summaries), liquibase-shell-spec.md
│   ├── Makefile                #   make install → ~/.local/bin
│   └── README.md               #   Install + configuration
├── docs/                       # This grouping directory's docs
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
└── Makefile                    # Delegates to children via ../mk/subdirs.mk
```
