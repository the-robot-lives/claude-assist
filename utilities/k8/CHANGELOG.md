# Changelog — utilities/k8

Group-level history for the `utilities/k8/` k8s DevOps toolset. Each child
(`cluster-utils`, `docker-utils`, `helm-utils`, `infra-utils`, `k8-lib`,
`secret-utils`, `staging-utils`) keeps its own `CHANGELOG.md` with tool-internal
detail — this file tracks cross-tool/group-wide events only: subtree
consolidation, shared-library changes, and group-wide doc/tooling passes.

## [Unreleased]
- (docs-only working tree churn — PROJ-FAQ/PROJ-HOWTO rollout in child dirs —
  is tracked per-child; see each tool's own CHANGELOG.md)

## [m3-doc-architecture-standardization] — 2026-07-16 — tag: `utilities-k8/m3-doc-architecture-standardization`
Milestone summary: rolled out matching PROJ-ARCH/PROJ-LAYOUT doc pairs (full +
`.summary.md`) at both the group root (`utilities/k8/docs/`) and each child
tool, giving the whole tree a consistent architecture/layout doc story.

### Added
- `utilities/k8/docs/PROJ-ARCH.md` + `PROJ-LAYOUT.md` (and summaries) — group-level architecture/layout docs
- Matching PROJ-ARCH/PROJ-LAYOUT doc pairs added to docker-utils
### Changed
- cluster-utils arch/layout docs rewritten around the k8-lib shared-library model

## Checkpoint: 2026-06-16 → 2026-07-09 — per-tool feature work
No group-level restructuring in this span; each change lives entirely inside
one child tool. Listed here for continuity — see the named tool's own
CHANGELOG.md for the full story:
- infra-utils: new `infra-config` inspection tool (~790 lines)
- helm-utils: `helm-upgrade` defaults to `--reset-values` (with a
  `helm_preserve_values` opt-out list) so bumped image tags in `values.yaml`
  are no longer silently ignored on upgrade
- docker-utils: `docker-build` zellij integration + follow-up fixes
- infra-utils: `deploy-service` rewritten (~325 lines touched)
- secret-utils: `infisical-populate-secrets` iterated three times (doc-pointer
  updates, then two functional passes)

## [m2-shared-lib-and-secrets-docs] — 2026-06-14 — tag: `utilities-k8/m2-shared-lib-and-secrets-docs`
Milestone summary: introduced the `k8-lib` shared bash library consumed by the
other tools, added a group-level `Makefile`, normalized per-tool `.gitignore`,
and documented the secrets-management workflow end to end.

### Added
- `k8-lib/` shared library (`assist.sh`, `cleanup.sh`, `common.sh`, `all.sh`, …) + its own `Makefile`/`README.md`
- Group-level `utilities/k8/Makefile`
- `docs/secret-management.md` — reference for the six secret-management use cases
- `dc bat --flat` — line-numbered dotted-path secret listing without values
### Changed
- `docker-build`/`docker-push`/`helm-upgrade` refactored (~270 lines net across the three)
- `secret-utils` Makefile installs `secret-engine.sh` to `~/.local/lib/`
- `.gitignore` added to every child tool
### Fixed
- `infisical-view-dc`: `local` used outside a function + broken filter logic

## [m1-subtree-consolidation] — 2026-06-13 — tag: `utilities-k8/m1-subtree-consolidation`
Milestone summary: six previously independent k8s tooling repos were merged in
as git subtrees under `utilities/k8/`, forming this group.

### Added
- `cluster-utils`, `docker-utils`, `helm-utils`, `infra-utils`, `secret-utils`, `staging-utils` — merged as sibling subtrees under `utilities/k8/`
