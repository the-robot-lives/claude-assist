# Project FAQ — database (group)

Group-level questions only: why this grouping directory exists, when to reach
for the group vs. a specific child tool, and what the delegating Makefile
does and doesn't do. Per-tool questions (provisioning, migrations, snapshots)
live in [database-utils/docs/PROJ-FAQ.md](../database-utils/docs/PROJ-FAQ.md)
— see its [summary](../database-utils/docs/PROJ-FAQ.summary.md) for the list.

## Motivation

### Why does `utilities/database/` exist as a separate directory instead of just having `database-utils/` directly under `utilities/`?

So a second database-engine toolkit (MongoDB, Elasticsearch, a future
managed-service CLI) has somewhere to land without a breaking rename or a
`utilities/` root that mixes single tools and multi-tool domains
inconsistently. Today it holds exactly one child, so in practice
`utilities/database/` and `database-utils/` are almost interchangeable — the
extra layer is a bet on future shape, not a present need. If that bet never
pays off, this directory is one child forever and the indirection is pure
overhead; that's an acceptable cost against the alternative of renaming/moving
things later once other code has hard-coded a path.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions) for the grouping-directory
rationale used repo-wide.*

### Why does this level have its own docs (ARCH/LAYOUT/HOWTO/FAQ) if it has no logic of its own?

Because "which tool do I want" and "how do I install the whole group" are
questions that don't belong to any one child — they're about the set. Putting
them at the group level means a future second child only needs to add a row
to an existing table, not create a new place for cross-tool questions to live.
The trade-off: today, with one child, most group-level answers are thin
wrappers that immediately point at `database-utils/` — read that impression
as "correctly proportioned to one child," not "over-documented."

## Fit

### Should I read this FAQ or `database-utils/docs/PROJ-FAQ.md` first?

Read this one first only if your question is "which tool" or "how do I set up
this whole group" — otherwise skip straight to
[database-utils/docs/PROJ-FAQ.md](../database-utils/docs/PROJ-FAQ.md), which
is where almost every concrete "why does `provision-db` do X" or "what
happens if Y" question actually gets answered. This group level intentionally
does not re-answer child-level questions.

### If I'm adding support for a new database engine, should it be a new child directory here or a new command inside `database-utils/`?

A new child directory, if the engine is genuinely different from Postgres/TimescaleDB/Valkey (e.g. MongoDB, Elasticsearch) — `database-utils/` is scoped and documented around that stack, and bolting on an unrelated engine's CLI/config/SQL templates would blur its own `PROJ-ARCH.md`/`PROJ-LAYOUT.md` rather than extend them cleanly. If instead you're adding another operation *for the same engines* (another Postgres/Valkey task), it belongs inside `database-utils/` as a new command, not a new child — a child directory per command would fragment install/docs for no benefit. When genuinely unsure, the cheaper mistake is adding it to `database-utils/` first; splitting a command out into its own child later is easier than merging two children back together.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-database-utility-to-this-group) for the mechanical steps once you've decided.*

### Is `make install` from `utilities/database/` different from running `make install` inside `database-utils/` directly?

No — functionally identical today. `utilities/database/Makefile` fans out to
`SUBDIRS := database-utils` via the shared `../mk/subdirs.mk` include, so
running it at the group root installs the same tools the same way. The group
entry point exists so that adding a second child later doesn't change the
command you run; use whichever level matches your mental model.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-everything-in-this-group).*

## Comparison

### If I add a second database toolkit here, will it share tools/config with `database-utils`, or is each child fully independent?

Each child is fully independent — its own `Makefile`, own `docs/`, own
install target — the group only aggregates the `make install` fan-out. Shared
plumbing (the `share/k8-lib` shell library, `.infra-config.yaml` targets, the
dc → Infisical → K8s Secrets credential flow) is inherited by convention
because every monorepo utility uses it, not because this grouping directory
enforces or provides it. A new child that ignored those conventions would
still install fine; it just wouldn't fit the rest of the repo.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*

## Caveats

### If `make install-utilities` fails partway through this group, do I know which child broke?

Only as well as the child's own Makefile output tells you — `mk/subdirs.mk`
fans out sequentially and doesn't add its own per-child error wrapping today.
With one child (`database-utils`) this is moot; once a second child exists,
a failure will surface as that child's own `make install` error output,
not a group-level summary. Re-run `cd utilities/database/<child> && make
install` directly to isolate it.

### Does this group-level Makefile do anything besides `install`?

Whatever targets `../mk/subdirs.mk` and the child Makefiles expose fan through
the same way `install` does — this doc only calls out `install` because it's
the one anyone actually runs. Don't assume group-level parity with every
child target without checking the child's own `Makefile`.

→ *See [database-utils/docs/PROJ-HOWTO.md](../database-utils/docs/PROJ-HOWTO.md)
for what the child's `Makefile` actually exposes.*
