# PROJ-FAQ.summary — database (group)

Question list only — see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers. Group
level covers cross-tool/grouping questions only; per-tool questions are in
each child's own summary (e.g.
[database-utils/PROJ-FAQ.summary.md](../database-utils/docs/PROJ-FAQ.summary.md)).

## Motivation
- Why does `utilities/database/` exist as a separate directory instead of
  just having `database-utils/` directly under `utilities/`?
- Why does this level have its own docs (ARCH/LAYOUT/HOWTO/FAQ) if it has no
  logic of its own?

## Fit
- If I'm adding support for a new database engine, should it be a new child
  directory here or a new command inside `database-utils/`?
- Should I read this FAQ or `database-utils/docs/PROJ-FAQ.md` first?
- Is `make install` from `utilities/database/` different from running `make
  install` inside `database-utils/` directly?

## Comparison
- If I add a second database toolkit here, will it share tools/config with
  `database-utils`, or is each child fully independent?

## Caveats
- If `make install-utilities` fails partway through this group, do I know
  which child broke?
- Does this group-level Makefile do anything besides `install`?
