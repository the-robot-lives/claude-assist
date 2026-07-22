# Project How-To

Group-level guides only: cross-tool workflows and "which tool do I want"
questions for `utilities/database/`. For a specific tool's own tasks (running
migrations, provisioning a DB, taking a snapshot), see the child's own
`PROJ-HOWTO.md` linked below — do not re-derive those steps here.

## How to: install everything in this group

**Goal:** get all database-group CLI tools (`liquibase-shell`,
`liquibase-update`, `provision-db`, `tsdb-snapshot`) on your `$PATH` in one
step.
**Prereqs:** see each tool's own prereqs in
[database-utils/PROJ-HOWTO.md](../database-utils/docs/PROJ-HOWTO.md#how-to-install-the-tools)
(`kubectl`, `yq`, `liquibase`, `psql`/`mysql`, `dc`+`redis-cli`).

1. From the repo root:
   ```bash
   make install-utilities
   ```
   This recurses into `utilities/database/Makefile`, which fans out to
   `SUBDIRS := database-utils` via `../mk/subdirs.mk`.
2. Or install just this group's children directly:
   ```bash
   cd utilities/database && make install
   ```

**Verify:**
```bash
which liquibase-shell liquibase-update provision-db tsdb-snapshot
```
**Gotchas:**
- There is currently one child (`database-utils/`) — installing "the group"
  and installing that one child are the same operation today. The delegating
  Makefile exists so a future second child (e.g. a MongoDB or Elasticsearch
  toolkit) installs the same way without changing the top-level command.
- If `make install-utilities` fails partway through this group, `mk/subdirs.mk`
  doesn't add its own per-child error wrapping — you only get that child's own
  `make install` output. Isolate which child broke by re-running it directly:
  ```bash
  cd utilities/database/database-utils && make install
  ```

## How to: pick the right tool for a database task

**Goal:** know which command to reach for without reading every child's docs.

| I want to... | Use |
|---|---|
| Run/preview a Liquibase migration interactively, or get a live psql/mysql shell | `liquibase-shell <target>` — see [child guide](../database-utils/docs/PROJ-HOWTO.md#how-to-open-a-liquibase-shell-against-a-cluster-database) |
| Apply a Liquibase changelog from CI / non-interactively via a K8s Job | `liquibase-update <target>` — see [child guide](../database-utils/docs/PROJ-HOWTO.md#how-to-run-the-legacy-one-shot-liquibase-update-job) |
| Create a DB + role (and optional Valkey ACL user) for a new app on an already-running instance | `provision-db` — see [howto/provision-db.md](../database-utils/docs/howto/provision-db.md) |
| Take an app-consistent EBS snapshot of a TimescaleDB volume | `tsdb-snapshot --config <target>` — see [child guide](../database-utils/docs/PROJ-HOWTO.md#how-to-take-an-application-consistent-timescaledb-snapshot) |
| Stand up PgBouncer auth or a migration role for a project not yet wired into `provision-db` | copy/customize the SQL templates — see [child guide](../database-utils/docs/PROJ-HOWTO.md#how-to-use-the-sql-templates-for-a-new-project) |

**Gotchas:**
- `liquibase-shell` vs `liquibase-update`: both run the same migrations against
  the same `liquibase_targets` config, but `liquibase-shell` is the
  interactive/one-shot path (prefer this); `liquibase-update` is the legacy
  in-cluster-Job path, kept for CI callers built around it.
- All targets/config for every child here live in the repo-root
  `.infra-config.yaml` (`liquibase_targets`, `tsdb_snapshot_targets`), not in
  per-tool flags — see [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).

## How to: add a new database utility to this group

**Goal:** wire a new child tool package (e.g. a second database engine's
toolkit) into the group's install fan-out.
**Prereqs:** the new tool lives in its own subdirectory here with its own
`Makefile` exposing an `install` target, plus its own `docs/` (PROJ-ARCH,
PROJ-LAYOUT, PROJ-HOWTO — self-documented per the same convention as
`database-utils/`).

1. Add the new directory name to `SUBDIRS` in `utilities/database/Makefile`:
   ```makefile
   SUBDIRS := database-utils your-new-tool
   ```
2. Confirm it installs via the group fan-out:
   ```bash
   cd utilities/database && make install
   ```
3. Update `docs/PROJ-ARCH.md` and `docs/PROJ-LAYOUT.md` (group level) to list
   the new child in their component/tree tables, and add a "which tool" row
   above if it overlaps an existing task.

**Verify:** `make install` from this directory installs both children without
error; `which <new-tool-binary>` resolves.
**Gotchas:** don't duplicate the new child's own internal docs at this
group level — link its `PROJ-ARCH.summary.md`/`PROJ-LAYOUT.summary.md`, the
same pattern used for `database-utils/`.
