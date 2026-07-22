# Changelog — utilities/shell/zellij

## [Unreleased]
- Added `docs/PROJ-ARCH.md`, `docs/PROJ-ARCH.summary.md`, `docs/PROJ-LAYOUT.md`, `docs/PROJ-LAYOUT.summary.md` (architecture + layout reference docs)

## [m2-codex-support-and-prefill] — 2026-06-27 — tag: `utilities-shell-zellij/m2-codex-support-and-prefill`
Added a Codex-flavored counterpart to `zj-claude`, then upgraded both agent launchers so the agent command is queued into an editable prompt line instead of firing immediately.

### Added
- `zj-codex` — launches a zellij session with `codex` queued in split panes per selected directory (mirrors `zj-claude`'s workspace/session/pane options)
### Changed
- `zj-claude` and `zj-codex` now prefill the agent command into the pane's shell prompt (zsh `vared`, bash `read -e -i`, generic fallback) so the user presses Enter to run it rather than having it auto-execute

## [m1-initial-toolkit] — 2026-06-14 — tag: `utilities-shell-zellij/m1-initial-toolkit`
Initial import of the zellij dev-session toolkit as a subtree: four launcher scripts plus a shared layout for arranging `claude`/editor/shell panes across tabs and sessions.

### Added
- `zj-claude` — launches a zellij session with `claude` in split panes per selected directory
- `zj-panes` — populates the current tab with the standard claude/nvim/shell pane layout
- `zj-spawn` — launches a session with one tab per selected subdirectory
- `zj-tab` — adds a claude dev tab (claude/nvim/shell/floating dev-server panes) to the current or a new session
- `layouts/claude-dev.kdl` — reusable zellij layout backing the above
- `Makefile` — `install` target symlinking/copying `bin/*` into `~/.local/bin`
- `.gitignore` — ignore local editor/OS/env cruft
