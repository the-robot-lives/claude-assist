# Changelog — utilities/colo

`utilities/colo` is a grouping directory: it hosts the `colo-utils` child package (own history in
`colo-utils/CHANGELOG.md`) plus group-level Makefile delegation and cross-tool docs. Entries here
track group-level history only — see `colo-utils/CHANGELOG.md` for tool-internal changes.

## [Unreleased]
### Added
- `docs/PROJ-HOWTO.md` + `docs/PROJ-HOWTO.summary.md` — group-level task guides (install across the group, tool discovery via child docs, adding a new colo package)

## [m2-npl-docs-alignment] — 2026-07-16 — tag: `utilities-colo/m2-npl-docs-alignment`
Milestone summary: added group-level `docs/PROJ-ARCH.md` and `docs/PROJ-LAYOUT.md` (+ summaries) at the `utilities/colo` root, aligning the grouping directory with the npl arch/layout doc convention used across sibling utilities.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — group-level architecture overview
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — group-level layout overview

## [m1-initial-group-scaffold] — 2026-06-14 — tag: `utilities-colo/m1-initial-group-scaffold`
Milestone summary: established `utilities/colo` as a grouping directory over the newly-imported `colo-utils` subtree (deploy-relay/colo-sync tooling plus the cluster inspection suite — see `colo-utils/CHANGELOG.md` for that history).

### Added
- Root `Makefile` — delegates to `colo-utils` via `../mk/subdirs.mk` (`SUBDIRS := colo-utils`)
