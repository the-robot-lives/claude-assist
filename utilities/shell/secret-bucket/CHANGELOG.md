# Changelog — utilities/shell/secret-bucket

## [Unreleased]
- [Accumulating changes since the last milestone tag]

## [m2-arch-docs] — 2026-07-16 — tag: `utilities-shell-secret-bucket/m2-arch-docs`
Milestone summary: added standard NPL architecture/layout reference docs (PROJ-ARCH, PROJ-LAYOUT + summaries) under `docs/`, describing the tool's internal structure for agent consumers.

### Added
- `docs/PROJ-ARCH.md` + `PROJ-ARCH.summary.md` — architecture reference
- `docs/PROJ-LAYOUT.md` + `PROJ-LAYOUT.summary.md` — directory layout reference

## [m1-initial-release] — 2026-06-13 — tag: `utilities-shell-secret-bucket/m1-initial-release`
Milestone summary: `secret-bucket` landed in the monorepo as a git subtree import, arriving fully-formed — a Rust CLI for agent-safe, value-free comparison and copying of secrets across `.envrc`/`.envrc.dc`/`.envrc.k8.dc`-style files (`envrc:` and `dcfile:` address formats), plus a `.gitignore` for the Cargo `target/` build output. Covers the initial subtree merge (2026-06-13, effectively a no-op resync of an identical 2026-06-08 squash) through a run of build-cache-only commits accidentally touching the tracked `target/.rustc_info.json` fingerprint file (no source changes).

### Added
- `src/main.rs` (852 lines) — CLI implementing `list`/`diff`/`copy` over `envrc:` and `dcfile:` addresses
- `Cargo.toml` / `Cargo.lock` — Rust project + pinned dependencies
- `README.md` — usage, address formats, privilege-separated install guidance
- `docs/PRD.md`, `docs/policy.example.yaml`, `docs/sudoers.example` — product spec + privilege-separation examples
- `.gitignore` for `target/`

### Notes
- `target/` build artifacts (e.g. `.rustc_info.json`) are tracked in this history from the initial import; the 2026-06-14 through 2026-07-09 "wip"/"utilities updates" commits only bump that generated fingerprint file and carry no source changes.
