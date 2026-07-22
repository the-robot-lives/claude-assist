# Changelog — utilities/agent

Grouping directory for agent-centric utilities (`claude-assist`, `claude-desktop-sandbox`,
`dangerously-safe`, `mallm`, `media-tool`, `run-claude`, `skill-manage`). This changelog
covers group-level history — cross-tool workflow additions and when each child arrived.
Per-child history lives in each child's own `CHANGELOG.md`.

## [Unreleased]

### Changed — 2026-07-22
- `skill-manage` folded into `claude-assist` as an embedded crate; the combined tool renamed
  `llm-toolkit`. `llm-toolkit skill …` replaces the standalone `skill-manage` binary (all prior
  subcommands unchanged). Legacy `claude-assist` and `skill-manage` bins removed on install;
  only `llm-toolkit` is installed to `~/.local/bin` going forward.

## [m4-skill-manage-and-docs] — 2026-07-16 — tag: `utilities-agent/m4-skill-manage-and-docs`
Milestone summary: added `skill-manage` (Rust Claude Code skill symlink/catalog manager) as a
new child tool, then backfilled per-project `PROJ-ARCH`/`PROJ-LAYOUT` docs across children.

### Added
- `skill-manage` child tool: Rust CLI with catalog/config schema and audit module
### Changed
- Root `Makefile` updated to fan out to the new `skill-manage` child
- `claude-assist` and `claude-desktop-sandbox` gained per-project `PROJ-ARCH.md` /
  `PROJ-LAYOUT.md` (+ summaries) documentation

## [m3-sandbox-and-media-fim] — 2026-07-09 — tag: `utilities-agent/m3-sandbox-and-media-fim`
Milestone summary: added the `claude-desktop-sandbox` launcher tool, landed a run of
`media-tool` "fim" (fill-in-the-middle?) enhancements, and patched `run-claude` profiles.

### Added
- `claude-desktop-sandbox` child tool: bwrap-based multi-instance claude-desktop launcher
  (`bin/claude-sandbox`, Makefile, README)
### Changed
- `run-claude`: profile updates and a patch (2026-07-08/09)
- `media-tool`: several rounds of "ongoing" enhancements and fim-related work (multiple
  commits 2026-07-09; see `media-tool/CHANGELOG.md` for tool-internal detail)

## [m2-claude-assist-and-runclaude-buildout] — 2026-06-27 — tag: `utilities-agent/m2-claude-assist-and-runclaude-buildout`
Milestone summary: built out `run-claude` (CLI, proxy, watchdog, shell hooks, model routing)
and extended `claude-assist` (LLM services, conversation indexer/editor/operations, custom
MCP endpoint selection in the interactive TUI).

### Added
- `run-claude`: `cli.py`, `proxy.py`, `state.py`, `watchdog.py`, `front_proxy.py`, bash/zsh
  shell hooks, `profiles.yaml`, expanded `models.yaml` routing tables
- `claude-assist`: LLM route/service layer, conversation indexer/editor/operations services,
  custom MCP endpoint selection in the interactive CLI (interface-selection, FocusContext)
### Changed
- `claude-assist` Settings/Edit web pages updated to match new API services
### Fixed
- Stray committed scratch file (`claude-assist/2`) removed

## [m1-early-utility-buildout] — 2026-06-14 — tag: `utilities-agent/m1-early-utility-buildout`
Milestone summary: first commit after subtree import — added the group-level `Makefile` and
Docker snippet library to `dangerously-safe`.

### Added
- Root `utilities/agent/Makefile` (fan-out to child subdirs)
- `dangerously-safe`: per-language app Dockerfile snippets (claude, codex, elixir, node,
  opencode, rust, shell) plus `Cargo.lock`/`Cargo.toml`, README

## [m0-subtree-init] — 2026-06-13 — tag: `utilities-agent/m0-subtree-init`
Milestone summary: `utilities/agent` established as a grouping directory by importing four
existing tools as git subtrees.

### Added
- `claude-assist` subtree merged in (agent-transcript indexer/browser: API + web + TUI)
- `dangerously-safe` subtree merged in (agent-sandbox: Rust TUI + Docker builder)
- `mallm` subtree merged in (LLM-friendly CLI docs resolver, Node CLI)
- `media-tool` subtree merged in (YAML `.media.prompt` → media asset generation, Rust)
