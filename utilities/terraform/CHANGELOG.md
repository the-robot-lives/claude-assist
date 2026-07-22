# Changelog — utilities/terraform

Group-level changelog. This directory is a grouping root (no code of its own) that
fans standard targets out to child tool packages — see `docs/PROJ-ARCH.md` for the
group/child split. Child package history lives in its own `CHANGELOG.md`
(`terraform-utils/CHANGELOG.md`); this file covers group-wide scaffolding and
cross-tool docs only.

## [Unreleased]
- No changes since the last milestone.

## [m2-npl-docs] — 2026-07-16 — tag: `utilities-terraform/m2-npl-docs`
Milestone summary: added the standard NPL per-level architecture/layout docs at this
group root (`docs/PROJ-ARCH.md`, `docs/PROJ-LAYOUT.md` + summaries), alongside the
matching doc rework in the `terraform-utils` child.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — group architecture (Makefile
  fan-out over `SUBDIRS`, ecosystem/scope notes)
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md`

## [m1-initial-tooling] — 2026-06-14 — tag: `utilities-terraform/m1-initial-tooling`
Milestone summary: established this directory as a grouping root for Terraform-related
DevOps utilities, with a `Makefile` fanning standard targets (`install`, etc.) out to
child packages via `SUBDIRS`, and the first child package (`terraform-utils`) taking
shape underneath it.

### Added
- `Makefile` (`SUBDIRS := terraform-utils`, includes `../mk/subdirs.mk`)
- `terraform-utils/.gitignore`

## See Also
- `terraform-utils/CHANGELOG.md` — `tf-plan-all` and `migrate-tfstate` tool history
- `docs/PROJ-ARCH.md`, `docs/PROJ-LAYOUT.md` — group architecture/layout
