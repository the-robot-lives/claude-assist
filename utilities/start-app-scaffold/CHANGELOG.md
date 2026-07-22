# Changelog — utilities/start-app-scaffold

## [Unreleased]
- NPL architecture/layout docs added under `docs/` (`PROJ-ARCH.md`, `PROJ-LAYOUT.md` + summaries) describing the toolset and its file layout

## [m2-provisioning-and-llm-merge] — 2026-07-08 — tag: `utilities-start-app-scaffold/m2-provisioning-and-llm-merge`
Milestone summary: grew the package from a template extractor into a full scaffold-and-provision toolchain — a one-shot `start-app-scaffold` CLI, an LLM-assisted merge workflow for existing apps, and a shared repo-root resolver so installed copies work outside the monorepo.

### Added
- `bin/start-app-scaffold` — scaffold and provision a start-app instance in one command; writes provisioning artifacts to `<target>/.start-app-provision`, with `--execute` applying Postgres and Valkey ACL steps via `--postgres-url`/`--valkey-url`
- `bin/llm-merge-start-app` — stages a fresh hydrated scaffold, infers project identity (slug, module, app name, site) from an existing target, emits `metadata.env`, diff stat/patch, and file-set inventories, then hands the merge to an LLM coding agent (`--apply`, `LLM_MERGE_AGENT_CMD`)
- `lib/repo-root.sh` — shared repo-root resolver (`$INFRA_ROOT` → script-dir walk-up → `$PWD` walk-up); fixes installed-to-`~/.local/bin` copies silently bottoming out at `/`

### Changed
- All four bin scripts source the shared resolver instead of per-script `.git` walk-up loops
- `make install` also installs `lib/repo-root.sh` to `~/.local/share/start-app-scaffold/`
- `make test` now syntax-checks (`bash -n`) the lib and every bin script

## [m1-initial-scaffold-tooling] — 2026-06-20 — tag: `utilities-start-app-scaffold/m1-initial-scaffold-tooling`
Milestone summary: initial toolset for creating portfolio projects from the `components/start-app` template, plus a Makefile install target.

### Added
- `bin/init-proj-scaffold` — create a new portfolio project from the start-app template tarball (`<project_dir> <slug> <elixir_module>`, `--target`, `--helm`/`--no-helm`)
- `bin/build-start-app-tarball` — build the `start-app.tar.gz` template tarball consumed by the scaffolder
- `Makefile` — `make install` copies the tools to `~/.local/bin`
