# Changelog — utilities/agent/dangerously-safe

## [Unreleased]
- NPL architecture/layout docs added under `docs/` (PROJ-ARCH.md + summary, PROJ-LAYOUT.md + summary, layout/src.md) (2026-07-16, ff72b3565bf)
- NPL how-to docs added under `docs/` (PROJ-HOWTO.md + summary, howto/build-or-reuse-image.md, howto/add-custom-app.md, howto/log-outbound-traffic.md) (2026-07-17)
- NPL FAQ docs added under `docs/` (PROJ-FAQ.md + summary) (2026-07-17)

## [m2-rust-agent-sandbox] — 2026-06-14 — tag: `utilities-agent-dangerously-safe/m2-rust-agent-sandbox`
Milestone summary: full Rust rewrite as `agent-sandbox` — a TUI + Docker image builder for running coding agents (claude / codex / opencode) in dangerous/auto-approve mode safely, inside an isolated git worktree mounted into a per-project container. The legacy bash script is kept alongside.

### Added
- Rust crate (~6,800 lines): CLI (`build-image`, `list-images`, `doctor`, `template`, `preview`) plus an interactive TUI wizard (`src/tui/`)
- Composable Dockerfile snippets (`snippets/base.dockerfile` + per-app: claude, codex, opencode, node, rust, elixir, shell) with image slug/tag normalization and OCI app-set labels for reuse (`src/image/`)
- Git worktree lifecycle management under `.agent-sandbox/worktrees/` (`src/worktree/`)
- Per-project config with template bootstrap and merge layering (`src/config/`, `templates/default/config.yaml`)
- Container launch pipeline: controlled env, ports, network, hooks, and agent tools on PATH (`src/launch/`, `src/docker/`)
- Closest-image inference to reuse existing local images instead of rebuilding (`src/image/closest.rs`, `src/inference/`)
- README documenting usage, image naming/reuse, and wizard flow

### Changed
- Makefile expanded from a 17-line installer to a full cargo build/install/test workflow

## [m1-bash-sandbox-script] — 2026-06-13 — tag: `utilities-agent-dangerously-safe/m1-bash-sandbox-script`
Milestone summary: initial import as a git subtree — a standalone bash utility that provisions a locked-down `claude` user/`agents` group and an isolated `<branch>-agent` git worktree for running agents in dangerous mode.

### Added
- `bin/dangerously-safe` bash script (179 lines): pre-flight user/group creation (Linux + macOS), per-branch agent worktree setup
- Makefile installer target
