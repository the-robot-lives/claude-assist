# Apache AGE — live verification runbook

Everything the AGE projection layer needs (ADR-013) that **cannot** run against the shared dev/CI
Postgres — that image is AGELESS (`postgis/postgis` in CI; Alpine TimescaleDB in the shared dev
stack), so Liquibase `031-age-graph` and every `:age`-tagged test are skipped there. This runbook
stands up a disposable AGE-capable database (the production image) and runs all of it in one shot.

## Prerequisites

- **Docker access.** The daemon is up, but the shell user must be able to reach its socket — either
  in the `docker` group (`sudo usermod -aG docker "$USER"`, then re-login) or invoke via `sudo`.
- **mix toolchain on the host** (asdf, see `app/.tool-versions`). `mix deps.get` needs hex access on
  a fresh checkout; on an already-built checkout it is a no-op.
- Nothing else: the script provisions its own Postgres, port, and volume.

## One command

```bash
cd app
scripts/verify-age-stack.sh          # full verification, tears the stack down on success
scripts/verify-age-stack.sh --keep   # ... but leave the DB running for the full Phase-C benchmark
scripts/verify-age-stack.sh --down    # tear the verify stack down and exit
```

On failure the stack is left running for inspection; remove it with `--down`.

## What it stands up

`docker-compose.age-verify.yaml` — an isolated compose project (`-p trr-age-verify`, its own
`_default` network and `trr_age_verify_pgdata` volume, host port **5499**) with two services:

- `age-verify-db` — the **production** DB image
  `docker.io/noizu/timescaledb-ha-with-age:pg17.9-ts2.25.2-all-age1.7.0-r2`, which ships **AGE
  1.7.0** plus pgvector / pg_trgm / cube / citext / uuid-ossp / earthdistance. Database
  `trr_verify_test`, superuser `trr_verify` (needed for `CREATE EXTENSION age`).
- `age-verify-migrations` — the repo's own Liquibase image (`backend/db/Dockerfile`), pointed at the
  verify DB via `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD`.

It is a **separate compose project** from the dev stack, so it cannot touch dev containers, networks
(`lets-go_default`), or volumes.

## What each stage proves

| Stage | Proves |
|-------|--------|
| `db-up` / `db-ready` | the AGE image boots and accepts connections on 5499 |
| `liquibase` | changelog **000..031** applies cleanly — incl. `CREATE EXTENSION age`, `create_graph('trr_memory')`, all vertex/edge labels and the pre-load indexes |
| `age-roundtrip` | the `age` extension is installed and `ag_catalog.ag_graph` has `trr_memory` (i.e. AGE loads and the graph is queryable) |
| `mix-test-age` | `mix test --include age` — the full suite **plus** the live `:age` suites: `GraphMirrorAgeTest` (vertex MERGE round-trip) and `GraphBenchAgeTest` (CTE/AGE overlap + `run/1` percentile stats) |
| `bench-smoke` | `mix trr.bench.graph` seeds a tiny synthetic graph, runs both traversals, prints the comparison table, and cleans up |

## Database wiring (why the DB name looks doubled)

`backend/config/test.exs` derives the Ecto database as `"${DB_NAME}_test"`. The physical database is
`trr_verify_test`, so:

- **Liquibase** is given `DB_NAME=trr_verify_test` (the real database), password via **`DB_PASSWORD`**.
- **mix** is given `DB_NAME=trr_verify` (Ecto appends `_test` → `trr_verify_test`), password via
  **`DB_PASS`**, and runs under `MIX_ENV=test` (so Oban is `testing: :inline` and no `oban_jobs`
  table is required at boot). `AGE_GRAPH_ENABLED=true` turns on `Repo.AGE.after_connect/1`.

The `:age` tests use the Ecto Sandbox; the AGE graph lives in its own `trr_memory` schema, so
`TestSchema.ensure_memory_schema!` (which drop/recreates the *public* memory tables each run) leaves
it intact.

## Full Phase-C benchmark (ADR-013 promotion decision)

Run with `--keep`, then drive the harness against the retained DB:

```bash
cd app && scripts/verify-age-stack.sh --keep
cd backend
DB_HOST=localhost DB_PORT=5499 DB_USER=trr_verify DB_PASS=trr_verify_pw DB_NAME=trr_verify \
  AGE_GRAPH_ENABLED=true MIX_ENV=test \
  mix trr.bench.graph --scale-sweep --queries 50 --seed-size 40
# single point:
#   ... mix trr.bench.graph --nodes 100000 --edges 500000 --queries 50 --seed-size 40
```

Paste the printed p50/p95/p99 into the **Phase C — Benchmark** table in
`docs/adrs/ADR-013-apache-age-projection-layer.md` and set the promotion decision:
**promote AGE onto the recall hot path iff its p99 stays < 1 s at both ≥100k and ≥1M edges**;
otherwise recall stays on the CTE and AGE remains the projection.

Tear down when finished: `scripts/verify-age-stack.sh --down`.

## Overrides

The script honors `VERIFY_DB_USER`, `VERIFY_DB_PASSWORD`, `VERIFY_DB_NAME` (must keep the `_test`
suffix), and `VERIFY_DB_PORT` from the environment; defaults are `trr_verify` / `trr_verify_pw` /
`trr_verify_test` / `5499`.

## Notes / assumptions not verifiable without Docker access

- **Image internals.** The exact `PGDATA` path is assumed to be the TimescaleDB-HA default
  (`/home/postgres/pgdata`); if a future image tag changes it, the named volume just won't persist
  (correctness is unaffected — the flow is idempotent from empty). That the image honors
  `POSTGRES_USER/PASSWORD/DB` and creates the user as a superuser follows the official-entrypoint
  convention TimescaleDB-HA builds on, but has not been run here.
- **Extension coverage.** `000-extensions.yaml` needs citext, uuid-ossp, vector, cube, pg_trgm,
  earthdistance (postgis was removed); the `-all` image is expected to carry them. If any is missing
  the `liquibase` stage fails loudly with the offending `CREATE EXTENSION`.
- **Full suite dependencies.** `mix test --include age` runs the *entire* suite. If any non-AGE test
  needs a service this script does not provide (e.g. Redis), add it or scope the command — the AGE
  coverage itself only needs Postgres.
