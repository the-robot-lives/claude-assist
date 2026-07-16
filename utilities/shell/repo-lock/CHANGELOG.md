# Changelog — utilities/shell/repo-lock

## [Unreleased]
- Docs restructuring: PROJ-ARCH/PROJ-LAYOUT reconciled to per-level convention; added `docs/arch/decisions.md` capturing architecture decision records

## [m1-initial-implementation] — 2026-07-16 — tag: `utilities-shell-repo-lock/m1-initial-implementation`
Milestone summary: initial build of repo-lock, a Rust CLI coordinating concurrent AI sessions and humans sharing one git checkout — advisory session locks plus a repo-wide commit mutex enforced via a pre-commit hook.

### Added
- flock-backed central lock registry under the git common dir, with file/dir locks (TTL + heartbeat + dead-pid break)
- repo-wide commit mutex via `repo-lock exec`
- wrap-and-chain pre-commit hook rejecting commits that stage foreign-locked paths or race the mutex
- session identity via `REPO_LOCK_SESSION` (tobor session UUID), displayed as a 4-glyph unicode handle
- PROJ-ARCH / PROJ-LAYOUT docs, 16 integration tests
