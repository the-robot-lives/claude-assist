# Changelog — utilities/colo/colo-utils

## [Unreleased]
- Docs refresh (2026-07-17): new PROJ-HOWTO.md + PROJ-HOWTO.summary.md with task-oriented guides for install, cluster dashboards, colo-sync, local-model tunnel, VM telemetry setup, and deploy-relay wiring; four guides extracted to `docs/howto/`.
- Docs refresh (2026-07-16): PROJ-ARCH.md restructured with per-level summaries; new PROJ-LAYOUT.md + PROJ-LAYOUT.summary.md; installation and shared-library arch notes reworked to match the npl arch/layout doc convention.

## [m2-cluster-tooling-suite] — 2026-06-14 — tag: `utilities-colo-colo-utils/m2-cluster-tooling-suite`
Milestone summary: expanded the package from a two-script deploy helper into a full Kubernetes cluster inspection suite with README and architecture docs.

### Added
- `cluster-status` — tiered pod health dashboard across namespaces
- `cluster-nodes` — node layout with CPU/RAM reservation view
- `cluster-resources` — per-pod usage vs requests (metrics-server)
- `cluster-helm` — color-coded Helm release status
- `cluster-layout` — node/PVC/PV layout rendered as markdown (glow)
- `cluster-manticore` — Manticore search dashboard (readers, indexes, S3, jobs)
- `cluster-setup-telemetry` — telemetry bootstrap tooling (largest script, ~1k lines)
- `colo-local-model-link` — local model linking helper
- `README.md` and `docs/` (PROJ-ARCH.md, arch/installation.md, arch/shared-library.md)
- `.gitignore`

### Changed
- `Makefile` install target extended to cover the new `cluster-*` tools

## [m1-deploy-relay-and-sync] — 2026-06-13 — tag: `utilities-colo-colo-utils/m1-deploy-relay-and-sync`
Milestone summary: initial import of the colo-utils package as a git subtree — deploy automation and file-sync tooling for the colo server.

### Added
- `colo-deploy-relay` — polls GitHub Deployments API and runs `helm-upgrade`; designed for a systemd timer on the colo server
- `colo-deploy-relay.service` / `colo-deploy-relay.timer` — systemd units for the relay
- `colo-sync` — rsync between local machine and noizu.server with mirrored-path convenience mode (`--to`/`--from`, `--dry-run`, `--cmd`)
- `Makefile` install target
