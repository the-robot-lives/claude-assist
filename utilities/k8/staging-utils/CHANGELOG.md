# Changelog — utilities/k8/staging-utils

## [Unreleased]
- Regenerated `docs/PROJ-ARCH.md`/`PROJ-ARCH.summary.md` and added `docs/PROJ-LAYOUT.md`/`PROJ-LAYOUT.summary.md` per the NPL arch/layout doc convention

## [m1-initial-tooling] — 2026-06-14 — tag: `utilities-k8-staging-utils/m1-initial-tooling`
Staging environment lifecycle tool suite landed as a subtree merge: deploy, teardown, log-tailing, and status dashboard commands for the staging namespace, delegating deploy to `helm-upgrade`.

### Added
- `staging-up` — deploy all staging services (delegates to `helm-upgrade --env stage`)
- `staging-down` — uninstall all Helm releases in the staging namespace
- `staging-logs` — tail logs for a staging service by name (defaults to frontend)
- `staging-status` — dashboard of pods, Helm releases, KEDA ScaledObjects, and resource usage
- `Makefile` with `make install` target installing `staging-*` tools to `~/.local/bin`
- Config loaded via shared k8-lib chain (`.kubernetes.staging_namespace`, `.kubernetes.app_prefix`), overridable via `--config` or env vars
- `.gitignore` for local dev artifacts

### Changed
- README config reference repointed from relative `../k8-lib/README.md` to installed `~/.local/share/k8-lib/README.md` path
