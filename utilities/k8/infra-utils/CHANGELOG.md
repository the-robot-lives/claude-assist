# Changelog — utilities/k8/infra-utils

## [Unreleased]
- Nothing pending since m4.

## [m4-docs-foundation] — 2026-07-16 — tag: `utilities-k8-infra-utils/m4-docs-foundation`
Established the package's self-documentation baseline: architecture and layout docs plus their compact summaries, and a dedicated scripts reference.

### Added
- `docs/PROJ-ARCH.md` fleshed out with fuller architecture detail; matching `PROJ-ARCH.summary.md`
- `docs/PROJ-LAYOUT.md` + `PROJ-LAYOUT.summary.md` — directory/file layout reference
- `docs/arch/scripts.md` — per-script architecture notes

## [m3-deploy-service-rewrite] — 2026-07-08 — tag: `utilities-k8-infra-utils/m3-deploy-service-rewrite`
Substantial rework of the `deploy-service` pipeline logic (build → push → Helm values bump → upgrade).

### Changed
- `bin/deploy-service` — large-scale rewrite (~191 insertions / 134 deletions) refining pipeline flow and control logic

## [m2-infra-config-tool] — 2026-06-16 — tag: `utilities-k8-infra-utils/m2-infra-config-tool`
Added `infra-config`, a large standalone CLI for managing `.infra-config.yaml`-driven configuration, alongside a Makefile install-list update.

### Added
- `bin/infra-config` — new config-management CLI (~786 lines)
### Changed
- `Makefile` — install target updated to include `infra-config`

## [m1-initial-tooling] — 2026-06-14 — tag: `utilities-k8-infra-utils/m1-initial-tooling`
Initial import of the infra-utils toolkit as a subtree, plus early housekeeping (gitignore, doc touch-ups).

### Added
- `infra-init` — bootstrap repos, Terraform, imports, and dependency checks
- `deploy-service` — build → push → values.yaml bump → Helm upgrade pipeline
- `deploy-one-off` — one-off Kubernetes deployment helper
- `open-dashboard` — open configured dashboards
- `add-import-permissions` — IAM setup for Terraformer imports
- `README.md`, `Makefile` (install target), initial `docs/PROJ-ARCH.md` + summary, `docs/arch/scripts.md`
### Added (follow-up)
- `.gitignore`
### Changed
- Minor `docs/PROJ-ARCH.md` / `docs/arch/scripts.md` corrections
