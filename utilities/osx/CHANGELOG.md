# Changelog — utilities/osx

`utilities/osx` is a grouping directory, not a standalone tool — entries here cover
group-level concerns (the fan-out Makefile, cross-tool docs) and interval checkpoints.
Child-internal work is tracked in each child's own changelog:
[fstab/CHANGELOG.md](fstab/CHANGELOG.md) ·
[queue-populator/CHANGELOG.md](queue-populator/CHANGELOG.md).

## [Unreleased]
- No changes since the last milestone tag.

## [m2-docs-baseline] — 2026-07-16 — tag: `utilities-osx/m2-docs-baseline`
Milestone summary: added group-level `docs/PROJ-ARCH.md` and `docs/PROJ-LAYOUT.md` (+
summaries) describing the group's fan-out role and its two children; refreshed the
equivalent docs inside both children in the same pass.

### Added
- `docs/PROJ-ARCH.md`, `docs/PROJ-ARCH.summary.md` — group role, child responsibilities, ecosystem fit
- `docs/PROJ-LAYOUT.md`, `docs/PROJ-LAYOUT.summary.md` — directory map with links to child docs
### Changed
- `fstab/docs/*` and `queue-populator/docs/*` PROJ-ARCH/PROJ-LAYOUT revised for currency (see child changelogs)

## [checkpoint: child-tool feature work] — 2026-07-05 — tag: `utilities-osx/checkpoint-2026-07-05`
Large interval between the initial scaffold and the docs baseline; every commit in it
landed entirely inside a child directory, with no group-level (`Makefile`, top-level
`docs/`) changes. Detail lives in the child changelogs:
- **queue-populator**: `m2-virtual-mic-and-memo-review`, `m3-config-secrets-and-debug-tooling`, `m4-audio-reliability-fixes`
- **fstab**: `m2-ntfs-rw-support`, `m3-entry-parser-rewrite`

## [m1-initial-scaffold] — 2026-06-14 — tag: `utilities-osx/m1-initial-scaffold`
Milestone summary: established the `utilities/osx` grouping directory — a thin
fan-out `Makefile` delegating `build`/`compile`/`test`/`install`/`clean` to child
tools — and subtree-imported the two initial macOS-host utilities under it.

### Added
- `Makefile` — `SUBDIRS := fstab queue-populator`, includes shared `utilities/mk/subdirs.mk`
- `fstab/` — LaunchDaemon-driven `/etc/fstab` emulation for APFS/NTFS (subtree-imported; see `fstab/CHANGELOG.md`)
- `queue-populator/` — Swift menu-bar voice-memo → LLM queue app (subtree-imported; see `queue-populator/CHANGELOG.md`)
