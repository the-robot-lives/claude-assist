# Changelog — utilities/mk

## [Unreleased]
- Nothing yet.

## [m2-npl-docs] — 2026-07-16 — tag: `utilities-mk/m2-npl-docs`
Milestone summary: brought the package under the repo-wide NPL documentation convention with architecture and layout docs plus summaries.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — architecture doc covering the shared-include design and target-dispatch flow
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — file layout doc for the package

## [m1-subdir-tooling] — 2026-06-14 — tag: `utilities-mk/m1-subdir-tooling`
Milestone summary: initial landing of the shared Makefile subdirectory toolkit — a reusable include for fanning targets out across child Makefiles, plus a consistency checker.

### Added
- `subdirs.mk` — shared include that dispatches `build`/`compile`/`test`/`install`/`clean` (configurable via `SUBDIR_TARGETS`) across `SUBDIRS`, skipping children lacking the target and falling back `build`→`compile` when only `compile` is declared
- `check-subdirs.sh` — tree linter that flags Makefiles missing from their parent's `SUBDIRS` and `SUBDIRS` entries with no child Makefile
