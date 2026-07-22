# Changelog — utilities/agent/claude-desktop-sandbox

## [Unreleased]
- NPL architecture/layout docs added under `docs/` (`PROJ-ARCH.md`, `PROJ-LAYOUT.md` + summaries) (ff72b3565bf, 2026-07-16)
- NPL how-to docs added under `docs/` (`PROJ-HOWTO.md` + summary, `howto/` extractions for seeding, deep-link routing, OAuth browser troubleshooting) (2026-07-17)
- NPL FAQ docs added under `docs/` (`PROJ-FAQ.md` + summary — motivation, fit, comparison, capability, caveats, trust) (2026-07-17)

## [m2-template-seeding-and-url-routing] — 2026-07-09 — tag: `utilities-agent-claude-desktop-sandbox/m2-template-seeding-and-url-routing`
Milestone summary: new sandboxes clone an existing template (login included) instead of starting cold, and inbound `claude://` deep links (OAuth callbacks) route to the right sandbox instead of the host app.

### Added
- `--from <template>` / `$CLAUDE_SANDBOX_TEMPLATE` seeding — new sandboxes are full clones of a template sandbox; defaults to the oldest existing sandbox, first-ever sandbox starts empty
- `claude://` URL routing: `--install-url-handler` / `--uninstall-url-handler` register a host `x-scheme-handler/claude` desktop entry that dispatches via `--open-url`
- `--pin <name>` / `--unpin` to force the deep-link target; unpinned links go to the last-launched sandbox, with fallback to host claude-desktop when nothing resolves
### Changed
- CLI reworked into a `case`-dispatched subcommand surface; unknown `--flags` now fail with usage instead of being treated as sandbox names
- README expanded to document templates and URL-handler workflow

## [m1-initial-sandbox-launcher] — 2026-07-09 — tag: `utilities-agent-claude-desktop-sandbox/m1-initial-sandbox-launcher`
Milestone summary: first working tool — run multiple isolated claude-desktop instances via bwrap, each with its own `$HOME` (config, session, cookies, MCP config) while sharing the host display, audio, and D-Bus.

### Added
- `bin/claude-sandbox` launcher: per-name sandbox homes under `~/sandboxes/claude-desktop-<name>`, fully detached launch (setsid + nohup) with per-sandbox log file
- `--list` and `--remove <name>` sandbox management
- Auto-generated `sandboxed-browser` wrapper so OAuth flows exec Chromium-based browsers with `--no-sandbox` (setuid sandbox can't nest inside bwrap namespaces)
- `Makefile` install target and initial `README.md`
