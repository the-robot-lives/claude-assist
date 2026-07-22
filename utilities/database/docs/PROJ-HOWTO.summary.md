# PROJ-HOWTO.summary — database (group)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full guides. Group
level covers cross-tool workflows only; per-tool tasks are in each child's own
summary (e.g. [database-utils/PROJ-HOWTO.summary.md](../database-utils/docs/PROJ-HOWTO.summary.md)).

- **Install everything in this group** — get all database-group CLI tools on
  your `$PATH` in one step via `make install-utilities` or `make install`.
- **Pick the right tool for a database task** — a lookup table mapping common
  intents (run a migration, provision a DB, snapshot a volume, set up
  PgBouncer auth) to the right child command.
- **Add a new database utility to this group** — wire a new self-documented
  child package into the group's `Makefile` fan-out and cross-link its docs.
