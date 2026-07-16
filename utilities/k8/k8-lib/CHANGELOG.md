# Changelog — utilities/k8/k8-lib

## [Unreleased]
- No changes since the last milestone.

## [m2-npl-arch-docs] — 2026-07-16 — tag: `utilities-k8-k8-lib/m2-npl-arch-docs`
Milestone summary: added per-level NPL architecture/layout documentation so the library carries its own machine-readable overview alongside the human README.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — component architecture overview (config-resolution facade, module families, key decisions)
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — directory layout reference
- `docs/layout/bin.md` — per-file layout notes for `bin/`

## [m1-initial-import] — 2026-06-14 — tag: `utilities-k8-k8-lib/m1-initial-import`
Milestone summary: k8-lib landed at `utilities/k8/k8-lib` as the shared sourced-shell library backing all devops tool suites (docker-build, docker-push, helm-upgrade, helm-publish, deploy-service, infra-init) — layered config resolution, Docker/Helm/IAM/Terraform helpers, and the infra-init subcommand set, installed to `~/.local/share/k8-lib` via `make install`.

### Added
- `Makefile` — `make install` + `bash -n` syntax check target
- `README.md` — config-layer docs (`infra-config.yaml`, `.envrc.k8.dc`) + quick start
- `bin/common.sh`, `bin/config.sh`, `bin/config-resolver.sh` — output helpers + layered config/scalar resolution facade (env var → `dc get k8` → YAML → hardcoded default; `--config` → `K8_CONFIG` → `$INFRA_ROOT` → git-root walk → `$K8_LIB_DIR`)
- `bin/docker-config.sh`, `bin/docker-vsn.sh` — Docker build-target discovery + version/tag logic
- `bin/helm-common.sh`, `bin/helm-publish-config.sh` — chart discovery, tier/namespace resolution, OCI publish config
- `bin/project-registry.sh` — per-project `project.yaml` loader for `deploy-service`
- `bin/assist.sh` — `--assist` AI help via headless Claude Code
- `bin/all.sh`, `bin/repos.sh`, `bin/terraform.sh`, `bin/import.sh`, `bin/iam.sh`, `bin/state_upgrade.sh`, `bin/cleanup.sh`, `bin/doctor.sh`, `bin/help.sh` — `infra-init` `cmd_*` subcommand modules
- `infra-config.yaml.example` — structural config template
- `.gitignore`
