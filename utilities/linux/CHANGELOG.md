# Changelog — utilities/linux

Group-level history for the Linux desktop-utilities grouping directory. This file covers group-wide concerns (Makefile fan-out, which-tool-when, cross-tool workflows) — child project internals are documented and changelogged in the child itself; see links below.

## [Unreleased]
- [Accumulating changes since the last milestone tag]

## [m2-arch-docs] — 2026-07-16 — tag: `utilities-linux/m2-arch-docs`
Milestone summary: added standard PROJ-ARCH/PROJ-LAYOUT documentation set for this grouping directory, describing the fan-out Makefile pattern and pointing at child docs.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — grouping-directory architecture (Makefile fan-out via `../mk/subdirs.mk`; no source of its own)
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — directory/layout reference, linking to `queue-populator/docs/`

## [m1-group-init] — 2026-07-07 — tag: `utilities-linux/m1-group-init`
Milestone summary: established `utilities/linux` as a grouping directory (SUBDIRS fan-out Makefile) and landed its first child project, `queue-populator` — a Rust port of the macOS wake-phrase voice-memo tool for Ubuntu GNOME/PipeWire. Full internal history for the child lives in its own changelog (see below).

### Added
- `Makefile` — `SUBDIRS := queue-populator` fan-out via shared `../mk/subdirs.mk` harness (`build`/`compile`/`test`/`install`/`clean` delegate to child Makefiles, which self-gate on Linux)
- `queue-populator/` child project — see `queue-populator/CHANGELOG.md` (`utilities-linux-queue-populator/m1-initial-rust-port`, `utilities-linux-queue-populator/m2-arch-docs`) and `queue-populator/docs/PROJ-ARCH.summary.md` for internals

## Child Projects

| Project | Docs | Changelog |
|---|---|---|
| `queue-populator/` | `queue-populator/docs/PROJ-ARCH.summary.md`, `queue-populator/docs/PROJ-LAYOUT.summary.md` | `queue-populator/CHANGELOG.md` |
