# Changelog — utilities/shell

Group-level history for the shell tooling collection. Each child tool keeps its own
`CHANGELOG.md` with tool-internal milestones (tags: `utilities-shell-<tool>/<milestone>`) —
this file tracks cross-tool, group-wide events: new tools joining the collection,
toolkit-wide doc/convention passes, and multi-tool thematic clusters. See each child's
`docs/PROJ-ARCH.summary.md` / `docs/PROJ-HOWTO.summary.md` for what a given tool does and
its own changelog for tool-internal detail.

Current members: `auto-sudo`, `direnv-config`, `github-utils`, `make-repo`,
`misc-git-utils`, `quick-gist`, `remote-tunnel`, `repo-lock`, `secret-bucket`,
`tabbing-on`, `zellij`.

## [Unreleased]
- No changes since the last milestone.

## [m5-repo-lock-and-doc-conventions] — 2026-07-16 — tag: `utilities-shell/m5-repo-lock-and-doc-conventions`
Milestone summary: `repo-lock` joined the collection (advisory session locks + a repo-wide
git commit mutex for concurrent AI/human sessions sharing one checkout), `tabbing-on` got a
further theme-picker/init/doctor pass, and every tool in the group received the new
per-level `PROJ-ARCH.md`/`PROJ-LAYOUT.md` (+ summaries, + per-directory `docs/layout/*.md`)
documentation convention.

### Added
- `repo-lock`: new Rust CLI — flock-backed lock registry, TTL/heartbeat/dead-pid break,
  `repo-lock exec` commit mutex, pre-commit hook rejecting foreign-locked/racing commits
- Per-directory layout docs (e.g. `direnv-config/docs/layout/src.md`,
  `tabbing-on/docs/layout/rust.md`) across the toolkit
- `utilities/shell/docs/PROJ-ARCH.md` + `PROJ-LAYOUT.md` (this group's own architecture docs)
### Changed
- All 11 tools: `PROJ-ARCH.md`/`PROJ-LAYOUT.md` (+ summaries) restructured to the shared
  per-level doc convention
- `tabbing-on`: theme_picker/render/theme rework, `tabbing-doctor` + `tabbing-init`
  diagnostics hardening

## [m4-doc-pointers-expansion] — 2026-07-09 — tag: `utilities-shell/m4-doc-pointers-expansion`
Milestone summary: `misc-git-utils`' `doc-pointers` tool (introduced in m2) grew
significantly — infisical- and media-tool-aware pointer generation logic.

### Changed
- `misc-git-utils/src/bin/doc-pointers.rs`: two follow-up passes adding infisical doc-pointer
  handling and broader media-tool-aware pointer rules (~275 lines net)

## [m3-session-isolation-hardening] — 2026-07-07 — tag: `utilities-shell/m3-session-isolation-hardening`
Milestone summary: closed a cross-terminal-session bug where `tabbing-on` theme/tab state
leaked between shells via the shared `dc` config store, hardened `dc` itself against
concurrent read-modify-write races, and tightened `auto-sudo`'s decision engine.

### Fixed
- `tabbing-on` + `direnv-config`: `dc-init` precmd bridge now reads the session-scoped
  `DC_TAB_NS` namespace instead of a hardcoded global, so one tab's state no longer
  overwrites another's; new shells evict inherited `TAB_*` state and regenerate session
  identity
- `direnv-config`: read-modify-write commands (`set`/`yaml`/`unset`/`prune`/`purge`/`bump`)
  now hold an exclusive `flock` on the store, preventing lost writes; an existing-but-corrupt
  layer file now errors instead of being silently replaced
### Changed
- `auto-sudo`: expanded decision-engine rule matching (`decision.rs`, +~200 lines)
- `tabbing-on`: ~150 lines of dead shell theme-data logic removed (superseded by the Rust
  `theme_data.rs` path); added a `todo` widget

## [m2-rust-rewrite-wave] — 2026-06-27 — tag: `utilities-shell/m2-rust-rewrite-wave`
Milestone summary: the collection's core interactive tools moved from pure shell/awk to
Rust engines in the same window — `auto-sudo`'s decision logic, `tabbing-on`'s rendering
and a new 256-color theme-data store, plus `direnv-config` gained an encryption/secret-gen
command set and `misc-git-utils`/`zellij` picked up new tooling (`doc-pointers`, `zj-codex`).

### Added
- `auto-sudo`: full Rust CLI rewrite (`config.rs`, `decision.rs`, `shell.rs`, `sudoers.rs`)
  replacing the prior zsh-only implementation
- `tabbing-on`: Rust engine buildout (color/theme/theme_picker/state) plus a
  line-indexed 256-color theme-data store (`TAB_THEME_DATA`, zero yaml/yq dependency,
  full xterm-256 palette + X11 color-name resolution) mirrored in both shell and Rust
- `direnv-config`: `encrypt`/`decrypt`/`gen`/`gen-secrets` commands for working with raw
  unencrypted passwords
- `misc-git-utils`: new `doc-pointers` Rust binary
- `zellij`: new `zj-codex` launcher wrapper (alongside existing `zj-claude`)
### Changed
- `tabbing-on`: daemon/init/history/emoji/plan modules substantially reworked alongside
  the Rust migration

## [m1-initial-toolkit-scaffold] — 2026-06-14 — tag: `utilities-shell/m1-initial-toolkit-scaffold`
Milestone summary: `utilities/shell/` established as its own tree in the monorepo import,
already carrying nine scaffolded tools, plus an initial `dc` (direnv-config) usability pass.

### Added
- Initial scaffold for `auto-sudo`, `direnv-config`, `github-utils`, `make-repo`,
  `misc-git-utils`, `quick-gist` (incl. README/docs/LICENSE), `remote-tunnel`,
  `secret-bucket`, `tabbing-on`
- `direnv-config`: `dc bat --flat` mode for line-numbered, value-free dotted-path output
### Fixed
- Legacy secret-management shell wrappers (e.g. `infisical-view-dc`) broken by a missing
  `secret-engine.sh` install path and a stray `local` outside a function
### Docs
- `docs/secret-management.md`: reference covering the six main secret-management use cases
