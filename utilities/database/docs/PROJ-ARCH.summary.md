# Project Architecture Summary

Grouping directory for database-related DevOps utility packages in the Noizu
Infra monorepo. No logic of its own — a delegating Makefile
(`../mk/subdirs.mk`, `SUBDIRS := database-utils`) fans installation out to
child packages, which are each self-documented under their own `docs/`.

## Components

- **Makefile** — delegates to child dirs via shared `utilities/mk/subdirs.mk`
- **database-utils/** — config-driven CLI tools + SQL templates for K8s
  Postgres/TimescaleDB/Valkey: liquibase-shell, liquibase-update,
  provision-db, tsdb-snapshot (see `database-utils/docs/PROJ-ARCH.summary.md`)

## Ecosystem Fit

Installed via repo-root `make install-utilities` into `~/.local/bin`; child
tools source shared `share/k8-lib` and read targets from repo-root
`.infra-config.yaml` (`liquibase_targets`, `tsdb_snapshot_targets`), with
credentials via the dc → Infisical → K8s Secrets flow.

## Key Decisions

- Grouping-directory pattern: children stay independently installable/documented
- Shared `mk/subdirs.mk` include: new utilities are added by appending to SUBDIRS
- No logic or duplicated docs at this level
