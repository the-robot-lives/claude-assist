# Changelog — utilities/database

Group-level history only. Child-tool internals (added tools, fixes, features)
are documented in each child's own changelog — see
`database-utils/CHANGELOG.md`.

## [Unreleased]
- (none)

## [m2-arch-docs] — 2026-07-16 — tag: `utilities-database/m2-arch-docs`
Group root gained its own `docs/PROJ-ARCH.md` + `PROJ-LAYOUT.md` (with
`.summary.md` companions), documenting the grouping-directory pattern itself
(delegating Makefile, child self-documentation) separate from
`database-utils`' own architecture docs, which were expanded in the same
commit.

### Added
- `docs/PROJ-ARCH.md`, `docs/PROJ-ARCH.summary.md` — group role: no logic of
  its own, fans install out to child packages via shared `mk/subdirs.mk`
- `docs/PROJ-LAYOUT.md`, `docs/PROJ-LAYOUT.summary.md`

## [m1-initial-grouping] — 2026-06-14 — tag: `utilities-database/m1-initial-grouping`
Established `utilities/database` as a grouping directory: the `database-utils`
toolkit landed via subtree merge, then a delegating root `Makefile` was added
so `make install-utilities` fans out to it.

### Added
- `database-utils/` subtree merge — initial toolkit import (see child
  changelog `m1-initial-import` for full contents: liquibase-shell,
  liquibase-update, tsdb-snapshot, SQL templates)
- Root `Makefile` — delegates to `SUBDIRS := database-utils` via shared
  `../mk/subdirs.mk`
