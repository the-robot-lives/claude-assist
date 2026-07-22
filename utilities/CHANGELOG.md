# Changelog — utilities

Root-level history for the `utilities/` toolbox (all groups: `agent/`, `colo/`, `database/`, `k8/`, `linux/`, `mk/`, `osx/`, `shell/`, `start-app-scaffold/`, `terraform/`). Scoped to changes touching the toolbox root and cross-cutting concerns; each child utility has its own `CHANGELOG.md` for internals — see `OVERVIEW.md` for the directory map.

## [Unreleased]
- [Accumulating changes since m5-repo-lock-and-doc-scaffolding]

## [m5-repo-lock-and-doc-scaffolding] — 2026-07-16 — tag: `utilities/m5-repo-lock-and-doc-scaffolding`
Advisory session locking lands for safe concurrent repo access, tabbing-on gets a cleanup pass, and every child utility gains a doc scaffold (PROJ-ARCH/LAYOUT/FAQ/HOWTO) plus a root `OVERVIEW.md`.

### Added
- `repo-lock`: advisory session locks + git commit mutex for concurrent-agent safety
- skill manager utility (2026-07-15)
- Root `docs/` PROJ-ARCH and PROJ-LAYOUT, generated/verified across every child utility

### Changed
- `tabbing-on`: further updates and a cleanup pass

## [m4-start-app-scaffold-and-media-tool] — 2026-07-09 — tag: `utilities/m4-start-app-scaffold-and-media-tool`
Two build-outs run in parallel: a new `start-app-scaffold` project generator, and several rounds of `media-tool` provider/pipeline enhancements, alongside `run-claude` profile work, tabbing-on/dc session-leak fixes, and Infisical secret-population updates.

### Added
- `start-app-scaffold`: new scaffold utility for bootstrapping app projects (multiple iterations)
- `run-claude`: profile support and patches
- `tsdb` utility update

### Changed
- `media-tool`: several rounds of provider/pipeline enhancements ("fim" work, ongoing enhancements)
- `tabbing-on` + `dc`: fixed cross-session theme leak; hardened dc store (unified writes on `--layer base`, purge now clears all `TAB_*`/`DC_TAB_NS` state, numeric validation on timestamp writes)
- `queue-populator`: fixed voice memo audio export and long-recording transcript loss
- Infisical secret-population script updates; doc pointer updates

## [m3-tool-polish-and-theme-system] — 2026-06-27 — tag: `utilities/m3-tool-polish-and-theme-system`
Broad polish pass across the toolbox: `helm-upgrade` and `liquibase-shell` defaults, `auto-sudo` hardening, custom MCP endpoint support, and `tabbing-on`'s 256-color theme system rewritten onto a single line-indexed variable store.

### Added
- `tabbing-on`: 256-color theme system via line-indexed single-variable store
- Custom MCP endpoint support
- `zj=codex` (zellij/codex integration)

### Changed
- `helm-upgrade`: default `--reset-values`, with per-chart opt-out
- `liquibase-shell`: default `KUBECONFIG` to the noizu cluster config
- `auto-sudo`: further hardening/improvements
- `docker-build`: zellij integration update
- `run-claude`, `claude-assist`, `tabbing-on`: assorted tweaks/updates
- `@noizu/styleguide` bumped to 0.1.15; model config updates

## [m2-secrets-and-macos-hardening] — 2026-06-16 — tag: `utilities/m2-secrets-and-macos-hardening`
Early consolidation after the subtree import: `dc` gains flat/dotted-path secret search, legacy Infisical wrappers get fixed, and macOS-specific tooling (fstab NTFS support, direnv raw-password access) is hardened.

### Added
- `dc bat --flat`: line-numbered dotted-path secret search without exposing values
- `docs/secret-management.md`: full reference covering 6 secret-management use cases
- NTFS read/write support added to osx `fstab` utility

### Fixed
- `secret-utils`/`infisical-view-dc`: broken legacy shell wrappers (install path, `local` outside function, filter logic)

### Changed
- `queue-populator`: improvements
- `direnv-config`: enhancements for approved raw/unencrypted password access
- `infra-utils`: misc fixes ("infra-itos")

## [m1-initial-subtree-import] — 2026-06-13 — tag: `utilities/m1-initial-subtree-import`
The `utilities/` toolbox is assembled by importing 18 previously-standalone tool repos as git subtrees, establishing the `agent/`, `colo/`, `database/`, `k8/`, `osx/`, `shell/`, and `terraform/` groupings used ever since.

### Added
- `agent/`: claude-assist, dangerously-safe, mallm, media-tool
- `colo/colo-utils`, `database/database-utils`
- `k8/`: cluster-utils, docker-utils, helm-utils, infra-utils, secret-utils, staging-utils
- `osx/`: fstab, queue-populator
- `shell/`: auto-sudo, direnv-config, github-utils, make-repo, misc-git-utils, remote-tunnel, secret-bucket, tabbing-on, zellij
- `terraform/terraform-utils`
