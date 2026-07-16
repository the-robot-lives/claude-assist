# Changelog — utilities/k8/cluster-utils

## [Unreleased]
- Expanded architecture docs and added layout docs: new `docs/PROJ-LAYOUT.md` + summary, reworked `docs/PROJ-ARCH.md`/summary, refreshed `docs/arch/installation.md` and `docs/arch/shared-library.md` (`ff72b3565bf`, 2026-07-16)
- Added task-oriented `docs/PROJ-HOWTO.md` + summary, plus extracted `docs/howto/setup-telemetry.md`, covering install/verify, each dashboard, `--assist`, `--config`, and remote telemetry setup (2026-07-17)

## [m1-subtree-import] — 2026-06-14 — tag: `utilities-k8-cluster-utils/m1-subtree-import`
Milestone summary: the cluster-utils toolkit landed in the monorepo as a git subtree (squashed from external commit `8440a413548`) and received an immediate post-import cleanup pass.

### Added
- Seven `bin/` cluster inspection and setup utilities: `cluster-helm`, `cluster-layout`, `cluster-manticore`, `cluster-nodes`, `cluster-resources`, `cluster-setup-telemetry`, `cluster-status`
- `Makefile` install target and `README.md` usage guide
- Initial `docs/` set: `PROJ-ARCH.md` + summary, `arch/installation.md`, `arch/shared-library.md`
- `.gitignore` for local artifacts (post-import cleanup, `5b235c9bd5f`)

### Changed
- Corrected README and architecture docs for monorepo paths and the shared `k8-lib` install flow (`5b235c9bd5f`)
