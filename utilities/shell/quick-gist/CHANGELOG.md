# Changelog — utilities/shell/quick-gist

## [Unreleased]
- No committed changes since last milestone (working tree has uncommitted script/doc updates not yet reflected here)

## [m1-initial-release] — 2026-07-16 — tag: `utilities-shell-quick-gist/m1-initial-release`
Milestone summary: `quick-gist` lands as a fast, ergonomic CLI wrapper around `gh gist` with interactive file picking via fzf, then gets its PROJ-ARCH/PROJ-LAYOUT docs aligned to the per-level docs convention.

### Added
- Initial `quick-gist` script: fzf-driven interactive file picker (multi-select, preview), stdin piping, add-to-existing-gist, public/secret visibility (flag or env var), auto-copy gist URL to clipboard, optional post-create browser open
- Makefile, LICENSE.md, README.md, PROJ-ARCH.md, PROJ-LAYOUT.md (+ summaries)
### Changed
- PROJ-ARCH.md / PROJ-LAYOUT.md (+ summaries) revised to match the per-level docs convention
